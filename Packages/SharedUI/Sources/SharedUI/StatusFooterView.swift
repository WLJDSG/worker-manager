import SwiftUI

public struct StatusFooterView: View {
    public let iconName: String
    public let color: Color
    public let message: String

    public init(iconName: String, color: Color, message: String) {
        self.iconName = iconName
        self.color = color
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundStyle(color)
            Text(message)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.footnote)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}