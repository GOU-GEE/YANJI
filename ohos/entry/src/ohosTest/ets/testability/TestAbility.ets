import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';
import window from '@ohos.window';

export default class TestAbility extends UIAbility {
  onCreate(): void {
    Hypium.hypiumTest(
      AbilityDelegatorRegistry.getAbilityDelegator(),
      AbilityDelegatorRegistry.getArguments(),
      (): void => testsuite(this.context)
    );
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('testability/pages/Index');
  }
}
