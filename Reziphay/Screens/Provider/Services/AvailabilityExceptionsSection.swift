import SwiftUI

// MARK: - Supporting Type

struct AvailabilityExceptionInput: Identifiable {
    var id = UUID()
    var date: String
    var isClosedAllDay: Bool
    var startTime: String
    var endTime: String
    var note: String
}

// MARK: - AvailabilityExceptionsSection

struct AvailabilityExceptionsSection: View {
    @Binding var exceptions: [AvailabilityExceptionInput]

    var body: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            HStack {
                Text("Closed Days & Exceptions")
                    .font(.rzH4)
                    .foregroundStyle(.rzTextPrimary)
                Spacer()
                Button {
                    addException()
                } label: {
                    HStack(spacing: RZSpacing.xxxs) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Exception")
                            .font(.rzBodySmall)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.rzPrimary)
                }
                .buttonStyle(.plain)
            }

            if exceptions.isEmpty {
                emptyPlaceholder
            } else {
                VStack(spacing: RZSpacing.xs) {
                    ForEach($exceptions) { $exception in
                        exceptionRow(exception: $exception)
                    }
                }
            }
        }
    }

    // MARK: - Empty Placeholder

    private var emptyPlaceholder: some View {
        HStack {
            Spacer()
            VStack(spacing: RZSpacing.xxs) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.rzTextTertiary)
                Text("No exceptions added")
                    .font(.rzBodySmall)
                    .foregroundStyle(.rzTextTertiary)
                Text("Tap \"Add Exception\" to block off holidays or modified hours.")
                    .font(.rzCaption)
                    .foregroundStyle(.rzTextTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, RZSpacing.md)
            Spacer()
        }
        .background(Color.rzSurface)
        .clipShape(RoundedRectangle(cornerRadius: RZRadius.card))
    }

    // MARK: - Exception Row

    private func exceptionRow(exception: Binding<AvailabilityExceptionInput>) -> some View {
        RZCard {
            VStack(alignment: .leading, spacing: RZSpacing.xs) {
                HStack {
                    RZTextField(
                        title: "Date (YYYY-MM-DD)",
                        placeholder: "2024-12-25",
                        text: exception.date
                    )
                    .frame(maxWidth: .infinity)

                    Button {
                        withAnimation {
                            exceptions.removeAll { $0.id == exception.wrappedValue.id }
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.rzError)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, RZSpacing.md)
                    .padding(.leading, RZSpacing.xxs)
                }

                Toggle(isOn: exception.isClosedAllDay) {
                    Text("Closed all day")
                        .font(.rzBodySmall)
                        .foregroundStyle(.rzTextPrimary)
                }
                .tint(.rzPrimary)

                if !exception.wrappedValue.isClosedAllDay {
                    HStack(spacing: RZSpacing.xs) {
                        RZTextField(
                            title: "Open From",
                            placeholder: "09:00",
                            text: exception.startTime
                        )
                        RZTextField(
                            title: "Open Until",
                            placeholder: "18:00",
                            text: exception.endTime
                        )
                    }
                }

                RZTextField(
                    title: "Note (optional)",
                    placeholder: "e.g. Holiday — reduced hours",
                    text: exception.note
                )
            }
        }
    }

    // MARK: - Action

    private func addException() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        withAnimation {
            exceptions.append(AvailabilityExceptionInput(
                date: today,
                isClosedAllDay: true,
                startTime: "09:00",
                endTime: "18:00",
                note: ""
            ))
        }
    }
}
