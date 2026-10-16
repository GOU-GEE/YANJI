#!/usr/bin/env python3
"""Stage a separate native test app; never install a test module into Yanji."""
import hashlib
import json
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'work/harmonyos/native-security-project'
BUNDLE = 'com.example.yanji.securitytests'


def write(path, value):
    target = STAGE / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n' if isinstance(value, dict) else value)


def main():
    STAGE.mkdir(parents=True, exist_ok=True)
    write('AppScope/app.json5', {'app': {'bundleName': BUNDLE, 'vendor': 'YanJi', 'versionCode': 1,
          'versionName': '1.0.0', 'icon': '$media:app_icon', 'label': '$string:app_name'}})
    write('AppScope/resources/base/element/string.json', {'string': [{'name': 'app_name', 'value': 'YanJi Security Tests'}]})
    media = STAGE / 'AppScope/resources/base/media'
    media.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT/'ohos/AppScope/resources/base/media/app_icon.png', media/'app_icon.png')
    write('build-profile.json5', {'app': {'signingConfigs': [], 'products': [{
        'name': 'default', 'compileSdkVersion': '26.0.0', 'compatibleSdkVersion': '5.0.5(17)',
        'targetSdkVersion': '26.0.0', 'runtimeOS': 'HarmonyOS'}], 'buildModeSet': [{'name': 'debug'}]},
        'modules': [{'name': 'entry', 'srcPath': './entry', 'targets': [{'name': 'default', 'applyToProducts': ['default']}]}]})
    write('hvigorfile.ts', "import { appTasks } from '@ohos/hvigor-ohos-plugin';\nexport default { system: appTasks, plugins: [] };\n")
    write('hvigor/hvigor-config.json5', {'modelVersion': '5.1.0', 'dependencies': {}})
    write('oh-package.json5', {'modelVersion': '5.1.0', 'name': 'yanji-security-tests', 'version': '1.0.0',
          'dependencies': {}, 'devDependencies': {'@ohos/hypium': '1.0.6'}})
    write('entry/oh-package.json5', {'name': 'entry', 'version': '1.0.0', 'dependencies': {}})
    shutil.copyfile(ROOT/'ohos/entry/build-profile.json5', STAGE/'entry/build-profile.json5')
    shutil.copyfile(ROOT/'ohos/entry/hvigorfile.ts', STAGE/'entry/hvigorfile.ts')
    main_src = STAGE / 'entry/src/main'
    shutil.copytree(ROOT/'ohos/entry/src/main/resources/base/element', main_src/'resources/base/element', dirs_exist_ok=True)
    shutil.copytree(ROOT/'ohos/entry/src/main/resources/base/media', main_src/'resources/base/media', dirs_exist_ok=True)
    write('entry/src/main/module.json5', {'module': {'name': 'entry', 'type': 'entry',
        'description': '$string:module_desc', 'mainElement': 'EntryAbility', 'deviceTypes': ['phone'],
        'deliveryWithInstall': True, 'installationFree': False, 'pages': '$profile:main_pages',
        'abilities': [{'name': 'EntryAbility', 'srcEntry': './ets/entryability/EntryAbility.ets',
          'icon': '$media:icon', 'label': '$string:EntryAbility_label', 'exported': False}]}})
    write('entry/src/main/resources/base/profile/main_pages.json', {'src': ['pages/Index']})
    write('entry/src/main/ets/entryability/EntryAbility.ets', "import UIAbility from '@ohos.app.ability.UIAbility';\nexport default class EntryAbility extends UIAbility {}\n")
    write('entry/src/main/ets/pages/Index.ets', "@Entry\n@Component\nstruct Index { build() { Column() { Text('Native security acceptance') } } }\n")
    # Copy the exact production class and native tests, without rewriting either.
    source = ROOT / 'ohos/entry/src/main/ets/platform/HuksSecretStore.ets'
    target = main_src/'ets/platform/HuksSecretStore.ets'
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    assert source.read_bytes() == target.read_bytes()
    shutil.copytree(ROOT/'ohos/entry/src/ohosTest', STAGE/'entry/src/ohosTest', dirs_exist_ok=True)
    write('source-provenance.json', {'bundleName': BUNDLE,
        'productionSource': str(source.relative_to(ROOT)), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()})
    print(f'Independent native test project: {STAGE}')


if __name__ == '__main__':
    main()
