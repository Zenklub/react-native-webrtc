//
//  WebRTCModule.m
//
//  Created by one on 2015/9/24.
//  Copyright © 2015 One. All rights reserved.
//

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#endif

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

#import <WebRTC/ZENDefaultVideoDecoderFactory.h>
#import <WebRTC/ZENDefaultVideoEncoderFactory.h>

#import "WebRTCModule.h"
#import "WebRTCModule+ZENPeerConnection.h"

@interface WebRTCModule ()
@end

@implementation WebRTCModule

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

- (void)dealloc
{
  [_localTracks removeAllObjects];
  _localTracks = nil;
  [_localStreams removeAllObjects];
  _localStreams = nil;

  for (NSNumber *peerConnectionId in _peerConnections) {
    ZENPeerConnection *peerConnection = _peerConnections[peerConnectionId];
    peerConnection.delegate = nil;
    [peerConnection close];
  }
  [_peerConnections removeAllObjects];

  _peerConnectionFactory = nil;
}

- (instancetype)init
{
    return [self initWithEncoderFactory:nil decoderFactory:nil];
}

- (instancetype)initWithEncoderFactory:(nullable id<ZENVideoEncoderFactory>)encoderFactory
                        decoderFactory:(nullable id<ZENVideoDecoderFactory>)decoderFactory
{
  self = [super init];
  if (self) {
    if (encoderFactory == nil) {
      encoderFactory = [[ZENDefaultVideoEncoderFactory alloc] init];
    }
    if (decoderFactory == nil) {
      decoderFactory = [[ZENDefaultVideoDecoderFactory alloc] init];
    }
    _peerConnectionFactory
      = [[ZENPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory
                                                  decoderFactory:decoderFactory];

    _peerConnections = [NSMutableDictionary new];
    _localStreams = [NSMutableDictionary new];
    _localTracks = [NSMutableDictionary new];

    dispatch_queue_attr_t attributes =
    dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,
                                            QOS_CLASS_USER_INITIATED, -1);
    _workerQueue = dispatch_queue_create("WebRTCModule.queue", attributes);
  }
  return self;
}

- (ZENMediaStream*)streamForReactTag:(NSString*)reactTag
{
  ZENMediaStream *stream = _localStreams[reactTag];
  if (!stream) {
    for (NSNumber *peerConnectionId in _peerConnections) {
      ZENPeerConnection *peerConnection = _peerConnections[peerConnectionId];
      stream = peerConnection.remoteStreams[reactTag];
      if (stream) {
        break;
      }
    }
  }
  return stream;
}

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
  return _workerQueue;
}

- (NSArray<NSString *> *)supportedEvents {
  return @[
    kEventPeerConnectionSignalingStateChanged,
    kEventPeerConnectionStateChanged,
    kEventPeerConnectionAddedStream,
    kEventPeerConnectionRemovedStream,
    kEventPeerConnectionOnRenegotiationNeeded,
    kEventPeerConnectionIceConnectionChanged,
    kEventPeerConnectionIceGatheringChanged,
    kEventPeerConnectionGotICECandidate,
    kEventPeerConnectionDidOpenDataChannel,
    kEventDataChannelStateChanged,
    kEventDataChannelReceiveMessage,
    kEventMediaStreamTrackMuteChanged
  ];
}

@end
