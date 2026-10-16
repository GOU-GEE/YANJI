import ActivityKit
import Combine
import SwiftUI
import WidgetKit

private let studyGreen = Color(red: 0.31, green: 0.76, blue: 0.55)

struct StudyLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: StudyActivityAttributes.self) { context in
      lockScreen(context)
      .activityBackgroundTint(Color.black.opacity(0.92))
      .activitySystemActionForegroundColor(.white)
      .widgetURL(URL(string: "yanji://live-activity/open"))
    } dynamicIsland: { context in
      let presentation = StudyActivityPresentationState(context.state)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          EmptyView()
        }
        DynamicIslandExpandedRegion(.trailing) {
          EmptyView()
        }
        DynamicIslandExpandedRegion(.bottom) {
          expandedIsland(context, presentation: presentation)
        }
        .contentMargins(.all, 20)
      } compactLeading: {
        StudyActivityCompactStatus(
          authoritativeState: context.state,
          presentation: presentation
        )
          .font(.caption2.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .frame(width: 44, alignment: .center)
      } compactTrailing: {
        StudyActivityCompactTimer(
          authoritativeState: context.state,
          presentation: presentation
        )
        .font(.caption2.monospacedDigit().bold())
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: 44, alignment: .trailing)
      } minimal: {
        StudyActivityCompactTimer(
          authoritativeState: context.state,
          presentation: presentation
        )
        .font(.caption2.monospacedDigit().bold())
      }
      .widgetURL(URL(string: "yanji://live-activity/open"))
      .keylineTint(studyGreen)
    }
  }

  private func lockScreen(
    _ context: ActivityViewContext<StudyActivityAttributes>
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 3) {
          Text(context.attributes.subject).font(.headline).lineLimit(1)
          statusLabel(context.state.status)
        }
        Spacer()
        liveDuration(
          state: context.state,
          baseSeconds: context.state.elapsedSeconds
        )
        .font(.title.monospacedDigit().bold())
        .foregroundStyle(studyGreen)
      }
      HStack {
        Text("今日累计").foregroundStyle(.secondary)
        Spacer()
        liveDuration(
          state: context.state,
          baseSeconds: context.state.todayTotalSeconds
        )
        .monospacedDigit()
      }
      .font(.subheadline)
      if context.state.targetSeconds > 0 {
        ProgressView(
          value: min(Double(context.state.todayTotalSeconds), Double(context.state.targetSeconds)),
          total: Double(context.state.targetSeconds)
        )
        .tint(studyGreen)
      }
      activityFooter(context)
    }
    .padding(16)
  }

  @ViewBuilder
  private func activityFooter(_ context: ActivityViewContext<StudyActivityAttributes>) -> some View {
    if context.state.status == "finished" {
      HStack {
        Label("本次学习完成", systemImage: "checkmark.circle.fill")
          .foregroundStyle(studyGreen)
        Spacer()
      }
      .font(.subheadline.weight(.semibold))
    } else {
      expandedActions(context)
    }
  }

  @ViewBuilder
  private func expandedIsland(
    _ context: ActivityViewContext<StudyActivityAttributes>,
    presentation: StudyActivityPresentationState
  ) -> some View {
    if context.state.status == "finished" {
      HStack {
        Label("本次学习完成", systemImage: "checkmark.circle.fill")
          .foregroundStyle(studyGreen)
        Spacer()
      }
      .font(.subheadline.weight(.semibold))
    } else if #available(iOSApplicationExtension 17.0, *) {
      if context.state.status == "paused" {
        Toggle(isOn: true, intent: ResumeStudyTimerIntent()) {
          StudyActivityExpandedHeader(
            authoritativeState: context.state,
            subject: context.attributes.subject,
            presentation: presentation
          )
        }
        .toggleStyle(
          StudyPauseToggleStyle(
            presentation: presentation,
            finishURL: actionURL("finish")
          )
        )
      } else {
        Toggle(isOn: false, intent: PauseStudyTimerIntent()) {
          StudyActivityExpandedHeader(
            authoritativeState: context.state,
            subject: context.attributes.subject,
            presentation: presentation
          )
        }
        .toggleStyle(
          StudyPauseToggleStyle(
            presentation: presentation,
            finishURL: actionURL("finish")
          )
        )
      }
    } else {
      VStack(spacing: 10) {
        StudyActivityExpandedHeader(
          authoritativeState: context.state,
          subject: context.attributes.subject,
          presentation: presentation
        )
        expandedActions(context)
      }
    }
  }

  private func expandedActions(_ context: ActivityViewContext<StudyActivityAttributes>) -> some View {
    HStack(spacing: 10) {
      Link(destination: actionURL("finish")) {
        Label("结束", systemImage: "stop.fill").frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered).tint(.white)

      if #available(iOSApplicationExtension 17.0, *) {
        if context.state.status == "paused" {
          Button(intent: ResumeStudyTimerIntent()) {
            Label("继续", systemImage: "play.fill").frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent).tint(studyGreen)
        } else {
          Button(intent: PauseStudyTimerIntent()) {
            Label("暂停", systemImage: "pause.fill").frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent).tint(studyGreen)
        }
      } else {
        Link(destination: actionURL(context.state.status == "paused" ? "resume" : "pause")) {
          Label(context.state.status == "paused" ? "继续" : "暂停",
                systemImage: context.state.status == "paused" ? "play.fill" : "pause.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent).tint(studyGreen)
      }
    }
  }

  private func actionURL(_ action: String) -> URL {
    URL(string: "yanji://live-activity/\(action)")!
  }

  private func statusLabel(_ status: String) -> some View {
    Text(status == "paused" ? "已暂停" : status == "finished" ? "✓ 学习完成" : "学习中")
      .font(.caption)
      .foregroundStyle(status == "active" ? studyGreen : .secondary)
  }

  @ViewBuilder
  private func liveDuration(
    state: StudyActivityAttributes.ContentState,
    baseSeconds: Int
  ) -> some View {
    if state.status == "active" {
      // SwiftUI owns this dynamic date text and keeps it moving while the app
      // is suspended. A TimelineView inside a Live Activity can stay cached
      // until the next ActivityKit state push (for example, when pausing).
      let startDate = state.referenceDate.addingTimeInterval(-Double(max(0, baseSeconds)))
      let endDate = state.referenceDate.addingTimeInterval(Double(max(0, 8 * 60 * 60 - state.elapsedSeconds)))
      Text(timerInterval: startDate...endDate, countsDown: false, showsHours: true)
    } else {
      Text(duration(baseSeconds))
    }
  }

  private func duration(_ seconds: Int) -> String {
    let safeSeconds = max(0, seconds)
    if safeSeconds < 60 { return "\(safeSeconds)秒钟" }
    return "\(safeSeconds / 60)分钟"
  }
}

@MainActor
private final class StudyActivityPresentationState: ObservableObject {
  @Published private(set) var contentState: StudyActivityAttributes.ContentState
  @Published private(set) var isActionPending = false

  init(_ contentState: StudyActivityAttributes.ContentState) {
    self.contentState = contentState
  }

  func setOptimisticPaused(_ paused: Bool) {
    guard !isActionPending else { return }

    var nextState = contentState
    let now = Date()
    if paused {
      nextState.elapsedSeconds = nextState.elapsed(at: now)
      nextState.todayTotalSeconds = nextState.todayTotal(at: now)
    }
    nextState.referenceDate = now
    nextState.status = paused ? "paused" : "active"
    contentState = nextState
    isActionPending = true
  }

  func reconcile(with authoritativeState: StudyActivityAttributes.ContentState) {
    guard contentState != authoritativeState || isActionPending else { return }
    contentState = authoritativeState
    isActionPending = false
  }
}

private struct StudyActivityExpandedHeader: View {
  let authoritativeState: StudyActivityAttributes.ContentState
  let subject: String
  @ObservedObject var presentation: StudyActivityPresentationState
  @ScaledMetric(relativeTo: .subheadline) private var timerWidth: CGFloat = 52

  var body: some View {
    let state = presentation.contentState
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      HStack(spacing: 6) {
        Text("内容")
          .foregroundStyle(.secondary)
        Text(subject)
          .fontWeight(.semibold)
      }
      Spacer(minLength: 8)
      HStack(spacing: 6) {
        Text(state.status == "paused" ? "已暂停" : state.status == "finished" ? "学习完成" : "学习中")
          .foregroundStyle(.secondary)
        liveActivityTimer(state: state, baseSeconds: state.elapsedSeconds)
          .monospacedDigit()
          // Dynamic date text expands to the proposed width, unlike the
          // static paused text. Give both the same cell and text alignment.
          .frame(width: timerWidth, alignment: .trailing)
          .multilineTextAlignment(.trailing)
      }
      .fixedSize(horizontal: true, vertical: false)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .font(.subheadline)
    .lineLimit(1)
    .minimumScaleFactor(0.75)
    .padding(.top, 24)
    .onChange(of: authoritativeState) { newState in
      presentation.reconcile(with: newState)
    }
  }
}

private struct StudyActivityCompactStatus: View {
  let authoritativeState: StudyActivityAttributes.ContentState
  @ObservedObject var presentation: StudyActivityPresentationState

  var body: some View {
    let state = presentation.contentState
    Text(state.status == "paused" ? "已暂停" : state.status == "finished" ? "已完成" : "学习中")
      .foregroundStyle(state.status == "active" ? studyGreen : .secondary)
      .onChange(of: authoritativeState) { newState in
        presentation.reconcile(with: newState)
      }
  }
}

private struct StudyActivityCompactTimer: View {
  let authoritativeState: StudyActivityAttributes.ContentState
  @ObservedObject var presentation: StudyActivityPresentationState

  var body: some View {
    let state = presentation.contentState
    liveActivityTimer(state: state, baseSeconds: state.elapsedSeconds)
      .foregroundStyle(state.status == "paused" ? .secondary : studyGreen)
      .onChange(of: authoritativeState) { newState in
        presentation.reconcile(with: newState)
      }
  }
}

@available(iOSApplicationExtension 17.0, *)
private struct StudyPauseToggleStyle: ToggleStyle {
  let presentation: StudyActivityPresentationState
  let finishURL: URL

  func makeBody(configuration: Configuration) -> some View {
    VStack(spacing: 10) {
      configuration.label
      HStack(spacing: 10) {
        Link(destination: finishURL) {
          Label("结束", systemImage: "stop.fill").frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.white)

        Button {
          guard !presentation.isActionPending else { return }
          let shouldPause = !configuration.isOn
          presentation.setOptimisticPaused(shouldPause)
          configuration.isOn = shouldPause
        } label: {
          Label(
            configuration.isOn ? "继续" : "暂停",
            systemImage: configuration.isOn ? "play.fill" : "pause.fill"
          )
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(studyGreen)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

@ViewBuilder
private func liveActivityTimer(
  state: StudyActivityAttributes.ContentState,
  baseSeconds: Int
) -> some View {
  if state.status == "active" {
    let startDate = state.referenceDate.addingTimeInterval(
      -Double(max(0, baseSeconds))
    )
    let endDate = state.referenceDate.addingTimeInterval(Double(max(0, 8 * 60 * 60 - state.elapsedSeconds)))
    Text(timerInterval: startDate...endDate, countsDown: false, showsHours: true)
      .contentTransition(.identity)
      .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
      }
  } else {
    Text(timerDuration(baseSeconds))
      .contentTransition(.identity)
      .transaction { transaction in
        transaction.animation = nil
        transaction.disablesAnimations = true
      }
  }
}

private func timerDuration(_ seconds: Int) -> String {
  let safeSeconds = max(0, seconds)
  if safeSeconds >= 3600 {
    return String(format: "%02d:%02d", safeSeconds / 3600, (safeSeconds / 60) % 60)
  }
  return String(format: "%02d:%02d", safeSeconds / 60, safeSeconds % 60)
}
