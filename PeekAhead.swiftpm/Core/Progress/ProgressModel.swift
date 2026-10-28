import Foundation
import Observation

/// The child's saved progress and the grown-up's settings, saved after every change.
@MainActor
@Observable
final class ProgressModel {
    /// The most check-ins kept; older ones are dropped first.
    static let feelingsLimit = 200

    private(set) var state: ProgressState
    /// `true` when the last save failed. Grown-up mode shows a notice; the child is never interrupted.
    private(set) var lastSaveFailed = false
    /// `true` when saved progress could not be read at launch and the app started fresh.
    private(set) var startedFresh = false

    @ObservationIgnored private let store: any ProgressStoring
    @ObservationIgnored private let now: () -> Date
    /// Set when the saved file comes from a newer app version: it is never overwritten by this one.
    @ObservationIgnored private var savesDisabled = false

    init(store: any ProgressStoring, now: @escaping () -> Date = Date.init) {
        self.store = store
        self.now = now
        do {
            state = try store.load() ?? ProgressState()
        } catch ProgressStoreError.newerVersion {
            state = ProgressState()
            startedFresh = true
            savesDisabled = true
        } catch {
            store.setAsideUnreadable()
            state = ProgressState()
            startedFresh = true
        }
    }

    var settings: AppSettings { state.settings }

    // MARK: Rewards

    var rewardOffer: [RoomItem] { RewardCatalog.offer(owned: state.roomItems) }

    func place(_ item: RoomItem) {
        guard !state.roomItems.contains(item) else { return }
        mutate { $0.roomItems.append(item) }
    }

    // MARK: Feelings

    func logFeeling(_ feeling: Feeling, for story: Story) {
        // Whole seconds: the file stores ISO 8601 dates, so the entry reads back exactly as it was saved.
        let date = Date(timeIntervalSince1970: now().timeIntervalSince1970.rounded(.down))
        let entry = FeelingEntry(storyID: story.id, storyTitle: story.title, feeling: feeling, date: date)
        mutate { state in
            state.feelings.append(entry)
            if state.feelings.count > Self.feelingsLimit {
                state.feelings.removeFirst(state.feelings.count - Self.feelingsLimit)
            }
        }
    }

    // MARK: Day plan and calm tools

    func setCalmTools(_ tools: Set<CalmTool>) {
        mutate { $0.calmTools = CalmTool.allCases.filter(tools.contains) }
    }

    func setDayPlan(_ plan: DayPlan?) {
        mutate { $0.dayPlan = plan }
    }

    func advanceDayPlan() {
        mutate { $0.dayPlan?.advance() }
    }

    // MARK: Settings and data

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        mutate { change(&$0.settings) }
    }

    /// Clears everything the child and grown-up have saved, settings included.
    func deleteAllData() {
        mutate { $0 = ProgressState() }
    }

    private func mutate(_ change: (inout ProgressState) -> Void) {
        change(&state)
        guard !savesDisabled else {
            lastSaveFailed = true
            return
        }
        do {
            try store.save(state)
            lastSaveFailed = false
        } catch {
            lastSaveFailed = true
        }
    }
}
