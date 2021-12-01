
Pod::Spec.new do |spec|

  spec.name         = "CJMVNPT"
  spec.version      = "1.0.6"
  spec.summary      = "CJM - VNPT"

  spec.description  = "Customer Journey Map VNPT."
  spec.homepage     = "https://github.com/anhdungaxz/CJMVNPT.git"
  spec.license      = "MIT"
  spec.author             = { "VNPT Media" => "VNPTMedia@gmail.com" }
  spec.source       = { :git => "https://github.com/anhdungaxz/CJMVNPT.git", :tag => "1.0.6" }

  spec.requires_arc              = true
  spec.module_name               = 'CJMVNPT'
  spec.resources                 = 'CJMVNPT/*.crt'
  spec.ios.dependency             'SDWebImage', '~> 5.1'
  spec.ios.frameworks            ='Firebase/Analytics'
  spec.ios.resources             = 'CJMVNPT/**/*.{png,xib}', 'CJMVNPT/**/*.xcdatamodeld'
  spec.ios.deployment_target     = '9.0'
  spec.ios.source_files          = 'CJMVNPT/**/*.{h,m}', 'CJMVNPT/AES/**/*.{h,m}'
  spec.ios.public_header_files   = 'CJMVNPT/CJM.h', 'CJMVNPT/CJM+SSLPinning.h','CJMVNPT/CJM+Inbox.h', 'CJMVNPT/CJMInstanceConfig.h', 'CJMVNPT/CJMBuildInfo.h', 'CJMVNPT/CJMEventDetail.h', 'CJMVNPT/CJMInAppNotificationDelegate.h', 'CJMVNPT/CJMSyncDelegate.h', 'CJMVNPT/CJMTrackedViewController.h', 'CJMVNPT/CJMUTMDetail.h', 'CJMVNPT/CJMJSInterface.h', 'CJMVNPT/CJM+ABTesting.h', 'CJMVNPT/CJM+DisplayUnit.h', 'CJMVNPT/CJM+FeatureFlags.h', 'CJMVNPT/CJM+ProductConfig.h', 'CJMVNPT/CJMPushNotificationDelegate.h'

end
