source 'https://github.com/CocoaPods/Specs'

workspace '../DribbbleSDK'

inhibit_all_warnings!

def import_sdk_pod
    platform :ios, '7.0'
    pod 'DribbbleSDK', :path => '../'
end

target :DribbbleSDKDemo do
    xcodeproj 'DribbbleSDKDemo'
    import_sdk_pod
end

target :'DribbbleSDK Tests' do
    xcodeproj '../DribbbleSDK Tests/DribbbleSDK Tests'
    import_sdk_pod
end

target :DribbbleSDKDev do
    xcodeproj '../DribbbleSDKDev/DribbbleSDKDev'
    pod 'AFNetworking', '~> 2.3'
    pod 'BlocksKit'
    pod 'NXOAuth2Client'
    pod 'JSONModel'
end
