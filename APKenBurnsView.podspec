Pod::Spec.new do |s|
  s.name             = "APKenBurnsView"
  s.version          = "1.0.5"
  s.summary          = "KenBurns effect written in pure Swift with face recognition."
  s.homepage         = "https://github.com/matthijsotterloo/APKenBurnsView"
  s.license          = 'MIT'
  s.author           = { "Nickolay Sheika" => "nickolai.sheika@alterplay.com" }
  s.source           = { :git => "https://github.com/matthijsotterloo/APKenBurnsView.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
end
