import SwiftUI

// MARK: - Supporting Types

struct AvailabilityRuleInput: Identifiable {
    var id = UUID()
    var dayOfWeek: DayOfWeek
    var startTime: String
    var endTime: String
    var isActive: Bool
}

extension AvailabilityRuleInput {
    static var defaultWeeklyRules: [AvailabilityRuleInput] {
        DayOfWeek.allCases.map { day in
            let isWeekend = day == .saturday || day == .sunday
            return AvailabilityRuleInput(
                dayOfWeek: day,
                startTime: "09:00",
                endTime: "18:00",
                isActive: !isWeekend
            )
        }
    }
}

// MARK: - AvailabilityRulesEditorSection

struct AvailabilityRulesEditorSection: View {
    @Binding var rules: [AvailabilityRuleInput]

    var body: some View {
        VStack(alignment: .leading, spacing: RZSpacing.xs) {
            Text("Weekly Availability")
                .font(.rzH4)
                .foregroundStyle(.rzTextPrimary)

            RZCard {
                VStack(spacing: 0) {
                    ForEach($rules) { $rule in
                        VStack(spacing: 0) {
                            dayRow(rule: $rule)
                            if rule.id != rules.last?.id {
                                Divider()
                                    .padding(.leading, RZSpacing.md)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Day Row

    private func dayRow(rule: Binding<AvailabilityRuleInput>) -> some View {
        VStack(spacing: RZSpacing.xs) {
            HStack(spacing: RZSpacing.sm) {
                Toggle(isOn: rule.isActive) {
                    Text(rule.wrappedValue.dayOfWeek.displayName)
                        .font(.rzBodySmall)
                        .fontWeight(.medium)
                        .foregroundStyle(rule.wrappedValue.isActive ? .rzTextPrimary : .rzTextTertiary)
                        .frame(width: 90, alignment: .leading)
                }
                .tint(.rzPrimary)
                .labelsHidden()

                Text(rule.wrappedValue.dayOfWeek.displayName)
                    .font(.rzBodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(rule.wrappedValue.isActive ? .rzTextPrimary : .rzTextTertiary)
                    .frame(width: 90, alignment: .leading)

                Spacer()

                if rule.wrappedValue.isActive {
                    HStack(spacing: RZSpacing.xxs) {
                        timeInput(label: "From", time: rule.startTime)
                        Text("–")
                            .font(.rzBodySmall)
                            .foregroundStyle(.rzTextTertiary)
                        timeInput(label: "To", time: rule.endTime)
                    }
                } else {
                    Text("Closed")
                        .font(.rzCaption)
                        .foregroundStyle(.rzTextTertiary)
                        .padding(.trailing, RZSpacing.xxs)
                }
            }
            .padding(.vertical, RZSpacing.xs)
            .padding(.horizontal, RZSpacing.sm)
        }
    }

    private func timeInput(label: String, time: Binding<String>) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.rzCaption)
                .foregroundStyle(.rzTextTertiary)
            TextField("HH:mm", text: time)
                .font(.rzBodySmall)
                .fontWeight(.medium)
                .foregroundStyle(.rzTextPrimary)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .frame(width: 52)
                .padding(.vertical, 6)
                .padding(.horizontal, RZSpacing.xxs)
                .background(Color.rzInputBackground)
                .clipShape(RoundedRectangle(cornerRadius: RZRadius.input))
        }
    }
}

// MARK: - DayOfWeek Display
