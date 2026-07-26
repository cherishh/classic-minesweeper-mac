#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'ClassicMinesweeper.xcodeproj')

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes['LastSwiftUpdateCheck'] = '2600'
project.root_object.attributes['LastUpgradeCheck'] = '2600'

app_group = project.main_group.new_group('Classic Minesweeper')
sources_group = app_group.new_group('Sources', 'Sources/WinMine98')
resources_group = app_group.new_group('Resources', 'Resources')
tests_group = app_group.new_group('Tests', 'Tests/WinMine98Tests')

app_target = project.new_target(
  :application,
  'WinMine98',
  :osx,
  '13.0',
  project.products_group,
  :swift,
  'Classic Minesweeper'
)

Dir.glob(File.join(ROOT, 'Sources/WinMine98/*.swift')).sort.each do |path|
  reference = sources_group.new_file(File.basename(path))
  app_target.source_build_phase.add_file_reference(reference)
end

asset_catalog = resources_group.new_file('Assets.xcassets')
app_target.resources_build_phase.add_file_reference(asset_catalog)

%w[RetroAssets Fonts].each do |folder_name|
  reference = resources_group.new_file(folder_name)
  reference.last_known_file_type = 'folder'
  app_target.resources_build_phase.add_file_reference(reference)
end

%w[
  PrivacyInfo.xcprivacy
  LICENSES.txt
  AlexAegis-Minesweeper-LICENSE.txt
  PixelatedMSSansSerif-LICENSE.txt
  PixelatedMSSansSerifBold-LICENSE.txt
].each do |filename|
  reference = resources_group.new_file(filename)
  app_target.resources_build_phase.add_file_reference(reference)
end

resources_group.new_file('Info.plist')
resources_group.new_file('ClassicMinesweeper.entitlements')

app_target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'dev.tuxi.classicminesweeper'
  settings['PRODUCT_NAME'] = 'Classic Minesweeper'
  settings['PRODUCT_MODULE_NAME'] = 'WinMine98'
  settings['INFOPLIST_FILE'] = 'Resources/Info.plist'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'Resources/ClassicMinesweeper.entitlements'
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  settings['MARKETING_VERSION'] = '1.0'
  settings['CURRENT_PROJECT_VERSION'] = '1'
  settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
  settings['SWIFT_VERSION'] = '5.9'
  settings['DEVELOPMENT_TEAM'] = 'PS3XQRQ595'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['ENABLE_HARDENED_RUNTIME'] = 'YES'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['ONLY_ACTIVE_ARCH'] = 'NO'
  settings['ARCHS'] = '$(ARCHS_STANDARD)'
  settings['SDKROOT'] = 'macosx'
end

test_target = project.new_target(
  :unit_test_bundle,
  'WinMine98Tests',
  :osx,
  '13.0',
  project.products_group,
  :swift
)

Dir.glob(File.join(ROOT, 'Tests/WinMine98Tests/*.swift')).sort.each do |path|
  reference = tests_group.new_file(File.basename(path))
  test_target.source_build_phase.add_file_reference(reference)
end

test_target.add_dependency(app_target)
test_target.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'dev.tuxi.classicminesweeper.tests'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
  settings['SWIFT_VERSION'] = '5.9'
  settings['DEVELOPMENT_TEAM'] = 'PS3XQRQ595'
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Classic Minesweeper.app/Contents/MacOS/Classic Minesweeper'
  settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app_target, test_target, launch_target: true)
scheme.save_as(PROJECT_PATH, 'WinMine98', true)

puts PROJECT_PATH
