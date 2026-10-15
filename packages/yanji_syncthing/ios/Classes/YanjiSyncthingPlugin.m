#import "YanjiSyncthingPlugin.h"
#import <Engine/Engine.h>
@implementation YanjiSyncthingPlugin {
  dispatch_queue_t _worker;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"yanji/syncthing" binaryMessenger:[registrar messenger]];
  YanjiSyncthingPlugin *plugin = [[YanjiSyncthingPlugin alloc] init];
  plugin->_worker = dispatch_queue_create("yanji.syncthing", DISPATCH_QUEUE_SERIAL);
  [registrar addMethodCallDelegate:plugin channel:channel];
}
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if (![call.method isEqualToString:@"execute"] || ![call.arguments isKindOfClass:[NSString class]]) { result(FlutterMethodNotImplemented); return; }
  NSString *request = call.arguments;
  dispatch_async(_worker, ^{
    NSError *error = nil;
    NSString *response = EngineExecute(request, &error);
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) result([FlutterError errorWithCode:@"sync_engine" message:error.localizedDescription details:nil]);
      else result(response);
    });
  });
}
@end
