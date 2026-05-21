import SwiftUI

struct ConsentView: View {
    @Environment(\.dismiss) private var dismiss
    let onStart: () -> Void

    @State private var isPulsing = false

    private let dotRed = Color(red: 0xE0/255.0, green: 0x50/255.0, blue: 0x7A/255.0)

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                Spacer()

                messageBlock
                    .padding(.horizontal, 32)

                indicatorRow
                    .padding(.top, 36)

                Spacer()

                startButton
                    .padding(.horizontal, 28)

                Text("good practice, and required by law in many places.")
                    .font(.body300(11))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
            }
        }
        .onAppear { isPulsing = true }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("cancel")
                    .font(.mono400(11))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(width: 80, height: 40, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("BEFORE WE LISTEN")
                .font(.mono400(10))
                .tracking(1.8)
                .foregroundStyle(Theme.inkFaint)

            Spacer()

            Color.clear.frame(width: 80, height: 40)
        }
    }

    private var messageBlock: some View {
        VStack(spacing: 16) {
            Text("please let everyone here know")
                .font(.body300(13))
                .tracking(0.4)
                .foregroundStyle(Theme.inkFaint)

            (
                Text("this phone is about to ")
                    .foregroundStyle(Theme.ink)
                +
                Text("listen")
                    .italic()
                    .foregroundStyle(Theme.accent)
                +
                Text(" to our conversation.")
                    .foregroundStyle(Theme.ink)
            )
            .font(.display400(28))
            .tracking(-0.4)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
        }
    }

    private var indicatorRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(dotRed)
                .frame(width: 9, height: 9)
                .opacity(isPulsing ? 1.0 : 0.4)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isPulsing)

            Text("LISTENING WILL START")
                .font(.mono400(11))
                .tracking(2.4)
                .foregroundStyle(Theme.inkMuted)
        }
    }

    private var startButton: some View {
        Button {
            onStart()
        } label: {
            Text("start")
                .font(.body300(15))
                .foregroundStyle(Theme.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.ink)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
