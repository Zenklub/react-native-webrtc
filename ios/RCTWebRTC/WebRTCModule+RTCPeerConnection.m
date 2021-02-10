//
//  WebRTCModule+ZENPeerConnection.m
//
//  Created by one on 2015/9/24.
//  Copyright © 2015 One. All rights reserved.
//

#import <objc/runtime.h>

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>

#import <WebRTC/ZENConfiguration.h>
#import <WebRTC/ZENIceCandidate.h>
#import <WebRTC/ZENIceServer.h>
#import <WebRTC/ZENMediaConstraints.h>
#import <WebRTC/ZENIceCandidate.h>
#import <WebRTC/ZENSessionDescription.h>
#import <WebRTC/ZENStatisticsReport.h>

#import "WebRTCModule.h"
#import "WebRTCModule+ZENDataChannel.h"
#import "WebRTCModule+ZENPeerConnection.h"
#import "WebRTCModule+VideoTrackAdapter.h"

@implementation ZENPeerConnection (React)

- (NSMutableDictionary<NSNumber *, ZENDataChannel *> *)dataChannels
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setDataChannels:(NSMutableDictionary<NSNumber *, ZENDataChannel *> *)dataChannels
{
  objc_setAssociatedObject(self, @selector(dataChannels), dataChannels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)reactTag
{
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setReactTag:(NSNumber *)reactTag
{
  objc_setAssociatedObject(self, @selector(reactTag), reactTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary<NSString *, ZENMediaStream *> *)remoteStreams
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRemoteStreams:(NSMutableDictionary<NSString *,ZENMediaStream *> *)remoteStreams
{
    objc_setAssociatedObject(self, @selector(remoteStreams), remoteStreams, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary<NSString *, ZENMediaStreamTrack *> *)remoteTracks
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setRemoteTracks:(NSMutableDictionary<NSString *,ZENMediaStreamTrack *> *)remoteTracks
{
    objc_setAssociatedObject(self, @selector(remoteTracks), remoteTracks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)webRTCModule
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWebRTCModule:(id)webRTCModule
{
    objc_setAssociatedObject(self, @selector(webRTCModule), webRTCModule, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation WebRTCModule (ZENPeerConnection)

RCT_EXPORT_METHOD(peerConnectionInit:(ZENConfiguration*)configuration
                            objectID:(nonnull NSNumber *)objectID)
{
  NSDictionary *optionalConstraints = @{ @"DtlsSrtpKeyAgreement" : @"true" };
  ZENMediaConstraints* constraints =
      [[ZENMediaConstraints alloc] initWithMandatoryConstraints:nil
                                            optionalConstraints:optionalConstraints];
  ZENPeerConnection *peerConnection
    = [self.peerConnectionFactory
      peerConnectionWithConfiguration:configuration
			  constraints:constraints
                             delegate:self];

  peerConnection.dataChannels = [NSMutableDictionary new];
  peerConnection.reactTag = objectID;
  peerConnection.remoteStreams = [NSMutableDictionary new];
  peerConnection.remoteTracks = [NSMutableDictionary new];
  peerConnection.videoTrackAdapters = [NSMutableDictionary new];
  peerConnection.webRTCModule = self;
  self.peerConnections[objectID] = peerConnection;
}

RCT_EXPORT_METHOD(peerConnectionSetConfiguration:(ZENConfiguration*)configuration objectID:(nonnull NSNumber *)objectID)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }
  [peerConnection setConfiguration:configuration];
}

RCT_EXPORT_METHOD(peerConnectionAddStream:(nonnull NSString *)streamID objectID:(nonnull NSNumber *)objectID)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }
  ZENMediaStream *stream = self.localStreams[streamID];
  if (!stream) {
    return;
  }

  [peerConnection addStream:stream];
}

RCT_EXPORT_METHOD(peerConnectionRemoveStream:(nonnull NSString *)streamID objectID:(nonnull NSNumber *)objectID)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }
  ZENMediaStream *stream = self.localStreams[streamID];
  if (!stream) {
    return;
  }

  [peerConnection removeStream:stream];
}


RCT_EXPORT_METHOD(peerConnectionCreateOffer:(nonnull NSNumber *)objectID
                                    options:(NSDictionary *)options
                                   callback:(RCTResponseSenderBlock)callback)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }

  ZENMediaConstraints *constraints =
    [[ZENMediaConstraints alloc] initWithMandatoryConstraints:options
                                          optionalConstraints:nil];

  [peerConnection
    offerForConstraints:constraints
      completionHandler:^(ZENSessionDescription *sdp, NSError *error) {
        if (error) {
          callback(@[
            @(NO),
            @{
              @"type": @"CreateOfferFailed",
              @"message": error.localizedDescription ?: [NSNull null]
            }
          ]);
        } else {
          NSString *type = [ZENSessionDescription stringForType:sdp.type];
          callback(@[@(YES), @{@"sdp": sdp.sdp, @"type": type}]);
        }
      }];
}

RCT_EXPORT_METHOD(peerConnectionCreateAnswer:(nonnull NSNumber *)peerConnectionId
                                     options:(NSDictionary *)options
                                    callback:(RCTResponseSenderBlock)callback)
{
  ZENPeerConnection *peerConnection = self.peerConnections[peerConnectionId];
  if (!peerConnection) {
    return;
  }

  ZENMediaConstraints *constraints =
    [[ZENMediaConstraints alloc] initWithMandatoryConstraints:options
                                          optionalConstraints:nil];

  [peerConnection
    answerForConstraints:constraints
       completionHandler:^(ZENSessionDescription *sdp, NSError *error) {
         if (error) {
           callback(@[
             @(NO),
             @{
               @"type": @"CreateAnswerFailed",
               @"message": error.localizedDescription ?: [NSNull null]
             }
           ]);
         } else {
           NSString *type = [ZENSessionDescription stringForType:sdp.type];
           callback(@[@(YES), @{@"sdp": sdp.sdp, @"type": type}]);
         }
       }];
}

RCT_EXPORT_METHOD(peerConnectionSetLocalDescription:(ZENSessionDescription *)sdp objectID:(nonnull NSNumber *)objectID callback:(RCTResponseSenderBlock)callback)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }

  [peerConnection setLocalDescription:sdp completionHandler: ^(NSError *error) {
    if (error) {
      id errorResponse = @{
        @"name": @"SetLocalDescriptionFailed",
        @"message": error.localizedDescription ?: [NSNull null]
      };
      callback(@[@(NO), errorResponse]);
    } else {
      callback(@[@(YES)]);
    }
  }];
}

RCT_EXPORT_METHOD(peerConnectionSetRemoteDescription:(ZENSessionDescription *)sdp objectID:(nonnull NSNumber *)objectID callback:(RCTResponseSenderBlock)callback)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }

  [peerConnection setRemoteDescription: sdp completionHandler: ^(NSError *error) {
    if (error) {
      id errorResponse = @{
        @"name": @"SetRemoteDescriptionFailed",
        @"message": error.localizedDescription ?: [NSNull null]
      };
      callback(@[@(NO), errorResponse]);
    } else {
      callback(@[@(YES)]);
    }
  }];
}

RCT_EXPORT_METHOD(peerConnectionAddICECandidate:(ZENIceCandidate*)candidate objectID:(nonnull NSNumber *)objectID callback:(RCTResponseSenderBlock)callback)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }

  [peerConnection addIceCandidate:candidate];
  RCTLogTrace(@"addICECandidateresult: %@", candidate);
  callback(@[@true]);
}

RCT_EXPORT_METHOD(peerConnectionClose:(nonnull NSNumber *)objectID)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    return;
  }

  // Remove video track adapters
  for(ZENMediaStream *stream in [peerConnection.remoteStreams allValues]) {
    for (ZENVideoTrack *track in stream.videoTracks) {
      [peerConnection removeVideoTrackAdapter:track];
    }
  }

  [peerConnection close];
  [self.peerConnections removeObjectForKey:objectID];

  // Clean up peerConnection's streams and tracks
  [peerConnection.remoteStreams removeAllObjects];
  [peerConnection.remoteTracks removeAllObjects];

  // Clean up peerConnection's dataChannels.
  NSMutableDictionary<NSNumber *, ZENDataChannel *> *dataChannels
    = peerConnection.dataChannels;
  for (NSNumber *dataChannelId in dataChannels) {
    dataChannels[dataChannelId].delegate = nil;
    // There is no need to close the ZENDataChannel because it is owned by the
    // ZENPeerConnection and the latter will close the former.
  }
  [dataChannels removeAllObjects];
}

RCT_EXPORT_METHOD(peerConnectionGetStats:(nonnull NSNumber *) objectID
                                resolver:(RCTPromiseResolveBlock)resolve
                                rejecter:(RCTPromiseRejectBlock)reject)
{
  ZENPeerConnection *peerConnection = self.peerConnections[objectID];
  if (!peerConnection) {
    reject(@"invalid_id", @"PeerConnection ID not found", nil);
    return;
  }

  [peerConnection statisticsWithCompletionHandler:^(ZENStatisticsReport *report) {
    resolve([self statsToJSON:report]);
  }];
}

/**
 * Constructs a JSON <tt>NSString</tt> representation of a specific
 * <tt>ZENStatisticsReport</tt>s.
 * <p>
 *
 * @param <tt>ZENStatisticsReport</tt>s
 * @return an <tt>NSString</tt> which represents the specified <tt>report</tt> in
 * JSON format
 */
- (NSString *)statsToJSON:(ZENStatisticsReport *)report
{
  /* 
  The initial capacity matters, of course, because it determines how many
  times the NSMutableString will have grow. But walking through the reports
  to compute an initial capacity which exactly matches the requirements of
  the reports is too much work without real-world bang here. An improvement
  should be caching the required capacity from the previous invocation of the 
  method and using it as the initial capacity in the next invocation. 
  As I didn't want to go even through that,choosing just about any initial 
  capacity is OK because NSMutableCopy doesn't have too bad a strategy of growing.
  */
  NSMutableString *s = [NSMutableString stringWithCapacity:16 * 1024];

  [s appendString:@"["];
  BOOL firstReport = YES;
  for (NSString *key in report.statistics.allKeys) {
    if (firstReport) {
      firstReport = NO;
    } else {
      [s appendString:@","];
    }
  
    [s appendString:@"[\""];
    [s appendString: key];
    [s appendString:@"\",{"];

    RTCStatistics *statistics = report.statistics[key];
    [s appendString:@"\"timestamp\":\""];
    [s appendFormat:@"%f", statistics.timestamp_us];
    [s appendString:@"\",\"type\":\""]; 
    [s appendString:statistics.type];
    [s appendString:@"\",\"id\":\""];
    [s appendString:statistics.id];
    [s appendString:@"\""];

    for (id key in statistics.values) {
        [s appendString:@","];
        [s appendString:@"\""];
        [s appendString:key];
        [s appendString:@"\":"];
        NSObject *statisticsValue = [statistics.values objectForKey:key];
        if ([statisticsValue isKindOfClass:[NSArray class]]) {
            [s appendString:@"["];
            BOOL firstValue = YES;
            for (NSObject *value in statisticsValue) {
              if(firstValue) {
                firstValue = NO;
              } else {
                [s appendString:@","];
              }

              [s appendString:@"\""];
              [s appendString:[NSString stringWithFormat:@"%@", value]];
              [s appendString:@"\""];
            }
            [s appendString:@"]"];
        } else {
            [s appendString:@"\""];
            [s appendString:[NSString stringWithFormat:@"%@", statisticsValue]];
            [s appendString:@"\""];
        }
    }
    
    [s appendString:@"}]"];
  } 

  [s appendString:@"]"];

  return s;
}

- (NSString *)stringForPeerConnectionState:(ZENPeerConnectionState)state {
  switch (state) {
    case ZENPeerConnectionStateNew: return @"new";
    case ZENPeerConnectionStateConnecting: return @"connecting";
    case ZENPeerConnectionStateConnected: return @"connected";
    case ZENPeerConnectionStateDisconnected: return @"disconnected";
    case ZENPeerConnectionStateFailed: return @"failed";
    case ZENPeerConnectionStateClosed: return @"closed";
  }
  return nil;
}

- (NSString *)stringForICEConnectionState:(RTCIceConnectionState)state {
  switch (state) {
    case RTCIceConnectionStateNew: return @"new";
    case RTCIceConnectionStateChecking: return @"checking";
    case RTCIceConnectionStateConnected: return @"connected";
    case RTCIceConnectionStateCompleted: return @"completed";
    case RTCIceConnectionStateFailed: return @"failed";
    case RTCIceConnectionStateDisconnected: return @"disconnected";
    case RTCIceConnectionStateClosed: return @"closed";
    case RTCIceConnectionStateCount: return @"count";
  }
  return nil;
}

- (NSString *)stringForICEGatheringState:(RTCIceGatheringState)state {
  switch (state) {
    case RTCIceGatheringStateNew: return @"new";
    case RTCIceGatheringStateGathering: return @"gathering";
    case RTCIceGatheringStateComplete: return @"complete";
  }
  return nil;
}

- (NSString *)stringForSignalingState:(RTCSignalingState)state {
  switch (state) {
    case RTCSignalingStateStable: return @"stable";
    case RTCSignalingStateHaveLocalOffer: return @"have-local-offer";
    case RTCSignalingStateHaveLocalPrAnswer: return @"have-local-pranswer";
    case RTCSignalingStateHaveRemoteOffer: return @"have-remote-offer";
    case RTCSignalingStateHaveRemotePrAnswer: return @"have-remote-pranswer";
    case RTCSignalingStateClosed: return @"closed";
  }
  return nil;
}

#pragma mark - ZENPeerConnectionDelegate methods

- (void)peerConnection:(ZENPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)newState {
  [self sendEventWithName:kEventPeerConnectionSignalingStateChanged
                     body:@{
                       @"id": peerConnection.reactTag,
                       @"signalingState": [self stringForSignalingState:newState]
                     }];
}

- (void)peerConnection:(ZENPeerConnection *)peerConnection didAddStream:(ZENMediaStream *)stream {
  NSString *streamReactTag = [[NSUUID UUID] UUIDString];
  NSMutableArray *tracks = [NSMutableArray array];
  for (ZENVideoTrack *track in stream.videoTracks) {
    peerConnection.remoteTracks[track.trackId] = track;
    [peerConnection addVideoTrackAdapter:streamReactTag track:track];
    [tracks addObject:@{@"id": track.trackId, @"kind": track.kind, @"label": track.trackId, @"enabled": @(track.isEnabled), @"remote": @(YES), @"readyState": @"live"}];
  }
  for (ZENAudioTrack *track in stream.audioTracks) {
    peerConnection.remoteTracks[track.trackId] = track;
    [tracks addObject:@{@"id": track.trackId, @"kind": track.kind, @"label": track.trackId, @"enabled": @(track.isEnabled), @"remote": @(YES), @"readyState": @"live"}];
  }

  peerConnection.remoteStreams[streamReactTag] = stream;
  [self sendEventWithName:kEventPeerConnectionAddedStream
                     body:@{
                       @"id": peerConnection.reactTag,
                       @"streamId": stream.streamId,
                       @"streamReactTag": streamReactTag,
                       @"tracks": tracks
                     }];
}

- (void)peerConnection:(ZENPeerConnection *)peerConnection didRemoveStream:(ZENMediaStream *)stream {
  // XXX Find the stream by comparing the 'streamId' values. It turns out that WebRTC (as of M69) creates new wrapper
  // instance for the native media stream before invoking the 'didRemoveStream' callback. This means it's a different
  // ZENMediaStream instance passed to 'didAddStream' and 'didRemoveStream'.
  NSString *streamReactTag = nil;
  for (NSString *aReactTag in peerConnection.remoteStreams) {
    ZENMediaStream *aStream = peerConnection.remoteStreams[aReactTag];
    if ([aStream.streamId isEqualToString:stream.streamId]) {
      streamReactTag = aReactTag;
      break;
    }
  }
  if (!streamReactTag) {
    RCTLogWarn(@"didRemoveStream - stream not found, id: %@", stream.streamId);
    return;
  }
  for (ZENVideoTrack *track in stream.videoTracks) {
    [peerConnection removeVideoTrackAdapter:track];
    [peerConnection.remoteTracks removeObjectForKey:track.trackId];
  }
  for (ZENAudioTrack *track in stream.audioTracks) {
    [peerConnection.remoteTracks removeObjectForKey:track.trackId];
  }
  [peerConnection.remoteStreams removeObjectForKey:streamReactTag];
  [self sendEventWithName:kEventPeerConnectionRemovedStream
                     body:@{
                       @"id": peerConnection.reactTag,
                       @"streamId": streamReactTag
                     }];
}

- (void)peerConnectionShouldNegotiate:(ZENPeerConnection *)peerConnection {
  [self sendEventWithName:kEventPeerConnectionOnRenegotiationNeeded
                     body:@{ @"id": peerConnection.reactTag }];
}

- (void)peerConnection:(ZENPeerConnection *)peerConnection didChangeConnectionState:(ZENPeerConnectionState)newState {
  [self sendEventWithName:kEventPeerConnectionStateChanged
                     body:@{@"id": peerConnection.reactTag, @"connectionState": [self stringForPeerConnectionState:newState]}];
}

- (void)peerConnection:(ZENPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
  [self sendEventWithName:kEventPeerConnectionIceConnectionChanged
                     body:@{
                       @"id": peerConnection.reactTag,
                       @"iceConnectionState": [self stringForICEConnectionState:newState]
                     }];
}

- (void)peerConnection:(ZENPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
  [self sendEventWithName:kEventPeerConnectionIceGatheringChanged
                     body:@{
                       @"id": peerConnection.reactTag,
                       @"iceGatheringState": [self stringForICEGatheringState:newState]
                     }];
}

- (void)peerConnection:(ZENPeerConnection *)peerConnection didGenerateIceCandidate:(ZENIceCandidate *)candidate {
  [self sendEventWithName:kEventPeerConnectionGotICECandidate
                     body:@{
                       @"id": peerConnection.reactTag,
                       @"candidate": @{
                           @"candidate": candidate.sdp,
                           @"sdpMLineIndex": @(candidate.sdpMLineIndex),
                           @"sdpMid": candidate.sdpMid
                       }
                     }];
}

- (void)peerConnection:(ZENPeerConnection*)peerConnection didOpenDataChannel:(ZENDataChannel*)dataChannel {
  // XXX RTP data channels are not defined by the WebRTC standard, have been
  // deprecated in Chromium, and Google have decided (in 2015) to no longer
  // support them (in the face of multiple reported issues of breakages).
  if (-1 == dataChannel.channelId) {
    return;
  }

  NSNumber *dataChannelId = [NSNumber numberWithInteger:dataChannel.channelId];
  dataChannel.peerConnectionId = peerConnection.reactTag;
  peerConnection.dataChannels[dataChannelId] = dataChannel;
  // WebRTCModule implements the category ZENDataChannel i.e. the protocol
  // ZENDataChannelDelegate.
  dataChannel.delegate = self;

  NSDictionary *body = @{@"id": peerConnection.reactTag,
                        @"dataChannel": @{@"id": dataChannelId,
                                          @"label": dataChannel.label}};
  [self sendEventWithName:kEventPeerConnectionDidOpenDataChannel body:body];
}

- (void)peerConnection:(nonnull ZENPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<ZENIceCandidate *> *)candidates {
  // TODO
}

@end
