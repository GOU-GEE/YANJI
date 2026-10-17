
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos'

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";

  // The system starting window can disappear before Flutter has rasterized its
  // first frame. FlutterPage removes this matching SVG only on onFirstFrame.
  @Builder
  launchClock() {
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.launch_mark'))
        .width(px2vp(512))
        .height(px2vp(512))
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  build() {
    Column() {
      FlutterPage({ viewId: this.viewId, splashScreenView: this.launchClock })
    }
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}
