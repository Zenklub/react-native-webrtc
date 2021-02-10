#import "RCTConvert+WebRTC.h"
#import <React/RCTLog.h>
#import <WebRTC/ZENDataChannelConfiguration.h>
#import <WebRTC/ZENIceServer.h>
#import <WebRTC/ZENSessionDescription.h>

@implementation RCTConvert (WebRTC)

+ (ZENSessionDescription *)ZENSessionDescription:(id)json
{
  if (!json) {
    RCTLogConvertError(json, @"must not be null");
    return nil;
  }

  if (![json isKindOfClass:[NSDictionary class]]) {
    RCTLogConvertError(json, @"must be an object");
    return nil;
  }

  if (json[@"sdp"] == nil) {
    RCTLogConvertError(json, @".sdp must not be null");
    return nil;
  }

  NSString *sdp = json[@"sdp"];
  RTCSdpType sdpType = [ZENSessionDescription typeForString:json[@"type"]];

  return [[ZENSessionDescription alloc] initWithType:sdpType sdp:sdp];
}

+ (ZENIceCandidate *)ZENIceCandidate:(id)json
{
  if (!json) {
    RCTLogConvertError(json, @"must not be null");
    return nil;
  }

  if (![json isKindOfClass:[NSDictionary class]]) {
    RCTLogConvertError(json, @"must be an object");
    return nil;
  }

  if (json[@"candidate"] == nil) {
    RCTLogConvertError(json, @".candidate must not be null");
    return nil;
  }

  NSString *sdp = json[@"candidate"];
  RCTLogTrace(@"%@ <- candidate", sdp);
  int sdpMLineIndex = [RCTConvert int:json[@"sdpMLineIndex"]];
  NSString *sdpMid = json[@"sdpMid"];


  return [[ZENIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
}

+ (ZENIceServer *)ZENIceServer:(id)json
{
  if (!json) {
    RCTLogConvertError(json, @"a valid iceServer value");
    return nil;
  }

  if (![json isKindOfClass:[NSDictionary class]]) {
    RCTLogConvertError(json, @"must be an object");
    return nil;
  }

  NSArray<NSString *> *urls;
  if ([json[@"url"] isKindOfClass:[NSString class]]) {
    // TODO: 'url' is non-standard
    urls = @[json[@"url"]];
  } else if ([json[@"urls"] isKindOfClass:[NSString class]]) {
    urls = @[json[@"urls"]];
  } else {
    urls = [RCTConvert NSArray:json[@"urls"]];
  }

  if (json[@"username"] != nil || json[@"credential"] != nil) {
    return [[ZENIceServer alloc]initWithURLStrings:urls
                                        username:json[@"username"]
                                        credential:json[@"credential"]];
  }

  return [[ZENIceServer alloc] initWithURLStrings:urls];
}

+ (nonnull ZENConfiguration *)ZENConfiguration:(id)json
{
  ZENConfiguration *config = [[ZENConfiguration alloc] init];

  if (!json) {
    return config;
  }

  if (![json isKindOfClass:[NSDictionary class]]) {
    RCTLogConvertError(json, @"must be an object");
    return config;
  }

  if (json[@"audioJitterBufferMaxPackets"] != nil && [json[@"audioJitterBufferMaxPackets"] isKindOfClass:[NSNumber class]]) {
    config.audioJitterBufferMaxPackets = [RCTConvert int:json[@"audioJitterBufferMaxPackets"]];
  }

  if (json[@"bundlePolicy"] != nil && [json[@"bundlePolicy"] isKindOfClass:[NSString class]]) {
    NSString *bundlePolicy = json[@"bundlePolicy"];
    if ([bundlePolicy isEqualToString:@"balanced"]) {
      config.bundlePolicy = RTCBundlePolicyBalanced;
    } else if ([bundlePolicy isEqualToString:@"max-compat"]) {
      config.bundlePolicy = RTCBundlePolicyMaxCompat;
    } else if ([bundlePolicy isEqualToString:@"max-bundle"]) {
      config.bundlePolicy = RTCBundlePolicyMaxBundle;
    }
  }

  if (json[@"iceBackupCandidatePairPingInterval"] != nil && [json[@"iceBackupCandidatePairPingInterval"] isKindOfClass:[NSNumber class]]) {
    config.iceBackupCandidatePairPingInterval = [RCTConvert int:json[@"iceBackupCandidatePairPingInterval"]];
  }

  if (json[@"iceConnectionReceivingTimeout"] != nil && [json[@"iceConnectionReceivingTimeout"] isKindOfClass:[NSNumber class]]) {
    config.iceConnectionReceivingTimeout = [RCTConvert int:json[@"iceConnectionReceivingTimeout"]];
  }

  if (json[@"iceServers"] != nil && [json[@"iceServers"] isKindOfClass:[NSArray class]]) {
    NSMutableArray<ZENIceServer *> *iceServers = [NSMutableArray new];
    for (id server in json[@"iceServers"]) {
      ZENIceServer *convert = [RCTConvert ZENIceServer:server];
      if (convert != nil) {
        [iceServers addObject:convert];
      }
    }
    config.iceServers = iceServers;
  }

  if (json[@"iceTransportPolicy"] != nil && [json[@"iceTransportPolicy"] isKindOfClass:[NSString class]]) {
    NSString *iceTransportPolicy = json[@"iceTransportPolicy"];
    if ([iceTransportPolicy isEqualToString:@"all"]) {
      config.iceTransportPolicy = RTCIceTransportPolicyAll;
    } else if ([iceTransportPolicy isEqualToString:@"none"]) {
      config.iceTransportPolicy = RTCIceTransportPolicyNone;
    } else if ([iceTransportPolicy isEqualToString:@"nohost"]) {
      config.iceTransportPolicy = RTCIceTransportPolicyNoHost;
    } else if ([iceTransportPolicy isEqualToString:@"relay"]) {
      config.iceTransportPolicy = RTCIceTransportPolicyRelay;
    }
  }

  if (json[@"rtcpMuxPolicy"] != nil && [json[@"rtcpMuxPolicy"] isKindOfClass:[NSString class]]) {
    NSString *rtcpMuxPolicy = json[@"rtcpMuxPolicy"];
    if ([rtcpMuxPolicy isEqualToString:@"negotiate"]) {
      config.rtcpMuxPolicy = RTCRtcpMuxPolicyNegotiate;
    } else if ([rtcpMuxPolicy isEqualToString:@"require"]) {
      config.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
    }
  }

  if (json[@"tcpCandidatePolicy"] != nil && [json[@"tcpCandidatePolicy"] isKindOfClass:[NSString class]]) {
    NSString *tcpCandidatePolicy = json[@"tcpCandidatePolicy"];
    if ([tcpCandidatePolicy isEqualToString:@"enabled"]) {
      config.tcpCandidatePolicy = RTCTcpCandidatePolicyEnabled;
    } else if ([tcpCandidatePolicy isEqualToString:@"disabled"]) {
      config.tcpCandidatePolicy = RTCTcpCandidatePolicyDisabled;
    }
  }

  return config;
}

+ (ZENDataChannelConfiguration *)ZENDataChannelConfiguration:(id)json
{
  if (!json) {
    return nil;
  }
  if ([json isKindOfClass:[NSDictionary class]]) {
    ZENDataChannelConfiguration *init = [ZENDataChannelConfiguration new];

    if (json[@"id"]) {
      [init setChannelId:[RCTConvert int:json[@"id"]]];
    }

    if (json[@"ordered"]) {
      init.isOrdered = [RCTConvert BOOL:json[@"ordered"]];
    }
    if (json[@"maxRetransmits"]) {
      init.maxRetransmits = [RCTConvert int:json[@"maxRetransmits"]];
    }
    if (json[@"negotiated"]) {
      init.isNegotiated = [RCTConvert NSInteger:json[@"negotiated"]];
    }
    if (json[@"protocol"]) {
      init.protocol = [RCTConvert NSString:json[@"protocol"]];
    }
    return init;
  }
  return nil;
}

@end
