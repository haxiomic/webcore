# Native WebAudio Implementation
- Based on WebAudio API
- Supports js and hxcpp targets
- Uses miniaudio.h for device interfacing

## Platform Specific Considerations

### iOS
- Link with AVFoundation and AudioToolbox when building your app

### Android
- Link with OpenSLES