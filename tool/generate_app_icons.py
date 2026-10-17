"""Generate launcher resources from assets/branding/yanji-app-icon.svg.

Requires Python with Pillow and librsvg's rsvg-convert on PATH.
Run from any directory; outputs are confined to this repository.
"""
from copy import deepcopy
from io import BytesIO
import json
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SVG_NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', SVG_NS)
SOURCE = ROOT / 'assets/branding/yanji-app-icon.svg'
renderer = shutil.which('rsvg-convert')
if renderer is None:
    raise SystemExit('Install librsvg to provide rsvg-convert first.')
source = SOURCE.read_bytes()
svg = ET.fromstring(source)
assert svg.attrib['viewBox'] == '0 0 1024 1024'
foreground_color = svg.find(f'{{{SVG_NS}}}g').attrib['fill']
background_color = svg.find(f'{{{SVG_NS}}}rect').attrib['fill']
assert all(color.startswith('#') and len(color) == 7 for color in (foreground_color, background_color))


def render(data, size, opaque=False):
    # Supersample small line art so tray/settings sizes keep smooth edges.
    factor = 4 if size < 256 else 1
    png = subprocess.check_output(
        [renderer, '--width', str(size * factor), '--height', str(size * factor)],
        input=data,
    )
    image = Image.open(BytesIO(png)).convert('RGBA')
    if factor != 1:
        image = image.resize((size, size), Image.Resampling.LANCZOS)
    return image.convert('RGB') if opaque else image


def save(path, image):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target, optimize=True)
    print(path)


cache = {}


def opaque(size):
    if size not in cache:
        cache[size] = render(source, size, opaque=True)
    return cache[size]


save('assets/branding/yanji-app-icon-1024.png', opaque(1024))

# The launch window needs the transparent vector mark, not the opaque tile
# used by launchers. Derive it from the same paths so future artwork stays in sync.
launch = ET.Element(f'{{{SVG_NS}}}svg', {
    # Match the old 512 px resource's intrinsic size. HarmonyOS uses it when
    # sizing this launch icon; a 1024 px SVG would double the visible mark.
    'width': '512', 'height': '512', 'viewBox': '0 0 1024 1024',
})
launch.append(deepcopy(svg.find(f'{{{SVG_NS}}}g')))
launch_target = ROOT / 'ohos/entry/src/main/resources/base/media/launch_mark.svg'
launch_target.write_bytes(ET.tostring(launch, encoding='utf-8', xml_declaration=True))
print(launch_target.relative_to(ROOT))

# Apple catalog filenames and sizes stay defined by their existing manifests.
desktop = ET.Element(f'{{{SVG_NS}}}svg', {
    'width': '1024', 'height': '1024', 'viewBox': '0 0 1024 1024',
})
defs = ET.SubElement(desktop, f'{{{SVG_NS}}}defs')
clip = ET.SubElement(defs, f'{{{SVG_NS}}}clipPath', {'id': 'desktop-tile'})
ET.SubElement(clip, f'{{{SVG_NS}}}rect', {
    'x': '64', 'y': '64', 'width': '896', 'height': '896', 'rx': '196',
})
clipped = ET.SubElement(desktop, f'{{{SVG_NS}}}g', {'clip-path': 'url(#desktop-tile)'})
tile = ET.SubElement(clipped, f'{{{SVG_NS}}}g', {'transform': 'translate(64 64) scale(0.875)'})
for child in svg:
    if child.tag in {f'{{{SVG_NS}}}rect', f'{{{SVG_NS}}}g'}:
        tile.append(deepcopy(child))
desktop_source = ET.tostring(desktop)
written = set()
for platform in ('ios', 'macos'):
    catalog = Path(platform) / 'Runner/Assets.xcassets/AppIcon.appiconset'
    for item in json.loads((ROOT / catalog / 'Contents.json').read_text())['images']:
        path = catalog / item['filename']
        if path in written:
            continue
        size = round(float(item['size'].split('x')[0]) * float(item['scale'][:-1]))
        image = opaque(size) if platform == 'ios' else render(desktop_source, size)
        save(path, image)
        written.add(path)

for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', opaque(size))

# Android 26+ gets a vector foreground and a separate solid background.
# 0.72 keeps the complete artwork inside the 66 dp safe circle on a 108 dp layer.
paths = svg.findall(f'.//{{{SVG_NS}}}path')
assert paths and not svg.findall(f'.//{{{SVG_NS}}}image')
foreground_paths = '\n'.join(
    f'            <path android:fillColor="#FF{foreground_color[1:]}" android:pathData="{p.attrib["d"]}" />'
    for p in paths
)
resources = {
    'drawable/ic_launcher_foreground.xml': f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="1024" android:viewportHeight="1024">
    <group android:pivotX="512" android:pivotY="512" android:scaleX="0.72" android:scaleY="0.72">
        <group android:translateY="1024" android:scaleY="-1">
{foreground_paths}
        </group>
    </group>
</vector>
''',
    'drawable/ic_launcher_background.xml': f'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <solid android:color="#FF{background_color[1:]}" />
</shape>
''',
}
for version, monochrome in [('v26', ''), ('v33', '    <monochrome android:drawable="@drawable/ic_launcher_foreground" />\n')]:
    resources[f'mipmap-anydpi-{version}/ic_launcher.xml'] = f'''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
{monochrome}</adaptive-icon>
'''
for name, text in resources.items():
    target = ROOT / 'android/app/src/main/res' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)
    print(target.relative_to(ROOT))

for path in ('ohos/AppScope/resources/base/media/app_icon.png',
             'ohos/entry/src/main/resources/base/media/icon.png'):
    save(path, opaque(512))

icon = render(desktop_source, 256)
icon.save(ROOT / 'windows/runner/resources/app_icon.ico', format='ICO',
          sizes=[(size, size) for size in (16, 24, 32, 48, 64, 128, 256)])
print('windows/runner/resources/app_icon.ico')
