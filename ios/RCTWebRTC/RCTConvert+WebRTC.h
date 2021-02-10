#import <React/RCTConvert.h>
#import <WebRTC/ZENDataChannelConfiguration.h>
#import <WebRTC/ZENConfiguration.h>
#import <WebRTC/ZENIceServer.h>
#import <WebRTC/ZENSessionDescription.h>
#import <WebRTC/ZENIceCandidate.h>

@interface RCTConvert (WebRTC)

+ (ZENIceCandidate *)ZENIceCandidate:(id)json;
+ (ZENSessionDescription *)ZENSessionDescription:(id)json;
+ (ZENIceServer *)ZENIceServer:(id)json;
+ (ZENDataChannelConfiguration *)ZENDataChannelConfiguration:(id)json;
+ (ZENConfiguration *)ZENConfiguration:(id)json;

@end
