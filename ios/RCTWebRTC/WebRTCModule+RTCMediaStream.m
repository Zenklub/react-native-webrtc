//
//  WebRTCModule+ZENMediaStream.m
//
//  Created by one on 2015/9/24.
//  Copyright © 2015 One. All rights reserved.
//

#import <objc/runtime.h>

#import <WebRTC/ZENCameraVideoCapturer.h>
#import <WebRTC/ZENVideoTrack.h>
#import <WebRTC/ZENMediaConstraints.h>

#import "ZENMediaStreamTrack+React.h"
#import "WebRTCModule+ZENPeerConnection.h"

@implementation WebRTCModule (ZENMediaStream)

#pragma mark - getUserMedia

/**
 * Initializes a new {@link ZENAudioTrack} which satisfies the given constraints.
 *
 * @param constraints The {@code MediaStreamConstraints} which the new
 * {@code ZENAudioTrack} instance is to satisfy.
 */
- (ZENAudioTrack *)createAudioTrack:(NSDictionary *)constraints {
  NSString *trackId = [[NSUUID UUID] UUIDString];
  ZENAudioTrack *audioTrack
    = [self.peerConnectionFactory audioTrackWithTrackId:trackId];
  return audioTrack;
}

/**
 * Initializes a new {@link ZENVideoTrack} which satisfies the given constraints.
 */
- (ZENVideoTrack *)createVideoTrack:(NSDictionary *)constraints {
  ZENVideoSource *videoSource = [self.peerConnectionFactory videoSource];

  NSString *trackUUID = [[NSUUID UUID] UUIDString];
  ZENVideoTrack *videoTrack = [self.peerConnectionFactory videoTrackWithSource:videoSource trackId:trackUUID];

#if !TARGET_IPHONE_SIMULATOR
  ZENCameraVideoCapturer *videoCapturer = [[ZENCameraVideoCapturer alloc] initWithDelegate:videoSource];
  VideoCaptureController *videoCaptureController
        = [[VideoCaptureController alloc] initWithCapturer:videoCapturer
                                            andConstraints:constraints[@"video"]];
  videoTrack.videoCaptureController = videoCaptureController;
  [videoCaptureController startCapture];
#endif

  return videoTrack;
}

/**
  * Implements {@code getUserMedia}. Note that at this point constraints have
  * been normalized and permissions have been granted. The constraints only
  * contain keys for which permissions have already been granted, that is,
  * if audio permission was not granted, there will be no "audio" key in
  * the constraints dictionary.
  */
RCT_EXPORT_METHOD(getUserMedia:(NSDictionary *)constraints
               successCallback:(RCTResponseSenderBlock)successCallback
                 errorCallback:(RCTResponseSenderBlock)errorCallback) {
  ZENAudioTrack *audioTrack = nil;
  ZENVideoTrack *videoTrack = nil;

  if (constraints[@"audio"]) {
      audioTrack = [self createAudioTrack:constraints];
  }
  if (constraints[@"video"]) {
      videoTrack = [self createVideoTrack:constraints];
  }

  if (audioTrack == nil && videoTrack == nil) {
    // Fail with DOMException with name AbortError as per:
    // https://www.w3.org/TR/mediacapture-streams/#dom-mediadevices-getusermedia
    errorCallback(@[ @"DOMException", @"AbortError" ]);
    return;
  }

  NSString *mediaStreamId = [[NSUUID UUID] UUIDString];
  ZENMediaStream *mediaStream
    = [self.peerConnectionFactory mediaStreamWithStreamId:mediaStreamId];
  NSMutableArray *tracks = [NSMutableArray array];
  NSMutableArray *tmp = [NSMutableArray array];
  if (audioTrack)
      [tmp addObject:audioTrack];
  if (videoTrack)
      [tmp addObject:videoTrack];

  for (ZENMediaStreamTrack *track in tmp) {
    if ([track.kind isEqualToString:@"audio"]) {
      [mediaStream addAudioTrack:(ZENAudioTrack *)track];
    } else if([track.kind isEqualToString:@"video"]) {
      [mediaStream addVideoTrack:(ZENVideoTrack *)track];
    }

    NSString *trackId = track.trackId;

    self.localTracks[trackId] = track;
    [tracks addObject:@{
                        @"enabled": @(track.isEnabled),
                        @"id": trackId,
                        @"kind": track.kind,
                        @"label": trackId,
                        @"readyState": @"live",
                        @"remote": @(NO)
                        }];
  }

  self.localStreams[mediaStreamId] = mediaStream;
  successCallback(@[ mediaStreamId, tracks ]);
}

#pragma mark - Other stream related APIs

RCT_EXPORT_METHOD(enumerateDevices:(RCTResponseSenderBlock)callback)
{
    NSMutableArray *devices = [NSMutableArray array];
    AVCaptureDeviceDiscoverySession *videoevicesSession
        = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                                 mediaType:AVMediaTypeVideo
                                                                  position:AVCaptureDevicePositionUnspecified];
    for (AVCaptureDevice *device in videoevicesSession.devices) {
        NSString *position = @"unknown";
        if (device.position == AVCaptureDevicePositionBack) {
            position = @"environment";
        } else if (device.position == AVCaptureDevicePositionFront) {
            position = @"front";
        }
        NSString *label = @"Unknown video device";
        if (device.localizedName != nil) {
            label = device.localizedName;
        }
        [devices addObject:@{
                             @"facing": position,
                             @"deviceId": device.uniqueID,
                             @"groupId": @"",
                             @"label": label,
                             @"kind": @"videoinput",
                             }];
    }
    AVCaptureDeviceDiscoverySession *audioDevicesSession
        = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInMicrophone ]
                                                                 mediaType:AVMediaTypeAudio
                                                                  position:AVCaptureDevicePositionUnspecified];
    for (AVCaptureDevice *device in audioDevicesSession.devices) {
        NSString *label = @"Unknown audio device";
        if (device.localizedName != nil) {
            label = device.localizedName;
        }
        [devices addObject:@{
                             @"deviceId": device.uniqueID,
                             @"groupId": @"",
                             @"label": label,
                             @"kind": @"audioinput",
                             }];
    }
    callback(@[devices]);
}

RCT_EXPORT_METHOD(mediaStreamCreate:(nonnull NSString *)streamID)
{
    ZENMediaStream *mediaStream = [self.peerConnectionFactory mediaStreamWithStreamId:streamID];
    self.localStreams[streamID] = mediaStream;
}

RCT_EXPORT_METHOD(mediaStreamAddTrack:(nonnull NSString *)streamID : (nonnull NSString *)trackID)
{
    ZENMediaStream *mediaStream = self.localStreams[streamID];
    ZENMediaStreamTrack *track = [self trackForId:trackID];

    if (mediaStream && track) {
        if ([track.kind isEqualToString:@"audio"]) {
            [mediaStream addAudioTrack:(ZENAudioTrack *)track];
        } else if([track.kind isEqualToString:@"video"]) {
            [mediaStream addVideoTrack:(ZENVideoTrack *)track];
        }
    }
}

RCT_EXPORT_METHOD(mediaStreamRemoveTrack:(nonnull NSString *)streamID : (nonnull NSString *)trackID)
{
    ZENMediaStream *mediaStream = self.localStreams[streamID];
    ZENMediaStreamTrack *track = [self trackForId:trackID];

    if (mediaStream && track) {
        if ([track.kind isEqualToString:@"audio"]) {
            [mediaStream removeAudioTrack:(ZENAudioTrack *)track];
        } else if([track.kind isEqualToString:@"video"]) {
            [mediaStream removeVideoTrack:(ZENVideoTrack *)track];
        }
    }
}

RCT_EXPORT_METHOD(mediaStreamRelease:(nonnull NSString *)streamID)
{
  ZENMediaStream *stream = self.localStreams[streamID];
  if (stream) {
    [self.localStreams removeObjectForKey:streamID];
  }
}

RCT_EXPORT_METHOD(mediaStreamTrackRelease:(nonnull NSString *)trackID)
{
    ZENMediaStreamTrack *track = self.localTracks[trackID];
    if (track) {
        track.isEnabled = NO;
        [track.videoCaptureController stopCapture];
        [self.localTracks removeObjectForKey:trackID];
    }
}

RCT_EXPORT_METHOD(mediaStreamTrackSetEnabled:(nonnull NSString *)trackID : (BOOL)enabled)
{
  ZENMediaStreamTrack *track = [self trackForId:trackID];
  if (track) {
    track.isEnabled = enabled;
    if (track.videoCaptureController) {  // It could be a remote track!
      if (enabled) {
        [track.videoCaptureController startCapture];
      } else {
        [track.videoCaptureController stopCapture];
      }
    }
  }
}

RCT_EXPORT_METHOD(mediaStreamTrackSwitchCamera:(nonnull NSString *)trackID)
{
  ZENMediaStreamTrack *track = self.localTracks[trackID];
  if (track) {
    ZENVideoTrack *videoTrack = (ZENVideoTrack *)track;
    [videoTrack.videoCaptureController switchCamera];
  }
}

#pragma mark - Helpers

- (ZENMediaStreamTrack*)trackForId:(NSString*)trackId
{
  ZENMediaStreamTrack *track = self.localTracks[trackId];
  if (!track) {
    for (NSNumber *peerConnectionId in self.peerConnections) {
      ZENPeerConnection *peerConnection = self.peerConnections[peerConnectionId];
      track = peerConnection.remoteTracks[trackId];
      if (track) {
        break;
      }
    }
  }
  return track;
}

@end
