import Foundation

enum DemoMode {
    static let isOn: Bool = {
        if ProcessInfo.processInfo.environment["DEMO_MODE"] == "1" { return true }
        return ProcessInfo.processInfo.arguments.contains("--demo")
    }()

    static let screen: String = {
        if let env = ProcessInfo.processInfo.environment["DEMO_SCREEN"] { return env }
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "--screen"),
           idx + 1 < ProcessInfo.processInfo.arguments.count {
            return ProcessInfo.processInfo.arguments[idx + 1]
        }
        return "home-empty"
    }()

    static let mockTranscriptShort = """
    Honestly the part that surprised me was how much faster we shipped once we stopped polling every fifteen minutes. The whole rhythm changed. People felt unblocked.

    I think we should write this up. Even a short note. Otherwise the next team that hits this hires three more engineers and tries to scale the polling.

    Yeah, let's do that. I'll draft something tonight, send it tomorrow.
    """

    static let mockTranscriptMedium = """
    Coffee with Mara. She mentioned the new pricing tier going up to $40 a seat. I asked about grandfathering and she said the old plans get a 90-day notice. So if we want to lock in old pricing we have to commit before March.

    Also, she's hiring two more people in Q2. Front-end heavy. Says it's the right time to ask if I want to refer anyone.

    On the way back I realized I never followed up with Theo about the API doc. Need to do that this week.
    """

    static let mockTranscriptLong = """
    Quick standup notes. Three things.

    First, the migration is unblocked. The schema change went through, no downtime. Took about twelve minutes of degraded reads but nobody noticed because we'd already rolled the cache change. So lesson, do cache changes first when in doubt.

    Second, customer call with Lighthouse went well. They want the new dashboard and they're OK paying for it. We should price it. Devesh has the rough scope, I'll get a number to them by Friday.

    Third, we need to talk about on-call. I think the rotation is too short. Two people, weekly switching, is leaving us with handoff issues. Either we add a third person or we go to two-week rotations. I lean toward the longer rotation.

    Anything else.
    """

    static func sampleRecords(in ctx: NSObject? = nil) -> [TranscriptRecord] {
        let now = Date()
        let cal = Calendar.current

        let r1 = TranscriptRecord(
            localFilePath: "",
            transcript: mockTranscriptShort,
            duration: 184,
            createdAt: cal.date(byAdding: .hour, value: -2, to: now)!,
            status: "complete"
        )
        let r2 = TranscriptRecord(
            localFilePath: "",
            transcript: mockTranscriptMedium,
            duration: 412,
            createdAt: cal.date(byAdding: .hour, value: -8, to: now)!,
            status: "complete"
        )
        let r3 = TranscriptRecord(
            localFilePath: "",
            transcript: mockTranscriptLong,
            duration: 724,
            createdAt: cal.date(byAdding: .day, value: -2, to: now)!,
            status: "complete"
        )
        let r4 = TranscriptRecord(
            localFilePath: "",
            transcript: "Parent teacher conference notes. She's reading two grades above level. They want to test her for the accelerated track. I said yes, of course.",
            duration: 96,
            createdAt: cal.date(byAdding: .day, value: -5, to: now)!,
            status: "complete"
        )
        let r5 = TranscriptRecord(
            localFilePath: "",
            transcript: "Idea while walking the dog. What if onboarding pulled the user's actual data on day one instead of showing fake examples. We could surface their first three actions as suggestions.",
            duration: 58,
            createdAt: cal.date(byAdding: .day, value: -12, to: now)!,
            status: "complete"
        )
        return [r1, r2, r3, r4, r5]
    }
}
