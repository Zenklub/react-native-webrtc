//
//  WebRTCModule+ZENPeerConnection.h
//
//  Created by one on 2015/9/24.
//  Copyright © 2015 One. All rights reserved.
//

#import "WebRTCModule.h"
#import <WebRTC/ZENDataChannel.h>
#import <WebRTC/ZENPeerConnection.h>

@interface ZENPeerConnection (React)

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, ZENDataChannel *> *dataChannels;
@property (nonatomic, strong) NSNumber *reactTag;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ZENMediaStream *> *remoteStreams;
@property (nonatomic, strong) NSMutableDictionary<NSString *, ZENMediaStreamTrack *> *remoteTracks;
@property (nonatomic, weak) id webRTCModule;

@end

@interface WebRTCModule (ZENPeerConnection) <ZENPeerConnectionDelegate>

@end
