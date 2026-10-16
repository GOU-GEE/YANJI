import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult,
  MethodCallHandler } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';
import { HuksSecretStore } from './HuksSecretStore';

export class YanjiPlatformPlugin implements FlutterPlugin, MethodCallHandler {
  private secrets: HuksSecretStore | null = null;
  private queue: Promise<void> = Promise.resolve();
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;

  getUniqueClassName(): string { return 'YanjiPlatformPlugin'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.secrets = new HuksSecretStore(this.context);
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'yanji/platform.v1');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.context = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    this.queue = this.queue.then(async () => {
      if (call.method === 'supportDirectory' && this.context !== null) {
        result.success(this.context.filesDir);
      } else if (call.method === 'secretRead' && this.secrets !== null) {
        result.success(await this.secrets.read(call.argument('key') as string));
      } else if (call.method === 'secretWrite' && this.secrets !== null) {
        await this.secrets.write(call.argument('key') as string, call.argument('value') as string);
        result.success(null);
      } else {
        result.notImplemented();
      }
    }).catch(() => {
      // Do not include credential contents or native exception details in logs.
      result.error('CREDENTIAL_UNAVAILABLE', '无法读取或保存设备安全身份，请保留应用数据后重试。', null);
    });
  }
}
