Pod::Spec.new do |s|
   s.name     = 'GEReelsMapView'
   s.version  = '1.0.0'
   s.summary  = 'GEReelsMapView'
   s.homepage = 'https://github.com/moi23/GEReelsMapView.com'
   s.author   = { 'GEReelsMapView' => 'GEReelsMapView@bakerhugles.com' }
   s.source   = { :git => 'https://github.com/moi23/GEReelsMapView.git', :tag => '1.0.0' }
  
 
   s.license  = 'MIT'
   s.frameworks = 'SVGKit','CocoaLumberjack'
   s.subspec 'GEReelsMapView' do |ss|
       ss.source_files = 'GEReelsMapView/*.{h,m}'
     end
 end