import SwiftUI

@MainActor
@Observable
final class EightBallModel {
    enum Phase: Equatable {
        case idle
        case shaking
        case answered(String)
    }

    /// The 20 classic answers: 10 affirmative, 5 non-committal, 5 negative.
    static let answers = [
        "It is certain",
        "It is decidedly so",
        "Without a doubt",
        "Yes definitely",
        "You may rely on it",
        "As I see it, yes",
        "Most likely",
        "Outlook good",
        "Yes",
        "Signs point to yes",
        "Reply hazy, try again",
        "Ask again later",
        "Better not tell you now",
        "Cannot predict now",
        "Concentrate and ask again",
        "Don't count on it",
        "My reply is no",
        "My sources say no",
        "Outlook not so good",
        "Very doubtful",
    ]

    /// How long the ball "thinks" before the answer floats up.
    static let shakeDuration: Duration = .milliseconds(1000)

    private(set) var phase: Phase = .idle
    private var lastAnswer: String?

    func ask() {
        guard phase != .shaking else { return }
        phase = .shaking
        Task {
            try? await Task.sleep(for: Self.shakeDuration)
            let answer = Self.answers.filter { $0 != lastAnswer }.randomElement()!
            lastAnswer = answer
            phase = .answered(answer)
        }
    }
}
