#
# Be sure to run `pod lib lint ForceDirectedScene.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ForceDirectedScene'
  s.version          = '1.0.1'
  s.summary          = 'A SceneKit compatible Force Directed Graph Implementation'

  s.description      = <<-DESC
    Adds many body particle physics simulation to a SpriteKit Scene targeted
    at supporting the display of a forced directed graph. It minimally interacts
    with SpriteKit to apply a force to each body as an accumlated force from other
    nodes in the simulation, such that each node can still be subjected any other
    forces, collisions, and contacts in SpriteKit's physics simulation.
  DESC

  s.homepage         = 'https://github.com/knightcode/ForceDirectedScene'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'knightcode' => 'knightcode1@yahoo.com' }
  s.source           = { :git => 'https://github.com/knightcode/ForceDirectedScene.git', :tag => s.version.to_s }
  s.social_media_url = 'https://instagram.com/knightcode'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/**/*'

end
