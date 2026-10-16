
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { YanjiPlatformPlugin } from '../platform/YanjiPlatformPlugin';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    const registry = flutterEngine.getPlugins()
    if (registry === null) throw new Error('Flutter plugin registry is unavailable')
    registry.add(new YanjiPlatformPlugin())
  }
}
