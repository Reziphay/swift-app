import Foundation
import UserNotifications

@Observable
final class PushNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    var deviceToken: String?
    var isPermissionGranted: Bool = false

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            isPermissionGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            isPermissionGranted = false
        }
    }

    func registerToken(_ token: String) async {
        deviceToken = token
        let body: [String: String] = [
            "token": token,
            "platform": "IOS"
        ]
        try? await apiClient.postVoid(APIEndpoints.pushTokens, body: body)
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
