import Foundation
import SwiftData
import Observation

enum SessionControllerError: Error, Equatable {
    case noSpace
    case noEnabledTasks
    case noActiveSession
    case spaceHasHistory
}

@MainActor
@Observable
final class SessionController {
    private(set) var engine = TimerEngine()
    private(set) var spaces: [Space] = []
    private(set) var selectedSpaceID: UUID?
    private(set) var lastError: String?

    var timeSource: any TimeSource
    var notifications: any NotificationScheduling
    var liveActivity: LiveActivityManaging
    var settings: SettingsStore
    var distraction = DistractionMonitor(activeSessionID: nil, threshold: 300)

    private let context: ModelContext
    private let launch: LaunchConfiguration

    var snapshot: TimerSnapshot { engine.snapshot }

    var selectedSpace: Space? {
        spaces.first(where: { $0.id == selectedSpaceID }) ?? spaces.first
    }

    var selectedTasks: [TaskItem] {
        selectedSpace?.enabledTasksSorted ?? []
    }

    var activeTask: TaskItem? {
        guard let id = snapshot.activeTaskID else {
            return selectedTasks.first
        }
        return selectedSpace?.tasks.first(where: { $0.id == id }) ?? selectedTasks.first
    }

    init(
        context: ModelContext,
        timeSource: any TimeSource = SystemTimeSource(),
        notifications: any NotificationScheduling = NotificationService(),
        liveActivity: LiveActivityManaging = LiveActivityManager(),
        settings: SettingsStore = SettingsStore(),
        launch: LaunchConfiguration = .default
    ) {
        self.context = context
        self.timeSource = timeSource
        self.notifications = notifications
        self.liveActivity = liveActivity
        self.settings = settings
        self.launch = launch
        self.distraction.threshold = settings.distractionTimeoutSeconds
    }

    func bootstrap() throws {
        try DemoDataSeeder.seedIfNeeded(context: context, force: launch.resetStore)
        try reloadSpaces()
        if let stored = settings.selectedSpaceID, spaces.contains(where: { $0.id == stored }) {
            selectedSpaceID = stored
        } else {
            selectedSpaceID = spaces.first?.id
        }
        try restoreActiveSessionIfNeeded()
        applyLaunchOverrides()
        AppRuntime.shared.sessionController = self
    }

    func reloadSpaces() throws {
        let descriptor = FetchDescriptor<Space>(sortBy: [SortDescriptor(\.displayOrder)])
        spaces = try context.fetch(descriptor)
    }

    func selectSpace(_ id: UUID) {
        selectSpace(id, haptic: false)
    }

    func selectSpace(_ id: UUID, haptic: Bool) {
        selectedSpaceID = id
        settings.selectedSpaceID = id
        if haptic {
            Haptics.spaceChange()
        }
    }

    func displayedElapsed(at now: Date) -> TimeInterval {
        if let frozen = launch.frozenElapsed, launch.screenshotMode {
            return frozen
        }
        return engine.snapshot.elapsed(at: now)
    }

    func start() throws {
        guard let space = selectedSpace else { throw SessionControllerError.noSpace }
        let now = timeSource.now()
        if engine.snapshot.phase == .paused {
            try resume()
            return
        }
        let tasks = space.enabledTasksSorted
        let task = tasks.first
        let session = Session(
            id: UUID(),
            startedAt: now,
            phase: .running,
            accumulatedActiveDuration: 0,
            currentSegmentStartedAt: now,
            activeTaskID: task?.id,
            space: space
        )
        context.insert(session)
        if let task {
            let interval = TaskInterval(startedAt: now, session: session, task: task)
            context.insert(interval)
        }
        try engine.start(now: now, sessionID: session.id, spaceID: space.id, taskID: task?.id)
        try persistSessionState(session)
        Haptics.start()
        notifications.requestAuthorizationIfNeeded()
        liveActivity.startOrUpdate(from: self, at: now)
        try context.save()
    }

    func pause() throws {
        let now = timeSource.now()
        try engine.pause(now: now)
        try closeOpenIntervals(at: now)
        try persistActiveSession(at: now)
        liveActivity.startOrUpdate(from: self, at: now)
        try context.save()
    }

    func resume() throws {
        guard let session = activeSession() else { throw SessionControllerError.noActiveSession }
        let now = timeSource.now()
        try engine.resume(now: now)
        if let task = activeTask {
            context.insert(TaskInterval(startedAt: now, session: session, task: task))
        }
        session.currentSegmentStartedAt = now
        session.phase = .running
        liveActivity.startOrUpdate(from: self, at: now)
        try context.save()
    }

    func stop() throws {
        let now = timeSource.now()
        try engine.stop(now: now)
        try closeOpenIntervals(at: now)
        if let session = activeSession() {
            session.endedAt = now
            session.phase = .stopped
            session.accumulatedActiveDuration = engine.snapshot.lastStoppedElapsed
            session.currentSegmentStartedAt = nil
            notifications.cancelDistractionReminder(sessionID: session.id)
        }
        Haptics.stop()
        liveActivity.end(at: now, elapsed: engine.snapshot.lastStoppedElapsed)
        try context.save()
    }

    func resetStoppedDisplay() {
        engine.reset()
        liveActivity.dismiss()
    }

    func lap() throws {
        guard engine.snapshot.phase == .running else { throw SessionControllerError.noActiveSession }
        guard let space = selectedSpace else { throw SessionControllerError.noSpace }
        let tasks = space.enabledTasksSorted
        guard !tasks.isEmpty else { throw SessionControllerError.noEnabledTasks }
        let now = timeSource.now()
        try closeOpenIntervals(at: now)
        let next = nextTask(after: engine.snapshot.activeTaskID, in: tasks)
        if let session = activeSession(), let next {
            context.insert(TaskInterval(startedAt: now, session: session, task: next))
            session.activeTaskID = next.id
        }
        if let next {
            try engine.lap(now: now, nextTaskID: next.id)
        }
        Haptics.lap()
        liveActivity.startOrUpdate(from: self, at: now)
        try context.save()
    }

    func selectTask(_ task: TaskItem) throws {
        guard engine.snapshot.isActiveSession else { throw SessionControllerError.noActiveSession }
        let now = timeSource.now()
        try closeOpenIntervals(at: now)
        if engine.snapshot.phase == .running, let session = activeSession() {
            context.insert(TaskInterval(startedAt: now, session: session, task: task))
            session.activeTaskID = task.id
        } else if let session = activeSession() {
            session.activeTaskID = task.id
        }
        try engine.selectTask(now: now, taskID: task.id)
        Haptics.lap()
        liveActivity.startOrUpdate(from: self, at: now)
        try context.save()
    }

    func nextTask(after currentID: UUID?, in tasks: [TaskItem]) -> TaskItem? {
        guard !tasks.isEmpty else { return nil }
        guard let currentID, let index = tasks.firstIndex(where: { $0.id == currentID }) else {
            return tasks.first
        }
        return tasks[(index + 1) % tasks.count]
    }

    func accumulatedDuration(for task: TaskItem, at now: Date) -> TimeInterval {
        let intervals = task.intervals.filter { interval in
            if let sessionID = engine.snapshot.sessionID {
                return interval.session?.id == sessionID
            }
            return false
        }
        return intervals.reduce(0) { $0 + $1.duration(at: now) }
    }

    func createSpace(name: String, tint: SpaceTint, tasks: [String]) throws -> Space {
        try reloadSpaces()
        let order = (spaces.map(\.displayOrder).max() ?? -1) + 1
        let space = Space(name: name, tint: tint, displayOrder: order)
        space.tasks = tasks.enumerated().map { index, taskName in
            TaskItem(name: taskName, displayOrder: index, space: space)
        }
        context.insert(space)
        try context.save()
        try reloadSpaces()
        return space
    }

    func importSpace(_ payload: SpaceImportPayload) throws -> Space {
        try createSpace(name: payload.name, tint: payload.color, tasks: payload.tasks)
    }

    func renameSpace(_ space: Space, to name: String) throws {
        space.name = name
        try context.save()
        try reloadSpaces()
    }

    func recolorSpace(_ space: Space, tint: SpaceTint) throws {
        space.tint = tint
        try context.save()
        try reloadSpaces()
    }

    func deleteSpace(_ space: Space, confirmHistory: Bool) throws {
        let hasHistory = !(space.sessions.isEmpty)
        if hasHistory && !confirmHistory {
            throw SessionControllerError.spaceHasHistory
        }
        if selectedSpaceID == space.id {
            if engine.snapshot.isActiveSession {
                try? stop()
            }
        }
        context.delete(space)
        try context.save()
        try reloadSpaces()
        if selectedSpaceID == space.id {
            selectedSpaceID = spaces.first?.id
            settings.selectedSpaceID = selectedSpaceID
        }
    }

    func addTask(to space: Space, name: String) throws {
        let order = (space.tasks.map(\.displayOrder).max() ?? -1) + 1
        context.insert(TaskItem(name: name, displayOrder: order, space: space))
        try context.save()
        try reloadSpaces()
    }

    func deleteTask(_ task: TaskItem) throws {
        if engine.snapshot.activeTaskID == task.id, engine.snapshot.isRunning {
            try lap()
        }
        context.delete(task)
        try context.save()
        try reloadSpaces()
    }

    func moveSpaces(from source: IndexSet, to destination: Int) throws {
        var ordered = spaces
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, space) in ordered.enumerated() {
            space.displayOrder = index
        }
        try context.save()
        try reloadSpaces()
    }

    func distractionStarted() {
        let active = engine.snapshot.isRunning
        let sessionID = engine.snapshot.sessionID
        let spaceName = selectedSpace?.name ?? "Timer"
        let elapsed = engine.snapshot.elapsed(at: timeSource.now())
        let threshold = selectedSpace?.distractionTimeoutSeconds ?? settings.distractionTimeoutSeconds
        distraction.threshold = threshold
        distraction.distractionStarted(isSessionActive: active, sessionID: sessionID) { id in
            notifications.scheduleDistractionReminder(
                sessionID: id,
                spaceName: spaceName,
                elapsed: elapsed,
                after: threshold
            )
        }
    }

    func distractionEnded() {
        distraction.distractionEnded { id in
            notifications.cancelDistractionReminder(sessionID: id)
        }
    }

    func allSessions() throws -> [Session] {
        let descriptor = FetchDescriptor<Session>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return try context.fetch(descriptor)
    }

    private func activeSession() -> Session? {
        guard let id = engine.snapshot.sessionID else { return nil }
        let all = (try? context.fetch(FetchDescriptor<Session>())) ?? []
        return all.first(where: { $0.id == id })
    }

    private func closeOpenIntervals(at now: Date) throws {
        guard let session = activeSession() else { return }
        for interval in session.intervals where interval.isOpen {
            interval.endedAt = now
        }
    }

    private func persistSessionState(_ session: Session) throws {
        session.phase = engine.snapshot.phase
        session.accumulatedActiveDuration = engine.snapshot.accumulatedActiveDuration
        session.currentSegmentStartedAt = engine.snapshot.currentSegmentStartedAt
        session.activeTaskID = engine.snapshot.activeTaskID
    }

    private func persistActiveSession(at now: Date) throws {
        guard let session = activeSession() else { return }
        session.phase = engine.snapshot.phase
        session.accumulatedActiveDuration = engine.snapshot.elapsed(at: now)
        if engine.snapshot.phase != .running {
            session.currentSegmentStartedAt = nil
        } else {
            session.currentSegmentStartedAt = engine.snapshot.currentSegmentStartedAt
        }
        session.activeTaskID = engine.snapshot.activeTaskID
    }

    private func restoreActiveSessionIfNeeded() throws {
        let descriptor = FetchDescriptor<Session>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let sessions = try context.fetch(descriptor)
        guard let session = sessions.first(where: { $0.phase == .running || $0.phase == .paused }) else {
            return
        }
        engine.restore(
            TimerSnapshot(
                phase: session.phase,
                sessionID: session.id,
                spaceID: session.space?.id,
                activeTaskID: session.activeTaskID,
                sessionStartedAt: session.startedAt,
                accumulatedActiveDuration: session.accumulatedActiveDuration,
                currentSegmentStartedAt: session.currentSegmentStartedAt,
                lastStoppedElapsed: 0
            )
        )
        if let spaceID = session.space?.id {
            selectedSpaceID = spaceID
        }
        liveActivity.startOrUpdate(from: self, at: timeSource.now())
    }

    private func applyLaunchOverrides() {
        guard launch.screenshotMode || launch.startRunning else { return }
        if engine.snapshot.phase == .idle || engine.snapshot.phase == .stopped {
            try? start()
        }
        if let frozen = launch.frozenElapsed, let session = activeSession() {
            session.accumulatedActiveDuration = frozen
            session.currentSegmentStartedAt = timeSource.now()
            engine.snapshot.accumulatedActiveDuration = 0
            engine.snapshot.currentSegmentStartedAt = timeSource.now().addingTimeInterval(-frozen)
        }
    }
}
