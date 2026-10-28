import Foundation

/// How Pip moves on screen: slow, small, and only when the system allows motion.
struct PipMotion: Equatable, Sendable {
    /// How far Pip floats up and down, in metres (Pip is about 1.1 m tall in the model).
    let bobHeight: Float
    /// Seconds for one full up-and-down cycle.
    let bobPeriod: Double
    /// How many times Pip waves when greeting or tapped.
    let waveCount: Int
    /// Seconds for one arm movement (up or down).
    let waveStepDuration: Double

    static let calm = PipMotion(bobHeight: 0.03, bobPeriod: 2.4, waveCount: 2, waveStepDuration: 0.35)

    /// The motion to use, or `nil` when Reduce Motion is on. Pip then stands still in a friendly pose.
    static func forSettings(reduceMotion: Bool) -> PipMotion? {
        reduceMotion ? nil : .calm
    }
}
