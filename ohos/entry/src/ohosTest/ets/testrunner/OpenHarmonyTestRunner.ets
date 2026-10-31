import TestRunner from '@ohos.application.testRunner';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

// The native UIAbility supplies a valid Stage context to Preferences/HUKS.
// No fault-injection methods are registered on the production Flutter channel.
export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {}
  async onRun(): Promise<void> {
    const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
    const args = AbilityDelegatorRegistry.getArguments();
    await delegator.startAbility({
      bundleName: args.bundleName,
      moduleName: 'entry_test',
      abilityName: 'TestAbility'
    });
  }
}
