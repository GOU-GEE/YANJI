require 'fileutils'

# CocoaPods only discovers vendored frameworks inside the pod root. Keep the
# generated engine in native/build and expose it through an ignored local link.
framework_build_dir = File.join(__dir__, 'build')
FileUtils.mkdir_p(framework_build_dir)
framework_link = File.join(framework_build_dir, 'Engine.xcframework')
unless File.symlink?(framework_link) || File.exist?(framework_link)
  File.symlink('../../native/build/Engine.xcframework', framework_link)
end

Pod::Spec.new do |s|
  s.name = 'yanji_syncthing'
  s.version = '0.1.0'
  s.summary = 'Embedded Syncthing record transport'
  s.description = 'Local-first cross-network synchronization of immutable operation files.'
  s.homepage = 'https://syncthing.net'
  s.license = { :type => 'MPL-2.0', :file => '../LICENSE' }
  s.author = 'YanJi'
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.5'
  s.vendored_frameworks = 'build/Engine.xcframework'
  s.libraries = 'resolv'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
