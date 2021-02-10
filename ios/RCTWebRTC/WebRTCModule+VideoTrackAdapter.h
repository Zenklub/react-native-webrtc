
#import "WebRTCModule.h"
#import <WebRTC/ZENPeerConnection.h>

@interface ZENPeerConnection (VideoTrackAdapter)

@property (nonatomic, strong) NSMutableDictionary<NSString *,  id> *videoTrackAdapters;

- (void)addVideoTrackAdapter:(NSString*)streamReactId track:(ZENVideoTrack*)track;
- (void)removeVideoTrackAdapter:(ZENVideoTrack*)track;

@end

