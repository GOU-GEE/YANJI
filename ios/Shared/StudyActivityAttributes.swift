import ActivityKit
import AppIntents
import Foundation

struct StudyActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var status: String
    var elapsedSeconds: Int
    var todayTotalSeconds: Int
    var referenceDate: Date
    // Optional so activities created by older app versions remain decodable.
    var statusUpdatedAt: Date?
    var targetSeconds: Int
    var doNotDisturbEnabled: Bool

    var effectiveStatusUpdatedAt: Date {
      statusUpdatedAt ?? referenceDate
    }

    func elapsed(at date: Date) -> Int {
      min(8 * 60 * 60, elapsedSeconds + (status == "active" ? max(0, Int(date.timeIntervalSince(referenceDate))) : 0))
    }

    func todayTotal(at date: Date) -> Int {
      todayTotalSeconds + max(0, elapsed(at: date) - elapsedSeconds)
    }
  }

  var sessionId: String
  var subject: String
}

struct StudyActivitySyncRequest: Sendable {
  var sessionId: String?
  var subject: String
  var status: String
  var elapsedSeconds: Int
  var todayTotalSeconds: Int
  var snapshotAt: Date
  var statusUpdatedAt: Date
  var targetSeconds: Int
  var doNotDisturbEnabled: Bool
}

@available(iOS 17.0, *)
struct PauseStudyTimerIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "暂停学习"
  static var openAppWhenRun: Bool = false

  func perform() async throws -> some IntentResult {
    await StudyTimerIntentCoordinator.shared.pause()
    return .result()
  }
}

@available(iOS 17.0, *)
struct ResumeStudyTimerIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "继续学习"
  static var openAppWhenRun: Bool = false

  func perform() async throws -> some IntentResult {
    await StudyTimerIntentCoordinator.shared.resume()
    return .result()
  }
}

@available(iOS 16.1, *)
actor StudyTimerIntentCoordinator {
  static let shared = StudyTimerIntentCoordinator()

  func pause() async {
    let now = Date()
    for activity in Activity<StudyActivityAttributes>.activities {
      var state = activity.contentState
      guard state.status == "active" else { continue }
      state.elapsedSeconds = state.elapsed(at: now)
      state.todayTotalSeconds = state.todayTotal(at: now)
      state.referenceDate = now
      state.status = "paused"
      state.statusUpdatedAt = now
      await activity.update(using: state)
    }
  }

  func resume() async {
    let now = Date()
    for activity in Activity<StudyActivityAttributes>.activities {
      var state = activity.contentState
      guard state.status == "paused" else { continue }
      state.referenceDate = now
      state.status = "active"
      state.statusUpdatedAt = now
      await activity.update(using: state)
    }
  }

  func sync(_ request: StudyActivitySyncRequest) async throws {
    guard let sessionId = request.sessionId, request.status != "finished" else {
      await finishActivities(
        at: request.snapshotAt,
        statusUpdatedAt: request.statusUpdatedAt
      )
      return
    }

    let now = Date()
    let ageSeconds = max(0, Int(now.timeIntervalSince(request.snapshotAt)))
    var incoming = StudyActivityAttributes.ContentState(
      status: request.status,
      elapsedSeconds: request.elapsedSeconds + (request.status == "active" ? ageSeconds : 0),
      todayTotalSeconds: request.todayTotalSeconds + (request.status == "active" ? ageSeconds : 0),
      referenceDate: now,
      statusUpdatedAt: request.statusUpdatedAt,
      targetSeconds: request.targetSeconds,
      doNotDisturbEnabled: request.doNotDisturbEnabled
    )

    if let activity = Activity<StudyActivityAttributes>.activities.first(where: {
      $0.attributes.sessionId == sessionId
    }) {
      let current = activity.contentState

      // A queued Flutter snapshot must not undo a more recent island action.
      guard request.snapshotAt >= current.referenceDate else { return }
      if request.statusUpdatedAt < current.effectiveStatusUpdatedAt {
        guard request.status == current.status else { return }
        incoming.elapsedSeconds = current.elapsed(at: now)
        incoming.todayTotalSeconds = current.todayTotal(at: now)
        incoming.statusUpdatedAt = current.effectiveStatusUpdatedAt
      } else {
        // Preserve monotonic time if a newer snapshot was computed from a
        // slightly older database read while an update was in flight.
        incoming.elapsedSeconds = max(incoming.elapsedSeconds, current.elapsed(at: now))
        incoming.todayTotalSeconds = max(incoming.todayTotalSeconds, current.todayTotal(at: now))
      }
      await activity.update(using: incoming)
    } else if ActivityAuthorizationInfo().areActivitiesEnabled {
      for oldActivity in Activity<StudyActivityAttributes>.activities {
        await oldActivity.end(dismissalPolicy: .immediate)
      }
      _ = try Activity.request(
        attributes: StudyActivityAttributes(sessionId: sessionId, subject: request.subject),
        contentState: incoming,
        pushType: nil
      )
    }
  }

  private func finishActivities(at date: Date, statusUpdatedAt: Date) async {
    for activity in Activity<StudyActivityAttributes>.activities {
      let current = activity.contentState
      // Ignore an old "finished" sync that was queued before a newer pause or
      // resume action.
      guard statusUpdatedAt >= current.effectiveStatusUpdatedAt else { continue }
      var finalState = current
      finalState.elapsedSeconds = finalState.elapsed(at: date)
      finalState.todayTotalSeconds = finalState.todayTotal(at: date)
      finalState.referenceDate = date
      finalState.status = "finished"
      finalState.statusUpdatedAt = statusUpdatedAt
      await activity.end(
        using: finalState,
        dismissalPolicy: .after(date.addingTimeInterval(60))
      )
    }
  }
}
