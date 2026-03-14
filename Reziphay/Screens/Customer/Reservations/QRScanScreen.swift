import SwiftUI
import AVFoundation

// MARK: - QR Camera View

struct QRCameraView: UIViewRepresentable {
    let onCodeDetected: (String) -> Void

    func makeUIView(context: Context) -> QRCameraUIView {
        let view = QRCameraUIView()
        view.onCodeDetected = onCodeDetected
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: QRCameraUIView, context: Context) {}

    static func dismantleUIView(_ uiView: QRCameraUIView, coordinator: ()) {
        uiView.stopSession()
    }
}

final class QRCameraUIView: UIView {
    var onCodeDetected: ((String) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func startSession() {
        let session = AVCaptureSession()
        captureSession = session

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(makeDelegate(), queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func stopSession() {
        captureSession?.stopRunning()
    }

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        try? device.lockForConfiguration()
        device.torchMode = device.torchMode == .on ? .off : .on
        device.unlockForConfiguration()
    }

    private func makeDelegate() -> QRMetadataDelegate {
        let delegate = QRMetadataDelegate()
        delegate.onCodeDetected = { [weak self] code in
            self?.onCodeDetected?(code)
        }
        return delegate
    }
}

private final class QRMetadataDelegate: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeDetected: ((String) -> Void)?
    private var hasDetected = false

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasDetected,
              let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue else { return }
        hasDetected = true
        onCodeDetected?(code)
    }
}

// MARK: - Screen

struct QRScanScreen: View {
    let reservationId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var isTorchOn: Bool = false
    @State private var isProcessing: Bool = false
    @State private var cameraViewRef: QRCameraUIView? = nil
    @State private var navigateToResult: Bool = false
    @State private var resultState: QRResultState = .success

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with dark background
                HStack {
                    RZIconButton(icon: "chevron.left", color: .white) { dismiss() }
                    Spacer()
                    Text("Scan QR Code")
                        .font(.rzH4)
                        .foregroundStyle(.white)
                    Spacer()
                    RZIconButton(
                        icon: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                        color: isTorchOn ? .rzWarning : .white
                    ) {
                        isTorchOn.toggle()
                        cameraViewRef?.toggleTorch()
                    }
                }
                .padding(.horizontal, RZSpacing.screenHorizontal)
                .padding(.vertical, RZSpacing.xs)

                Spacer()

                // Camera / preview area
                ZStack {
                    QRCameraViewWrapper(onCameraReady: { ref in
                        cameraViewRef = ref
                    }, onCodeDetected: handleCodeDetected)
                    .frame(width: 280, height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))

                    // Scanning reticle overlay
                    RoundedRectangle(cornerRadius: RZRadius.card)
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 280, height: 280)

                    // Corner accents
                    QRCornerOverlay()

                    if isProcessing {
                        RoundedRectangle(cornerRadius: RZRadius.card)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 280, height: 280)
                        VStack(spacing: RZSpacing.xs) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.4)
                            Text("Processing...")
                                .font(.rzBodySmall)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    }
                }

                Spacer()

                // Guidance text
                VStack(spacing: RZSpacing.xs) {
                    Text("Point your camera at the provider's QR code")
                        .font(.rzBody)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Having trouble? Ask the provider to complete manually.")
                        .font(.rzBodySmall)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, RZSpacing.xl)
                .padding(.bottom, RZSpacing.xl)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToResult) {
            QRCompletionResultScreen(state: resultState, reservationId: reservationId)
        }
    }

    private func handleCodeDetected(_ code: String) {
        guard !isProcessing else { return }
        isProcessing = true

        Task {
            defer { isProcessing = false }
            do {
                struct QRBody: Encodable { let qrToken: String }
                let _: Reservation = try await appState.apiClient.post(
                    APIEndpoints.reservationCompleteByQR(reservationId),
                    body: QRBody(qrToken: code)
                )
                resultState = .success
                navigateToResult = true
            } catch let error as APIError {
                switch error {
                case .notFound:
                    resultState = .invalid
                case .serverError(let code, _) where code == "QR_EXPIRED":
                    resultState = .expired
                case .serverError(let code, _) where code == "WRONG_CONTEXT":
                    resultState = .wrongContext
                case .serverError(let code, _) where code == "ALREADY_COMPLETED":
                    resultState = .alreadyCompleted
                default:
                    resultState = .fallback
                }
                navigateToResult = true
            } catch {
                resultState = .fallback
                navigateToResult = true
            }
        }
    }
}

// MARK: - Camera View Wrapper with ref access

private struct QRCameraViewWrapper: UIViewRepresentable {
    let onCameraReady: (QRCameraUIView) -> Void
    let onCodeDetected: (String) -> Void

    func makeUIView(context: Context) -> QRCameraUIView {
        let view = QRCameraUIView()
        view.onCodeDetected = onCodeDetected
        view.startSession()
        DispatchQueue.main.async {
            onCameraReady(view)
        }
        return view
    }

    func updateUIView(_ uiView: QRCameraUIView, context: Context) {}

    static func dismantleUIView(_ uiView: QRCameraUIView, coordinator: ()) {
        uiView.stopSession()
    }
}

// MARK: - Corner Overlay

private struct QRCornerOverlay: View {
    var body: some View {
        ZStack {
            // Top-left
            cornerShape().frame(width: 280, height: 280).overlay(alignment: .topLeading) {
                cornerMark()
            }
            // Top-right
            cornerMark().rotationEffect(.degrees(90))
                .frame(width: 280, height: 280, alignment: .topTrailing)
                .offset(x: 280/2 - 20, y: -280/2 + 4)
            // Bottom-left
            cornerMark().rotationEffect(.degrees(-90))
                .frame(width: 280, height: 280, alignment: .bottomLeading)
                .offset(x: -280/2 + 4, y: 280/2 - 20)
            // Bottom-right
            cornerMark().rotationEffect(.degrees(180))
                .frame(width: 280, height: 280, alignment: .bottomTrailing)
                .offset(x: 280/2 - 20, y: 280/2 - 20)
        }
    }

    private func cornerShape() -> some View {
        Color.clear.overlay(alignment: .topLeading) {
            cornerMark()
        }
    }

    private func cornerMark() -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 28))
            path.addLine(to: CGPoint(x: 0, y: 4))
            path.addQuadCurve(to: CGPoint(x: 4, y: 0), control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 28, y: 0))
        }
        .stroke(Color.rzPrimary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .frame(width: 32, height: 32)
        .offset(x: -280/2 + 4, y: -280/2 + 4)
    }
}
