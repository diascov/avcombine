# AVCombine

This library allows you to manage video/audio files in your iOS app.

Minimum deployment target is `iOS 11`.

## Installation

### CocoaPods

1. Add the following to your `Podfile`:

        pod 'AVCombine', :git => 'https://github.com/diascov/avcombine.git'

2. Install pods with `pod install`
3. Test your install by adding `import AVCombine` to your class

### Swift Package Manager (Xcode 11+)

1. In Xcode, select File > Swift Packages > Add Package Dependency.
2. Follow the prompts using URL:

        https://github.com/diascov/avcombine.git

3. Test your install by adding `import AVCombine` to your class

## Usage

### Capture

1. Create instance of class `AVCombineCaptureService(superLayer:maxRecordedDuration:delegate:)`
2. Call method `setupCaptureSession(position:)` for session init
3. Use `startCapture(source:)` to start recording and `stopCapture()` to break recording

### Crop video
`crop(asset:type:startTime:endTime:_:)`

### Generate video
`generateVideo(from:_:)`
`generateVideo(from:duration:_:)`

### Merge videos
`merge(assets:type:_:)`

### Overlays
`add(overlays:in:_:)`
