/*
 * Copyright (c) 2026 bonsoir contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import {
  AbilityAware,
  AbilityPluginBinding,
  Any,
  BinaryMessenger,
  EventChannel,
  EventSink,
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StreamHandler,
} from '@ohos/flutter_ohos';
import { mdns } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';

const TAG: string = 'BonsoirPlugin';
const CHANNEL_NAME: string = 'fr.skyost.bonsoir';

/** 事件 id，与 Dart 侧 BonsoirBroadcastEvent / BonsoirDiscoveryEvent 的常量一致。 */
const EVENT_BROADCAST_STARTED: string = 'broadcastStarted';
const EVENT_BROADCAST_NAME_ALREADY_EXISTS: string = 'broadcastNameAlreadyExists';
const EVENT_BROADCAST_STOPPED: string = 'broadcastStopped';
const EVENT_DISCOVERY_STARTED: string = 'discoveryStarted';
const EVENT_DISCOVERY_SERVICE_FOUND: string = 'discoveryServiceFound';
const EVENT_DISCOVERY_SERVICE_RESOLVED: string = 'discoveryServiceResolved';
const EVENT_DISCOVERY_SERVICE_LOST: string = 'discoveryServiceLost';
const EVENT_DISCOVERY_SERVICE_RESOLVE_FAILED: string = 'discoveryServiceResolveFailed';
const EVENT_DISCOVERY_STOPPED: string = 'discoveryStopped';

/** mDNS 服务未指定端口时按 0 上报。 */
const DEFAULT_PORT: number = 0;

/** 某个 id 的广播实例状态。 */
class BroadcastInstance {
  id: number;
  info: mdns.LocalServiceInfo;
  eventChannel: EventChannel | null = null;
  sink: EventSink | null = null;
  started: boolean = false;

  constructor(id: number, info: mdns.LocalServiceInfo) {
    this.id = id;
    this.info = info;
  }
}

/** 某个 id 的发现实例状态。 */
class DiscoveryInstance {
  id: number;
  type: string;
  service: mdns.DiscoveryService | null = null;
  eventChannel: EventChannel | null = null;
  sink: EventSink | null = null;
  /** 记录已发现的服务，解析与丢失事件需要带原始 LocalServiceInfo。 */
  found: Map<string, mdns.LocalServiceInfo> = new Map<string, mdns.LocalServiceInfo>();

  constructor(id: number, type: string) {
    this.id = id;
    this.type = type;
  }
}

/** 把实例的 EventSink 挂上 / 摘掉。 */
class InstanceStreamHandler implements StreamHandler {
  private readonly listen: (events: EventSink) => void;
  private readonly cancel: () => void;

  constructor(listen: (events: EventSink) => void, cancel: () => void) {
    this.listen = listen;
    this.cancel = cancel;
  }

  onListen(args: Object | null, events: EventSink): void {
    this.listen(events);
  }

  onCancel(args: Object | null): void {
    this.cancel();
  }
}

/**
 * bonsoir 的 OpenHarmony 实现。
 *
 * Android/iOS 用 NSD / Bonjour 做「广播自己的服务 + 发现局域网服务」，OHOS 对应
 * `@ohos.net.mdns`：
 * - 广播：`addLocalService` / `removeLocalService`
 * - 发现：`createDiscoveryService` + `serviceFound` / `serviceLost`
 * - 解析：`resolveLocalService`
 *
 * 通道结构与上游一致：一个 MethodChannel（`fr.skyost.bonsoir`）负责 start/stop，
 * 每个实例再挂一个 EventChannel（`fr.skyost.bonsoir.<类型>.<id>`）推事件。
 */
export default class BonsoirPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private messenger: BinaryMessenger | null = null;
  private context: common.UIAbilityContext | null = null;
  private readonly broadcasts: Map<number, BroadcastInstance> = new Map<number, BroadcastInstance>();
  private readonly discoveries: Map<number, DiscoveryInstance> = new Map<number, DiscoveryInstance>();

  getUniqueClassName(): string {
    return 'BonsoirPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.messenger = binding.getBinaryMessenger();
    this.channel = new MethodChannel(this.messenger, CHANNEL_NAME);
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.broadcasts.forEach((instance: BroadcastInstance) => {
      this.stopBroadcast(instance, false);
    });
    this.discoveries.forEach((instance: DiscoveryInstance) => {
      this.stopDiscovery(instance, false);
    });
    this.broadcasts.clear();
    this.discoveries.clear();
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.messenger = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context as common.UIAbilityContext;
  }

  onDetachedFromAbility(): void {
    this.context = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    try {
      switch (call.method) {
        case 'broadcast.initialize':
          this.initializeBroadcast(call);
          result.success(null);
          break;
        case 'broadcast.start':
          this.handleBroadcastStart(call, result);
          break;
        case 'broadcast.stop':
          this.handleBroadcastStop(call, result);
          break;
        case 'discovery.initialize':
          this.initializeDiscovery(call);
          result.success(null);
          break;
        case 'discovery.start':
          this.handleDiscoveryStart(call, result);
          break;
        case 'discovery.stop':
          this.handleDiscoveryStop(call, result);
          break;
        case 'discovery.resolveService':
          this.handleResolveService(call, result);
          break;
        case 'discovery.supportsMdnsHostname':
          // OHOS 解析结果里的 host 是 IP 地址，不提供 mDNS 主机名
          result.success(false);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `${call.method} failed: ${err.message}`);
      result.error('bonsoir_error', err.message, null);
    }
  }

  // ---------------------------------------------------------------- broadcast

  private initializeBroadcast(call: MethodCall): void {
    const id: number = (call.argument('id') as number) ?? 0;
    if (this.broadcasts.has(id)) {
      return;
    }
    const instance = new BroadcastInstance(id, BonsoirPlugin.buildServiceInfo(call));
    this.broadcasts.set(id, instance);
    const channel = new EventChannel(this.messenger as BinaryMessenger, `fr.skyost.bonsoir.broadcast.${id}`);
    channel.setStreamHandler(new InstanceStreamHandler(
      (events: EventSink): void => {
        instance.sink = events;
      },
      (): void => {
        instance.sink = null;
      }));
    instance.eventChannel = channel;
    Log.i(TAG, `broadcast.initialize id=${id} type=${instance.info.serviceType}`);
  }

  private handleBroadcastStart(call: MethodCall, result: MethodResult): void {
    const id: number = (call.argument('id') as number) ?? 0;
    const instance: BroadcastInstance | undefined = this.broadcasts.get(id);
    const context = this.context;
    if (instance === undefined || context === null) {
      result.error('bonsoir_error', `broadcast ${id} is not initialized or context is missing`, null);
      return;
    }
    mdns.addLocalService(context, instance.info)
      .then((info: mdns.LocalServiceInfo) => {
        instance.started = true;
        instance.info = info;
        this.emitBroadcast(instance, EVENT_BROADCAST_STARTED);
        result.success(null);
      })
      .catch((error: BusinessError) => {
        // 名称冲突等原因会导致注册失败，映射成上游的 broadcastNameAlreadyExists
        Log.e(TAG, `addLocalService failed code=${error.code} message=${error.message}`);
        this.emitBroadcast(instance, EVENT_BROADCAST_NAME_ALREADY_EXISTS);
        result.success(null);
      });
  }

  private handleBroadcastStop(call: MethodCall, result: MethodResult): void {
    const id: number = (call.argument('id') as number) ?? 0;
    const instance: BroadcastInstance | undefined = this.broadcasts.get(id);
    if (instance !== undefined) {
      this.stopBroadcast(instance, true);
    }
    result.success(null);
  }

  private stopBroadcast(instance: BroadcastInstance, emit: boolean): void {
    const context = this.context;
    if (context === null || !instance.started) {
      instance.started = false;
      if (emit) {
        this.emitBroadcast(instance, EVENT_BROADCAST_STOPPED);
      }
      return;
    }
    mdns.removeLocalService(context, instance.info)
      .then(() => {
        instance.started = false;
        if (emit) {
          this.emitBroadcast(instance, EVENT_BROADCAST_STOPPED);
        }
      })
      .catch((error: BusinessError) => {
        instance.started = false;
        Log.e(TAG, `removeLocalService failed code=${error.code} message=${error.message}`);
        if (emit) {
          this.emitBroadcast(instance, EVENT_BROADCAST_STOPPED);
        }
      });
  }

  private emitBroadcast(instance: BroadcastInstance, eventId: string): void {
    const sink = instance.sink;
    if (sink === null) {
      Log.i(TAG, `no broadcast listener for id=${instance.id}, drop ${eventId}`);
      return;
    }
    const event = new Map<string, Object>();
    event.set('id', eventId);
    event.set('service', BonsoirPlugin.toServiceMap(instance.info));
    sink.success(event);
  }

  // ---------------------------------------------------------------- discovery

  private initializeDiscovery(call: MethodCall): void {
    const id: number = (call.argument('id') as number) ?? 0;
    if (this.discoveries.has(id)) {
      return;
    }
    const type: string = (call.argument('type') as string) ?? '';
    const instance = new DiscoveryInstance(id, type);
    this.discoveries.set(id, instance);
    const channel = new EventChannel(this.messenger as BinaryMessenger, `fr.skyost.bonsoir.discovery.${id}`);
    channel.setStreamHandler(new InstanceStreamHandler(
      (events: EventSink): void => {
        instance.sink = events;
      },
      (): void => {
        instance.sink = null;
      }));
    instance.eventChannel = channel;
    Log.i(TAG, `discovery.initialize id=${id} type=${type}`);
  }

  private handleDiscoveryStart(call: MethodCall, result: MethodResult): void {
    const id: number = (call.argument('id') as number) ?? 0;
    const instance: DiscoveryInstance | undefined = this.discoveries.get(id);
    const context = this.context;
    if (instance === undefined || context === null) {
      result.error('bonsoir_error', `discovery ${id} is not initialized or context is missing`, null);
      return;
    }
    try {
      const service: mdns.DiscoveryService = mdns.createDiscoveryService(context, instance.type);
      service.on('serviceFound', (info: mdns.LocalServiceInfo): void => {
        instance.found.set(BonsoirPlugin.serviceKey(info), info);
        this.emitDiscoveryService(instance, EVENT_DISCOVERY_SERVICE_FOUND, info);
      });
      service.on('serviceLost', (info: mdns.LocalServiceInfo): void => {
        instance.found.delete(BonsoirPlugin.serviceKey(info));
        this.emitDiscoveryService(instance, EVENT_DISCOVERY_SERVICE_LOST, info);
      });
      instance.service = service;
      service.startSearchingMDNS();
      this.emitDiscoverySimple(instance, EVENT_DISCOVERY_STARTED);
      result.success(null);
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `createDiscoveryService failed code=${err.code} message=${err.message}`);
      result.error('bonsoir_error', err.message, null);
    }
  }

  private handleDiscoveryStop(call: MethodCall, result: MethodResult): void {
    const id: number = (call.argument('id') as number) ?? 0;
    const instance: DiscoveryInstance | undefined = this.discoveries.get(id);
    if (instance !== undefined) {
      this.stopDiscovery(instance, true);
    }
    result.success(null);
  }

  private stopDiscovery(instance: DiscoveryInstance, emit: boolean): void {
    const service = instance.service;
    if (service !== null) {
      try {
        service.stopSearchingMDNS();
        service.off('serviceFound');
        service.off('serviceLost');
      } catch (error) {
        const err = error as BusinessError;
        Log.e(TAG, `stopSearchingMDNS failed: ${err.message}`);
      }
      instance.service = null;
    }
    instance.found.clear();
    if (emit) {
      this.emitDiscoverySimple(instance, EVENT_DISCOVERY_STOPPED);
    }
  }

  private handleResolveService(call: MethodCall, result: MethodResult): void {
    const id: number = (call.argument('id') as number) ?? 0;
    const instance: DiscoveryInstance | undefined = this.discoveries.get(id);
    const context = this.context;
    if (instance === undefined || context === null) {
      result.error('bonsoir_error', 'discovery is not running', null);
      return;
    }
    const key: string = BonsoirPlugin.callServiceKey(call);
    const info: mdns.LocalServiceInfo | undefined = instance.found.get(key);
    if (info === undefined) {
      this.emitDiscoverySimple(instance, EVENT_DISCOVERY_SERVICE_RESOLVE_FAILED);
      result.success(null);
      return;
    }
    mdns.resolveLocalService(context, info)
      .then((resolved: mdns.LocalServiceInfo) => {
        instance.found.set(key, resolved);
        this.emitDiscoveryService(instance, EVENT_DISCOVERY_SERVICE_RESOLVED, resolved);
        result.success(null);
      })
      .catch((error: BusinessError) => {
        Log.e(TAG, `resolveLocalService failed code=${error.code} message=${error.message}`);
        this.emitDiscoverySimple(instance, EVENT_DISCOVERY_SERVICE_RESOLVE_FAILED);
        result.success(null);
      });
  }

  private emitDiscoverySimple(instance: DiscoveryInstance, eventId: string): void {
    const sink = instance.sink;
    if (sink === null) {
      return;
    }
    const event = new Map<string, Object>();
    event.set('id', eventId);
    sink.success(event);
  }

  private emitDiscoveryService(instance: DiscoveryInstance, eventId: string, info: mdns.LocalServiceInfo): void {
    const sink = instance.sink;
    if (sink === null) {
      return;
    }
    const event = new Map<string, Object>();
    event.set('id', eventId);
    event.set('service', BonsoirPlugin.toServiceMap(info));
    sink.success(event);
  }

  // ------------------------------------------------------------------ 转换层

  /** MethodCall → LocalServiceInfo（广播用，Dart 侧带的键都有 service. 前缀）。 */
  private static buildServiceInfo(call: MethodCall): mdns.LocalServiceInfo {
    const info: mdns.LocalServiceInfo = {
      serviceName: (call.argument('service.name') as string) ?? '',
      serviceType: (call.argument('service.type') as string) ?? '',
      port: (call.argument('service.port') as number) ?? DEFAULT_PORT,
      serviceAttribute: BonsoirPlugin.toServiceAttributes(call.argument('service.attributes')),
    };
    return info;
  }

  /** LocalServiceInfo → Dart 侧 service.toJson() 的结构（键同样带 service. 前缀）。 */
  private static toServiceMap(info: mdns.LocalServiceInfo): Map<string, Object> {
    const map = new Map<string, Object>();
    map.set('service.name', info.serviceName);
    map.set('service.type', info.serviceType);
    map.set('service.port', info.port ?? DEFAULT_PORT);
    map.set('service.attributes', BonsoirPlugin.fromServiceAttributes(info.serviceAttribute));
    const host = info.host;
    if (host !== undefined && host.address.length > 0) {
      map.set('service.hostAddresses', [host.address]);
    }
    return map;
  }

  /**
   * Dart 侧 Map<String,String> → OHOS Array<ServiceAttribute>。
   *
   * OHOS 的 TXT 记录值是字节数组，bonsoir 用字符串，这里统一按 UTF-8 编码。
   */
  private static toServiceAttributes(attributes: Any): Array<mdns.ServiceAttribute> {
    const result: Array<mdns.ServiceAttribute> = [];
    if (attributes === null || attributes === undefined) {
      return result;
    }
    const encoder = new util.TextEncoder();
    const source = attributes as Record<string, string>;
    Object.keys(source).forEach((key: string) => {
      const bytes: Uint8Array = encoder.encodeInto(source[key]);
      const value: Array<number> = [];
      for (let i = 0; i < bytes.length; i++) {
        value.push(bytes[i]);
      }
      result.push({ key: key, value: value });
    });
    return result;
  }

  /** OHOS Array<ServiceAttribute> → Dart 侧 Map<String,String>（UTF-8 解码）。 */
  private static fromServiceAttributes(attributes: Array<mdns.ServiceAttribute> | undefined): Map<string, Object> {
    const map = new Map<string, Object>();
    if (attributes === undefined) {
      return map;
    }
    const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    attributes.forEach((item: mdns.ServiceAttribute) => {
      map.set(item.key, decoder.decodeWithStream(new Uint8Array(item.value), { stream: false }));
    });
    return map;
  }

  private static serviceKey(info: mdns.LocalServiceInfo): string {
    return `${info.serviceName}|${info.serviceType}|${info.port ?? DEFAULT_PORT}`;
  }

  private static callServiceKey(call: MethodCall): string {
    const name: string = (call.argument('name') as string) ?? '';
    const type: string = (call.argument('type') as string) ?? '';
    const port: number = (call.argument('port') as number) ?? DEFAULT_PORT;
    return `${name}|${type}|${port}`;
  }
}
