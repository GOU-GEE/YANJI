
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import BonsoirPlugin from '../platform/BonsoirPlugin';
import { YanjiPlatformPlugin } from '../platform/YanjiPlatformPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { StudyNotificationPlugin } from '../platform/StudyNotificationPlugin';
import { Want, AbilityConstant } from '@kit.AbilityKit';

export default class EntryAbility extends FlutterAbility {
  private studyNotifications: StudyNotificationPlugin = new StudyNotificationPlugin();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);
    this.studyNotifications.handleWant(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onNewWant(want, launchParam);
    this.studyNotifications.handleWant(want);
  }

  onForeground(): void {
    super.onForeground();
    this.studyNotifications.setForeground(true);
  }

  onBackground(): void {
    this.studyNotifications.setForeground(false);
    super.onBackground();
  }

  onDestroy(): void {
    this.studyNotifications.destroy();
    super.onDestroy();
  }

  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    const registry = flutterEngine.getPlugins()
    if (registry === null) throw new Error('Flutter plugin registry is unavailable')
    registry.add(new YanjiPlatformPlugin())
    registry.add(new BonsoirPlugin())
    registry.add(this.studyNotifications)
  }
}
