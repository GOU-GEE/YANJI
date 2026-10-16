import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult,
  MethodCallHandler } from '@ohos/flutter_ohos';
import common from '@ohos.app.ability.common';

export class YanjiPlatformPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.Context | null = null;

  getUniqueClassName(): string { return 'YanjiPlatformPlugin'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.context = binding.getApplicationContext();
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'yanji/platform.v1');
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.context = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === 'supportDirectory' && this.context !== null) {
      result.success(this.context.filesDir);
    } else {
      result.notImplemented();
    }
  }
}
