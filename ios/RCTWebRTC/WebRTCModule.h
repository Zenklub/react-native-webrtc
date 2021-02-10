//
//  WebRTCModule.h
//
//  Created by one on 2015/9/24.
//  Copyright © 2015 One. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import <React/RCTEventEmitter.h>

#import <WebRTC/ZENMediaStream.h>
#import <WebRTC/ZENPeerConnectionFactory.h>
#import <WebRTC/ZENPeerConnection.h>
#import <WebRTC/ZENAudioTrack.h>
#import <WebRTC/ZENVideoTrack.h>
#import <WebRTC/ZENVideoDecoderFactory.h>
#import <WebRTC/ZENVideoEncoderFactory.h>

static NSString *const kEventPeerConnectionSignalingStateChanged = @"peerConnectionSignalingStateChanged";
static NSString *const kEventPeerConnectionStateChanged = @"peerConnectionStateChanged";
static NSString *const kEventPeerConnectionAddedStream = @"peerConnectionAddedStream";
static NSString *const kEventPeerConnectionRemovedStream = @"peerConnectionRemovedStream";
static NSString *const kEventPeerConnectionOnRenegotiationNeeded = @"peerConnectionOnRenegotiationNeeded";
static NSString *const kEventPeerConnectionIceConnectionChanged = @"peerConnectionIceConnectionChanged";
static NSString *const kEventPeerConnectionIceGatheringChanged = @"peerConnectionIceGatheringChanged";
static NSString *const kEventPeerConnectionGotICECandidate = @"peerConnectionGotICECandidate";
static NSString *const kEventPeerConnectionDidOpenDataChannel = @"peerConnectionDidOpenDataChannel";
static NSString *const kEventDataChannelStateChanged = @"dataChannelStateChanged";
static NSString *const kEventDataChannelReceiveMessage = @"dataChannelReceiveMessage";
static NSString *const kEventMediaStreamTrackMuteChanged = @"mediaStreamTrackMuteChanged";

@interface WebRTCModule : RCTEventEmitter <RCTBridgeModule>

@property(nonatomic, strong) dispatch_queue_t workerQueue;

@property (nonatomic, strong) ZENPeerConnectionFactory *peerConnectionFactory;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, ZENPeerConnection *> *peerConnections;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ZENMediaStream *> *localStreams;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ZENMediaStreamTrack *> *localTracks;

- (instancetype)initWithEncoderFactory:(id<ZENVideoEncoderFactory>)encoderFactory
                        decoderFactory:(id<ZENVideoDecoderFactory>)decoderFactory;

- (ZENMediaStream*)streamForReactTag:(NSString*)reactTag;

@end
