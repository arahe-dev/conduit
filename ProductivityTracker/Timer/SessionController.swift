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
    private var engines: [UUID: TimerEngine] = [:]
    private(set) var snapshots: [UUID: TimerSnapshot] = [:]
    private(set) var spaces: [Space] = []
    private(set) var selectedSpaceID: UUID?
    private(set) var lastError: String?
    private(set) var mutation: UInt64 = 0

    var timeSource: any TimeSource
    var notifications: any NotificationScheduling
    var liveActivity: LiveActivityManaging
    var settings: SettingsStore
    var distraction = DistractionMonitor(activeSessionID: nil, threshold: 300)

    private let context: ModelContext
    let launch: LaunchConfiguration

    var snapshot: TimerSnapshot {
        _ = mutation
        guard let id = selectedSpaceID else {
            return .idle(spaceID: DemoIDs.work)
        }
        return snapshots[id] ?? engine(for: id).snapshot
    }

    var selectedSpace: Space? {
        spaces.first(where: { $0.id == selectedSpaceID }) ?? spaces.first
    }

    var selectedTasks: [TaskItem] {
        selectedSpace?.enabledTasksSorted ?? []
    }

    func displayedTasks(in space: Space) -> [TaskItem] {
        space.enabledTasksSorted
    }

    var runningSpaceID: UUID? {
        spaces.map(\.id).first { snapshots[$0]?.phase == .running }
    }

    var activeTask: TaskItem? {
        let space = selectedSpace
        if let id = snapshot.currentTaskID,
           let match = space?.tasks.first(where: { $0.id == id }) {
            return match
        }
        return nil
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
        if launch.screenshotMode || launch.resetStore {
            selectedSpaceID = DemoIDs.work
            settings.selectedSpaceID = DemoIDs.work
        } else if let stored = settings.selectedSpaceID, spaces.contains(where: { $0.id == stored }) {
            selectedSpaceID = stored
        } else {
            selectedSpaceID = spaces.first?.id
        }
        for space in spaces {
            let preferred = preferredTaskID(in: space)
            let engine = engine(for: space.id)
            if engine.snapshot.currentTaskID == nil {
                engine.selectTask(preferred)
                publish(engine)
            }
        }
        try restoreOpenSessions()
        applyLaunchOverrides()
        AppRuntime.shared.sessionController = self
    }

    func reloadSpaces() throws {
        let descriptor = FetchDescriptor<Space>(sortBy: [SortDescriptor(\.displayOrder)])
        spaces = try context.fetch(descriptor)
        noteChange()
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
        if runningSpaceID != nil || snapshots.values.contains(where: { $0.phase == .stopped }) {
            liveActivity.startOrUpdate(from: self, at: timeSource.now())
        }
        noteChange()
    }

    func displayOverrideElapsed(for spaceID: UUID) -> TimeInterval? {
        guard launch.screenshotMode, let frozen = launch.frozenElapsed, spaceID == selectedSpaceID else {
            return nil
        }
        if snapshot(for: spaceID).isIdle { return 0 }
        return frozen
    }

    func displayedElapsed(at now: Date) -> TimeInterval {
        displayedElapsed(for: selectedSpaceID, at: now)
    }

    func displayedElapsed(for spaceID: UUID?, at now: Date) -> TimeInterval {
        guard let spaceID else { return 0 }
        if let frozen = launch.frozenElapsed, launch.screenshotMode, spaceID == selectedSpaceID {
            let phase = snapshot(for: spaceID).phase
            if phase == .idle { return 0 }
            return frozen
        }
        return snapshot(for: spaceID).elapsed(at: now)
    }

    func snapshot(for spaceID: UUID) -> TimerSnapshot {
        _ = mutation
        return snapshots[spaceID] ?? engine(for: spaceID).snapshot
    }

    func start() throws {
        guard let space = selectedSpace else { throw SessionControllerError.noSpace }
        try start(in: space)
    }

    func start(in space: Space, publishLiveActivity: Bool = true) throws {
        if selectedSpaceID != space.id {
            selectSpace(space.id)
        }
        let now = timeSource.now()
        if let runningID = runningSpaceID, runningID != space.id {
            try freezeSpace(runningID, at: now, haptic: false)
        }
        let engine = engine(for: space.id)
        switch engine.snapshot.phase {
        case .running:
            return
        case .stopped:
            try resumeStopped(space: space, engine: engine, at: now)
        case .idle:
            try startNew(space: space, engine: engine, at: now)
        }
        Haptics.start()
        notifications.requestAuthorizationIfNeeded()
        if publishLiveActivity {
            liveActivity.startOrUpdate(from: self, at: now)
        }
        try context.save()
        noteChange()
    }

    func stop() throws {
        guard let space = selectedSpace else { throw SessionControllerError.noSpace }
        try stop(in: space)
    }

    func stop(in space: Space, publishLiveActivity: Bool = true) throws {
        let now = timeSource.now()
        try freezeSpace(space.id, at: now, haptic: true)
        if publishLiveActivity {
            liveActivity.startOrUpdate(from: self, at: now)
        }
        try context.save()
        noteChange()
    }

    func pause() throws {
        try stop()
    }

    func resume() throws {
        try start()
    }

    func reset() throws {
        guard let space = selectedSpace else { throw SessionControllerError.noSpace }
        try reset(in: space)
    }

    func reset(in space: Space, publishLiveActivity: Bool = true) throws {
        if selectedSpaceID != space.id {
            selectSpace(space.id)
        }
        let engine = engine(for: space.id)
        let now = timeSource.now()
        if engine.snapshot.phase == .running {
            try freezeSpace(space.id, at: now, haptic: false)
        }
        guard engine.snapshot.phase == .stopped else { return }
        try closeOpenIntervals(sessionID: engine.snapshot.sessionID, at: now)
        if let session = session(id: engine.snapshot.sessionID) {
            let elapsed = engine.snapshot.elapsed(at: now)
            if elapsed > 0.0005 {
                session.endedAt = now
                session.phase = .stopped
                session.accumulatedActiveDuration = elapsed
                session.currentSegmentStartedAt = nil
            } else {
                context.delete(session)
            }
        }
        let keptTask = engine.snapshot.currentTaskID
        engine.resetDisplay()
        engine.selectTask(keptTask)
        publish(engine)
        if publishLiveActivity {
            liveActivity.dismissImmediate()
        }
        try context.save()
        noteChange()
    }

    func lap() throws {
        guard let space = selectedSpace else { throw SessionControllerError.noSpace }
        try lap(in: space)
    }

    func lap(in space: Space) throws {
        if selectedSpaceID != space.id {
            selectSpace(space.id)
        }
        let engine = engine(for: space.id)
        guard engine.snapshot.phase == .running else { throw SessionControllerError.noActiveSession }
        let tasks = space.timingTasksSorted
        guard !tasks.isEmpty else { throw SessionControllerError.noEnabledTasks }
        let now = timeSource.now()
        try closeOpenIntervals(sessionID: engine.snapshot.sessionID, at: now)
        let next = nextTask(after: engine.snapshot.currentTaskID, in: tasks)
        if let session = session(id: engine.snapshot.sessionID), let next {
            context.insert(TaskInterval(startedAt: now, session: session, task: next))
            session.activeTaskID = next.id
        }
        engine.selectTask(next?.id)
        publish(engine)
        Haptics.lap()
        liveActivity.startOrUpdate(from: self, at: now)
        try context.save()
        noteChange()
    }

    func selectTask(_ task: TaskItem) throws {
        guard task.isEnabled, !task.isCompleted else { return }
        guard let space = task.space ?? selectedSpace else { throw SessionControllerError.noSpace }
        if selectedSpaceID != space.id {
            selectSpace(space.id)
        }
        let engine = engine(for: space.id)
        if engine.snapshot.currentTaskID == task.id {
            return
        }
        let now = timeSource.now()
        switch engine.snapshot.phase {
        case .running:
            try closeOpenIntervals(sessionID: engine.snapshot.sessionID, at: now)
            if let session = session(id: engine.snapshot.sessionID) {
                context.insert(TaskInterval(startedAt: now, session: session, task: task))
                session.activeTaskID = task.id
            }
            engine.selectTask(task.id)
            publish(engine)
            Haptics.selection()
            liveActivity.startOrUpdate(from: self, at: now)
        case .stopped:
            if let session = session(id: engine.snapshot.sessionID) {
                session.activeTaskID = task.id
            }
            engine.selectTask(task.id)
            publish(engine)
            Haptics.selection()
        case .idle:
            engine.selectTask(task.id)
            publish(engine)
            Haptics.selection()
        }
        try context.save()
        noteChange()
    }

    func nextTask(after currentID: UUID?, in tasks: [TaskItem]) -> TaskItem? {
        guard !tasks.isEmpty else { return nil }
        guard let currentID, let index = tasks.firstIndex(where: { $0.id == currentID }) else {
            return tasks.first
        }
        return tasks[(index + 1) % tasks.count]
    }

    func taskElapsedParts(for task: TaskItem) -> (closed: TimeInterval, openStartedAt: Date?) {
        guard let spaceID = task.space?.id ?? selectedSpaceID else { return (0, nil) }
        guard let sessionID = snapshot(for: spaceID).sessionID else { return (0, nil) }
        var closed: TimeInterval = 0
        var openStartedAt: Date?
        for interval in task.intervals where interval.session?.id == sessionID {
            if let ended = interval.endedAt {
                closed += max(0, ended.timeIntervalSince(interval.startedAt))
            } else {
                openStartedAt = interval.startedAt
            }
        }
        return (closed, openStartedAt)
    }

    func accumulatedDuration(for task: TaskItem, at now: Date) -> TimeInterval {
        let parts = taskElapsedParts(for: task)
        var total = parts.closed
        if snapshot(for: task.space?.id ?? selectedSpaceID ?? DemoIDs.work).isRunning, let start = parts.openStartedAt {
            total += now.timeIntervalSince(start)
        }
        return total
    }

    func createSpace(name: String, tint: SpaceTint, tasks: [String], icon: SpaceIcon = .fallback) throws -> Space {
        try reloadSpaces()
        let order = (spaces.map(\.displayOrder).max() ?? -1) + 1
        let space = Space(name: name, tint: tint, displayOrder: order, icon: icon)
        let items = tasks.enumerated().map { index, taskName in
            TaskItem(name: taskName, displayOrder: index, space: space)
        }
        space.tasks = items
        space.defaultTaskID = items.first?.id
        context.insert(space)
        try context.save()
        try reloadSpaces()
        return space
    }

    func importSpace(_ payload: SpaceImportPayload) throws -> Space {
        try createSpace(name: payload.name, tint: payload.color, tasks: payload.tasks, icon: .monogram(from: payload.name))
    }

    func renameSpace(_ space: Space, to name: String) throws {
        space.name = name
        try context.save()
        try reloadSpaces()
        liveActivity.startOrUpdate(from: self, at: timeSource.now())
    }

    func recolorSpace(_ space: Space, tint: SpaceTint) throws {
        space.tint = tint
        try context.save()
        try reloadSpaces()
        liveActivity.startOrUpdate(from: self, at: timeSource.now())
    }

    func setSpaceIcon(_ space: Space, icon: SpaceIcon) throws {
        space.icon = icon
        try context.save()
        try reloadSpaces()
        liveActivity.startOrUpdate(from: self, at: timeSource.now())
    }

    func setDefaultTask(_ task: TaskItem?, for space: Space) throws {
        space.defaultTaskID = task?.id
        let engine = engine(for: space.id)
        if engine.snapshot.isIdle {
            engine.selectTask(task?.id ?? space.timingTasksSorted.first?.id)
            publish(engine)
        }
        try context.save()
        try reloadSpaces()
    }

    func setReminder(for space: Space, seconds: Double) throws {
        space.distractionTimeoutSeconds = max(0, seconds)
        try context.save()
        try reloadSpaces()
    }

    func setFocusKeyword(_ keyword: String?, for space: Space) throws {
        let trimmed = keyword?.trimmingCharacters(in: .whitespacesAndNewlines)
        space.focusKeyword = (trimmed?.isEmpty == true) ? nil : trimmed
        try context.save()
        try reloadSpaces()
    }

    func deleteSpace(_ space: Space, confirmHistory: Bool) throws {
        let hasHistory = space.sessions.contains { $0.endedAt != nil || $0.endedAt == nil && $0.accumulatedActiveDuration > 0 || !$0.intervals.isEmpty }
        if hasHistory && !confirmHistory {
            throw SessionControllerError.spaceHasHistory
        }
        if snapshots[space.id]?.phase == .running {
            try freezeSpace(space.id, at: timeSource.now(), haptic: false)
        }
        if snapshots[space.id]?.phase == .stopped {
            selectedSpaceID = space.id
            try? reset()
        }
        engines[space.id] = nil
        snapshots[space.id] = nil
        context.delete(space)
        try context.save()
        try reloadSpaces()
        if selectedSpaceID == space.id {
            selectedSpaceID = spaces.first?.id
            settings.selectedSpaceID = selectedSpaceID
        }
        noteChange()
    }

    func addTask(to space: Space, name: String) throws {
        let order = (space.tasks.map(\.displayOrder).max() ?? -1) + 1
        let task = TaskItem(name: name, displayOrder: order, space: space)
        context.insert(task)
        if space.defaultTaskID == nil {
            space.defaultTaskID = task.id
        }
        try context.save()
        try reloadSpaces()
    }

    func renameTask(_ task: TaskItem, to name: String) throws {
        task.name = name
        try context.save()
        try reloadSpaces()
        liveActivity.startOrUpdate(from: self, at: timeSource.now())
    }

    func setTaskEnabled(_ task: TaskItem, isEnabled: Bool) throws {
        task.isEnabled = isEnabled
        if !isEnabled, snapshot(for: task.space?.id ?? selectedSpaceID ?? DemoIDs.work).currentTaskID == task.id {
            try handleRemovedActiveTask(task)
        }
        try context.save()
        try reloadSpaces()
    }

    func setTaskCompleted(_ task: TaskItem, isCompleted: Bool) throws {
        task.isCompleted = isCompleted
        if isCompleted, snapshot(for: task.space?.id ?? selectedSpaceID ?? DemoIDs.work).currentTaskID == task.id {
            try handleRemovedActiveTask(task)
        }
        try context.save()
        try reloadSpaces()
        liveActivity.startOrUpdate(from: self, at: timeSource.now())
        noteChange()
    }

    func moveTasks(in space: Space, from source: IndexSet, to destination: Int) throws {
        var ordered = space.allTasksSorted
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in ordered.enumerated() {
            task.displayOrder = index
        }
        try context.save()
        try reloadSpaces()
    }

    func deleteTask(_ task: TaskItem) throws {
        if snapshot.currentTaskID == task.id {
            try handleRemovedActiveTask(task)
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
        let runningID = runningSpaceID
        let snap = runningID.map { snapshot(for: $0) }
        let active = snap?.phase == .running
        let sessionID = snap?.sessionID
        let space = runningID.flatMap { id in spaces.first { $0.id == id } } ?? selectedSpace
        let spaceName = space?.name ?? "Timer"
        let elapsed = snap?.elapsed(at: timeSource.now()) ?? 0
        let threshold = space?.distractionTimeoutSeconds ?? settings.distractionTimeoutSeconds
        distraction.threshold = threshold
        guard threshold > 0 else { return }
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

    func historicalSessions() throws -> [Session] {
        try allSessions().filter { $0.endedAt != nil }
    }

    func saveTime(in space: Space) throws {
        let now = timeSource.now()
        let snap = snapshot(for: space.id)
        let elapsed = snap.elapsed(at: now)
        guard elapsed > 0.0005 else { return }
        let taskName = space.tasks.first(where: { $0.id == snap.currentTaskID })?.name
        let record = TimeSave(
            name: TimeSave.makeName(space: space.name, task: taskName, at: now),
            savedAt: now,
            elapsed: elapsed,
            spaceID: space.id,
            spaceName: space.name,
            taskName: taskName
        )
        context.insert(record)
        try context.save()
        Haptics.selection()
        noteChange()
    }

    func savedTimes(filter: SavedTimeFilter) throws -> [TimeSave] {
        let descriptor = FetchDescriptor<TimeSave>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)])
        let all = try context.fetch(descriptor)
        switch filter {
        case .all:
            return all
        case .space(let id):
            return all.filter { $0.spaceID == id }
        }
    }

    func deleteSavedTime(_ record: TimeSave) throws {
        context.delete(record)
        try context.save()
        noteChange()
    }

    func startFromLiveActivity() async {
        guard let space = liveActivitySpace() else { return }
        try? start(in: space, publishLiveActivity: false)
        await liveActivity.startOrUpdateAndWait(from: self, at: timeSource.now())
    }

    func stopFromLiveActivity() async {
        guard let space = liveActivitySpace() else { return }
        try? stop(in: space, publishLiveActivity: false)
        await liveActivity.startOrUpdateAndWait(from: self, at: timeSource.now())
    }

    func resetFromLiveActivity() async {
        guard let space = liveActivitySpace() else { return }
        try? reset(in: space, publishLiveActivity: false)
        await liveActivity.dismissAndWait()
    }

    func lapFromLiveActivity() throws {
        guard let space = liveActivitySpace() else { throw SessionControllerError.noSpace }
        try lap(in: space)
    }

    func liveActivitySpace() -> Space? {
        if let id = runningSpaceID {
            return spaces.first { $0.id == id }
        }
        if snapshot.phase == .stopped {
            return selectedSpace
        }
        return spaces.first { snapshots[$0.id]?.phase == .stopped }
    }

    private func startNew(space: Space, engine: TimerEngine, at now: Date) throws {
        let task = initialTask(in: space, engine: engine)
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
            context.insert(TaskInterval(startedAt: now, session: session, task: task))
        }
        engine.selectTask(task?.id)
        engine.start(now: now, sessionID: session.id)
        persistSession(session, from: engine)
        publish(engine)
    }

    private func resumeStopped(space: Space, engine: TimerEngine, at now: Date) throws {
        guard let session = session(id: engine.snapshot.sessionID) else {
            try startNew(space: space, engine: engine, at: now)
            return
        }
        let taskID = engine.snapshot.currentTaskID
        let task = taskID.flatMap { id in space.timingTasksSorted.first { $0.id == id } }
        engine.start(now: now, sessionID: session.id)
        session.phase = .running
        session.currentSegmentStartedAt = now
        session.activeTaskID = task?.id
        if let task {
            context.insert(TaskInterval(startedAt: now, session: session, task: task))
        }
        persistSession(session, from: engine)
        publish(engine)
    }

    private func freezeSpace(_ spaceID: UUID, at now: Date, haptic: Bool) throws {
        let engine = engine(for: spaceID)
        guard engine.snapshot.phase == .running else { return }
        engine.stop(now: now)
        try closeOpenIntervals(sessionID: engine.snapshot.sessionID, at: now)
        if let session = session(id: engine.snapshot.sessionID) {
            session.endedAt = nil
            session.phase = .stopped
            session.accumulatedActiveDuration = engine.snapshot.accumulatedBeforeCurrentRun
            session.currentSegmentStartedAt = nil
            session.activeTaskID = engine.snapshot.currentTaskID
            notifications.cancelDistractionReminder(sessionID: session.id)
        }
        publish(engine)
        if haptic {
            Haptics.stop()
        }
    }

    private func handleRemovedActiveTask(_ task: TaskItem) throws {
        guard let space = task.space else { return }
        let engine = engine(for: space.id)
        let now = timeSource.now()
        let remaining = space.timingTasksSorted.filter { $0.id != task.id }
        let next = remaining.first
        if engine.snapshot.phase == .running {
            try closeOpenIntervals(sessionID: engine.snapshot.sessionID, at: now)
            if let session = session(id: engine.snapshot.sessionID), let next {
                context.insert(TaskInterval(startedAt: now, session: session, task: next))
                session.activeTaskID = next.id
            } else if let session = session(id: engine.snapshot.sessionID) {
                session.activeTaskID = nil
            }
            liveActivity.startOrUpdate(from: self, at: now)
        } else if let session = session(id: engine.snapshot.sessionID) {
            session.activeTaskID = next?.id
        }
        engine.selectTask(next?.id)
        publish(engine)
    }

    private func initialTask(in space: Space, engine: TimerEngine) -> TaskItem? {
        let enabled = space.timingTasksSorted
        if let current = engine.snapshot.currentTaskID,
           let match = enabled.first(where: { $0.id == current }) {
            return match
        }
        if let defaultID = space.defaultTaskID,
           let match = enabled.first(where: { $0.id == defaultID }) {
            return match
        }
        return enabled.first
    }

    private func preferredTaskID(in space: Space) -> UUID? {
        if let defaultID = space.defaultTaskID,
           space.timingTasksSorted.contains(where: { $0.id == defaultID }) {
            return defaultID
        }
        return space.timingTasksSorted.first?.id
    }

    private func session(id: UUID?) -> Session? {
        guard let id else { return nil }
        let all = (try? context.fetch(FetchDescriptor<Session>())) ?? []
        return all.first(where: { $0.id == id })
    }

    private func closeOpenIntervals(sessionID: UUID?, at now: Date) throws {
        guard let session = session(id: sessionID) else { return }
        for interval in session.intervals where interval.isOpen {
            interval.endedAt = now
        }
    }

    private func persistSession(_ session: Session, from engine: TimerEngine) {
        session.phase = engine.snapshot.phase
        session.accumulatedActiveDuration = engine.snapshot.accumulatedBeforeCurrentRun
        session.currentSegmentStartedAt = engine.snapshot.startedAt
        session.activeTaskID = engine.snapshot.currentTaskID
        session.endedAt = nil
    }

    private func restoreOpenSessions() throws {
        let descriptor = FetchDescriptor<Session>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        let sessions = try context.fetch(descriptor)
        let open = sessions.filter { $0.endedAt == nil && ($0.phase == .running || $0.phase == .stopped) }
        var sawRunning = false
        for session in open {
            guard let spaceID = session.space?.id else { continue }
            var restoredPhase = session.phase
            if restoredPhase == .running {
                if sawRunning {
                    restoredPhase = .stopped
                    session.phase = .stopped
                    session.currentSegmentStartedAt = nil
                    for interval in session.intervals where interval.isOpen {
                        interval.endedAt = timeSource.now()
                    }
                } else {
                    sawRunning = true
                }
            }
            let engine = engine(for: spaceID)
            engine.restore(
                TimerSnapshot(
                    phase: restoredPhase,
                    spaceID: spaceID,
                    sessionID: session.id,
                    currentTaskID: session.activeTaskID,
                    startedAt: restoredPhase == .running ? session.currentSegmentStartedAt : nil,
                    accumulatedBeforeCurrentRun: session.accumulatedActiveDuration,
                    lastTick: timeSource.now(),
                    liveActivityID: nil
                )
            )
            publish(engine)
            if restoredPhase == .running {
                selectedSpaceID = spaceID
            }
        }
        if snapshots.values.contains(where: { $0.phase == .running || $0.phase == .stopped }) {
            liveActivity.startOrUpdate(from: self, at: timeSource.now())
        }
        try context.save()
    }

    private func applyLaunchOverrides() {
        guard launch.screenshotMode || launch.startRunning || launch.timerState != nil else { return }
        switch launch.timerState {
        case .idle:
            return
        case .stopped:
            if snapshot.phase == .idle {
                try? start()
            }
            applyFrozenElapsedIfNeeded()
            try? stop()
        case .running, .none:
            if snapshot.phase == .idle || snapshot.phase == .stopped {
                try? start()
            }
            applyFrozenElapsedIfNeeded()
        }
    }

    private func applyFrozenElapsedIfNeeded() {
        guard let frozen = launch.frozenElapsed, let spaceID = selectedSpaceID else { return }
        let engine = engine(for: spaceID)
        let now = timeSource.now()
        if engine.snapshot.phase == .running {
            engine.restore(
                TimerSnapshot(
                    phase: .running,
                    spaceID: spaceID,
                    sessionID: engine.snapshot.sessionID,
                    currentTaskID: engine.snapshot.currentTaskID,
                    startedAt: now.addingTimeInterval(-frozen),
                    accumulatedBeforeCurrentRun: 0,
                    lastTick: now,
                    liveActivityID: engine.snapshot.liveActivityID
                )
            )
        }
        if let session = session(id: engine.snapshot.sessionID) {
            session.accumulatedActiveDuration = engine.snapshot.phase == .running ? 0 : frozen
            session.currentSegmentStartedAt = engine.snapshot.startedAt
        }
        publish(engine)
    }

    private func engine(for spaceID: UUID) -> TimerEngine {
        if let existing = engines[spaceID] {
            return existing
        }
        let created = TimerEngine(spaceID: spaceID)
        engines[spaceID] = created
        snapshots[spaceID] = created.snapshot
        return created
    }

    private func publish(_ engine: TimerEngine) {
        snapshots[engine.snapshot.spaceID] = engine.snapshot
        noteChange()
    }

    private func noteChange() {
        mutation &+= 1
    }
}
