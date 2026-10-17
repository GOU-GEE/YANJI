import {
  AbilityAware, AbilityPluginBinding, FlutterPlugin, FlutterPluginBinding,
  MethodCall, MethodCallHandler, MethodChannel, MethodResult
} from '@ohos/flutter_ohos';
import { common, wantAgent, Want, WantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const NOTIFICATION_ID: number = 42017;
const NOTIFICATION_LABEL: string = 'yanji.study';
const MAX_SECONDS: number = 8 * 60 * 60;

interface StudySnapshot {
  sessionId: string;
  subject: string;
  status: string;
  elapsedSeconds: number;
  snapshotAtMs: number;
  statusUpdatedAtMs: number;
}

interface PublishedStudyNotification {
  id: number;
  title: string;
  text: string;
}

interface NotificationStatus {
  enabled: boolean;
  notifications: PublishedStudyNotification[];
  liveViewSyscap: boolean;
}

/** Local notification fallback. Study records and pause rules remain in Dart. */
export class StudyNotificationPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private state: StudySnapshot | null = null;
  private queue: Promise<void> = Promise.resolve();
  private revision: number = 0;
  private lastSnapshotAtMs: number = 0;
  private permissionRequested: boolean = false;
  private enabled: boolean = false;
  private foreground: boolean = true;
  private ticker: number = -1;
  private tickPending: boolean = false;
  private openTimer: boolean = false;
  private agent: WantAgent | null = null;

  getUniqueClassName(): string { return 'StudyNotificationPlugin'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'com.example.yanji/study_live_activity');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.clearTicker();
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.clearTicker();
    this.context = null;
    this.agent = null;
  }

  handleWant(want: Want): void {
    if (want.parameters?.['yanjiStudyOpen'] === true) this.openTimer = true;
  }

  setForeground(value: boolean): void {
    this.foreground = value;
    this.clearTicker();
    const revision = this.revision;
    this.enqueue(async () => {
      if (this.state !== null && revision === this.revision) {
        this.enabled = await notificationManager.isNotificationEnabled();
        await this.publish();
        this.restartTicker();
      }
    });
  }

  destroy(): void {
    this.clearTicker();
    this.state = null;
    this.revision++;
    this.enqueue(async () => { await this.cancel(); });
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'consumePendingAction') {
      result.success(this.openTimer ? 'open' : null);
      this.openTimer = false;
      return;
    }
    if (call.method === 'currentActivityState') {
      // Native notification rendering never changes the authoritative clock.
      result.success(null);
      return;
    }
    if (call.method === 'notificationStatus') {
      this.status().then((value: NotificationStatus) => result.success(value))
        .catch((error: BusinessError) => result.error('NOTIFICATION_UNAVAILABLE',
          '无法读取系统通知状态', error.code));
      return;
    }
    if (call.method !== 'sync') {
      result.notImplemented();
      return;
    }
    const snapshotAt = call.argument('snapshotAtMs') as number;
    if (!Number.isFinite(snapshotAt) || snapshotAt < 0) {
      result.error('INVALID_STUDY_SNAPSHOT', '计时通知数据无效', null);
      return;
    }
    if (snapshotAt < this.lastSnapshotAtMs) {
      result.success(null);
      return;
    }
    const sessionId = call.argument('sessionId') as string | null;
    const status = call.argument('status') as string;
    if (sessionId === null || status === 'finished') {
      this.state = null;
    } else {
      const elapsed = call.argument('elapsedSeconds') as number;
      const updatedAt = call.argument('statusUpdatedAtMs') as number;
      if ((status !== 'active' && status !== 'paused') || !Number.isFinite(elapsed) ||
        elapsed < 0 || !Number.isFinite(updatedAt)) {
        result.error('INVALID_STUDY_SNAPSHOT', '计时通知数据无效', null);
        return;
      }
      this.state = {
        sessionId: sessionId,
        subject: (call.argument('subject') as string).slice(0, 80),
        status: status,
        elapsedSeconds: Math.min(MAX_SECONDS, Math.floor(elapsed)),
        snapshotAtMs: snapshotAt,
        statusUpdatedAtMs: updatedAt
      };
    }
    this.lastSnapshotAtMs = snapshotAt;
    const revision = ++this.revision;
    this.clearTicker();
    this.queue = this.queue.then(async () => {
      if (revision !== this.revision) { result.success(null); return; }
      if (this.state === null) {
        await this.cancel();
      } else {
        if (!await notificationManager.isNotificationEnabled() && !this.permissionRequested &&
          this.foreground && this.context !== null) {
          this.permissionRequested = true;
          await notificationManager.requestEnableNotification(this.context);
        }
        // A stop/pause can arrive while the authorization dialog is open.
        if (revision !== this.revision) { result.success(null); return; }
        this.enabled = await notificationManager.isNotificationEnabled();
        if (!this.enabled) {
          result.error('NOTIFICATION_DISABLED', '请在系统设置中允许研迹发送通知', null);
          return;
        }
        await notificationManager.addSlot(notificationManager.SlotType.CONTENT_INFORMATION);
        await this.publish();
        this.restartTicker();
      }
      result.success(null);
    }).catch((error: BusinessError) => {
      this.clearTicker();
      this.logFailure(error);
      result.error('NOTIFICATION_UNAVAILABLE', '计时已继续，但系统通知暂不可用', error.code);
    });
  }

  private enqueue(operation: () => Promise<void>): void {
    this.queue = this.queue.then(operation).catch((error: BusinessError) => this.logFailure(error));
  }

  private clearTicker(): void {
    if (this.ticker !== -1) clearInterval(this.ticker);
    this.ticker = -1;
  }

  private restartTicker(): void {
    this.clearTicker();
    if (!this.enabled || !this.foreground || this.state?.status !== 'active') return;
    this.ticker = setInterval(() => {
      if (this.tickPending) return;
      this.tickPending = true;
      const revision = this.revision;
      this.enqueue(async () => {
        try {
          if (revision === this.revision && this.foreground && this.state !== null) await this.publish();
        } finally { this.tickPending = false; }
      });
    }, 1000);
  }

  private async publish(): Promise<void> {
    const state = this.state;
    if (!this.enabled || state === null || this.context === null) return;
    if (this.agent === null) {
      this.agent = await wantAgent.getWantAgent({
        wants: [{ bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name, parameters: { yanjiStudyOpen: true } }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: NOTIFICATION_ID,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      });
    }
    const active = state.status === 'active';
    const elapsed = Math.min(MAX_SECONDS, state.elapsedSeconds +
      (active ? Math.max(0, Math.floor((Date.now() - state.snapshotAtMs) / 1000)) : 0));
    // Basic notifications do not implement a system stopwatch. In the
    // background show a stable time anchor, never a misleading frozen counter.
    const text = !active ? `已暂停 · 累计 ${this.duration(elapsed)} · 点击返回计时` :
      this.foreground ? `已学习 ${this.duration(elapsed)} · 截至 ${this.clock(Date.now())}` :
        `本段开始于 ${this.clock(state.statusUpdatedAtMs)} · 点击查看实时计时`;
    await notificationManager.publish({
      id: NOTIFICATION_ID,
      label: NOTIFICATION_LABEL,
      notificationSlotType: notificationManager.SlotType.CONTENT_INFORMATION,
      tapDismissed: false,
      isAlertOnce: true,
      autoDeletedTime: active ? state.snapshotAtMs +
        Math.max(1, MAX_SECONDS - state.elapsedSeconds) * 1000 : Date.now() + MAX_SECONDS * 1000,
      wantAgent: this.agent,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: { title: `${state.subject || '自由学习'} · ${active ? '学习计时中' : '学习已暂停'}`, text: text }
      }
    });
  }

  private async cancel(): Promise<void> {
    try { await notificationManager.cancel(NOTIFICATION_ID, NOTIFICATION_LABEL); }
    catch (error) { if ((error as BusinessError).code !== 1600007) throw (error as Error); }
  }

  private async status(): Promise<NotificationStatus> {
    const active = await notificationManager.getActiveNotifications();
    return {
      enabled: await notificationManager.isNotificationEnabled(),
      notifications: active.filter((item: notificationManager.NotificationRequest) =>
        item.id === NOTIFICATION_ID && item.label === NOTIFICATION_LABEL)
        .map((item: notificationManager.NotificationRequest): PublishedStudyNotification => ({
          id: item.id ?? NOTIFICATION_ID, title: item.content.normal?.title ?? '',
          text: item.content.normal?.text ?? ''
        })),
      // SysCap availability is not evidence of TIMER scene entitlement.
      liveViewSyscap: canIUse('SystemCapability.LiveView.LiveViewService')
    };
  }

  private duration(seconds: number): string {
    return [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60]
      .map((value: number) => value.toString().padStart(2, '0')).join(':');
  }

  private clock(milliseconds: number): string {
    const date = new Date(milliseconds);
    return [date.getHours(), date.getMinutes(), date.getSeconds()]
      .map((value: number) => value.toString().padStart(2, '0')).join(':');
  }

  private logFailure(error: BusinessError): void {
    if ([1600004, 1600005, 1600020].includes(error.code)) {
      this.enabled = false;
      this.clearTicker();
    }
    hilog.warn(0x0001, 'YanjiStudyNotification', 'Notification operation failed, code=%{public}d', error.code ?? -1);
  }
}
