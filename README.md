webrtc-ios-1
============
Build script which builds Google WebRTC project into iOS WebRTC.framework.
Simply add WebRTC.framework into your Xcode project, include following libraries and enjoy deploying WebRTC enabled apps.

#### Building
Clone repository, enter it using Terminal and **run make -j4**. After build process finishes you should see WebRTC.framework file your root of your working directory.

#### Required libraries:
- libsqlite3.dylib
- libstdc++.6.dylib
- libicucore.dylib
- libc++.dylib
- libxml2.dylib
- GLKit.framework
- UIKit.framework
- Foundation.framework

#### May also require these frameworks:
- VideoToolbox
- GLKit
- AudioToolbox
- AVFoundation
- CoreMedia
