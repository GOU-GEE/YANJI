import ActivityKit
import Flutter
import Foundation

final class StudyLiveActivityBridge {
  static var pendingAction: String?
  private static let channelName = "com.example.yanji/study_live_activity"

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "StudyLiveActivityBridge") else { return }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "sync":
        guard let values = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_arguments", message: "Missing activity state", details: nil))
          return
        }
        sync(values, result: result)
      case "consumePendingAction":
        let action = pendingAction
        pendingAction = nil
        result(action)
      case "currentActivityState":
        currentActivityState(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func currentActivityState(result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    Task { @MainActor in
      guard let activity = Activity<StudyActivityAttributes>.activities.first else {
        result(nil)
        return
      }
      let capturedAt = Date()
      result([
        "status": activity.contentState.status,
        "elapsedSeconds": activity.contentState.elapsed(at: capturedAt),
        "capturedAtMs": Int(capturedAt.timeIntervalSince1970 * 1000),
      ])
    }
  }

  @discardableResult
  static func handle(url: URL) -> Bool {
    guard url.scheme == "yanji", url.host == "live-activity" else { return false }
    let action = url.pathComponents.dropFirst().first
    guard ["open", "pause", "resume", "finish", "dnd"].contains(action) else { return false }
    pendingAction = action
    return true
  }

  private static func sync(_ values: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    Task { @MainActor in
      do {
        let now = Date()
        let snapshotAt = date(
          fromMilliseconds: (values["snapshotAtMs"] as? NSNumber)?.intValue,
          fallback: now
        )
        let statusUpdatedAt = date(
          fromMilliseconds: (values["statusUpdatedAtMs"] as? NSNumber)?.intValue,
          fallback: snapshotAt
        )
        let request = StudyActivitySyncRequest(
          sessionId: values["sessionId"] as? String,
          subject: values["subject"] as? String ?? "自由学习",
          status: values["status"] as? String ?? "finished",
          elapsedSeconds: (values["elapsedSeconds"] as? NSNumber)?.intValue ?? 0,
          todayTotalSeconds: (values["todayTotalSeconds"] as? NSNumber)?.intValue ?? 0,
          snapshotAt: snapshotAt,
          statusUpdatedAt: statusUpdatedAt,
          targetSeconds: (values["targetSeconds"] as? NSNumber)?.intValue ?? 0,
          doNotDisturbEnabled: values["doNotDisturbEnabled"] as? Bool ?? false
        )
        try await StudyTimerIntentCoordinator.shared.sync(request)
        result(nil)
      } catch {
        result(FlutterError(code: "activity_error", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func date(fromMilliseconds milliseconds: Int?, fallback: Date) -> Date {
    guard let milliseconds else { return fallback }
    return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
  }
}
