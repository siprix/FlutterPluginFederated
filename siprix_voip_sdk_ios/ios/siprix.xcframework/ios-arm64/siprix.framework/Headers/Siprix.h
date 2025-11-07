//
//  SiprixCore.h
//
//  Created by Created by Siprix Team.
//

#ifndef SiprixCore_h
#define SiprixCore_h

#define EXPORT __attribute__ ((visibility ("default") ))
#define IMPORT __attribute__ ((visibility ("default") ))

#import <Foundation/Foundation.h>

#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#else
//#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#endif

typedef NS_ENUM(NSInteger, SipTransport) {
    SipTransportUdp=0,
    SipTransportTcp,
    SipTransportTls
};

typedef NS_ENUM(NSInteger, RegState) {
    RegStateSuccess=0,
    RegStateFailed,
    RegStateRemoved,
    RegStateInProgress
};

typedef NS_ENUM(NSInteger, SubscrState) {
    SubscrCreated = 0,
    SubscrUpdated,
    SubscrDestroyed
};

typedef NS_ENUM(NSInteger, NetworkState) {
    NetworkStateLost = 0,
    NetworkStateRestored,
    NetworkStateSwitched,
};

typedef NS_ENUM(NSInteger, PlayerState) {
    PlayerStateStarted = 0,
    PlayerStateStopped,
    PlayerStateFailed,
};

typedef NS_ENUM(NSInteger, HoldState) {
    HoldStateNone = 0,
    HoldStateLocal = 1,
    HoldStateRemote = 2,
    HoldStateLocalAndRemote = 3
};

typedef NS_ENUM(NSInteger, CallState) {
    CallStateDialing=0,       //Outgoing call just initiated
    CallStateProceeding,      //Outgoing call in progress, received 100Trying or 180Ringing
    CallStateRinging,         //Incoming call just received
    CallStateRejecting,       //Incoming call rejecting after invoke 'call.reject'
    CallStateAccepting,       //Incoming call aceepting after invoke 'call.accept'
    CallStateConnected,       //Call successfully established, RTP is flowing
    CallStateDisconnecting,   //Call disconnecting after invoke 'call.bye'
    CallStateHolding,         //Call holding (renegotiating RTP stream states)
    CallStateHeld,            //Call held, RTP is NOT flowing
    CallStateTransferring     //Call transferring
};

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelStack=0,
    LogLevelDebug=1,
    LogLevelInfo=2,
    LogLevelWarning=3,
    LogLevelError=4,
    LogLevelNoLog=5
};

typedef NS_ENUM(NSInteger, DtmfMethod) {
    DtmfMethodRtp=0,
    DtmfMethodInfo=1
};

typedef NS_ENUM(NSInteger, SecureMedia) {
    SecureMediaDisabled=0,
    SecureMediaSdesSrtp, // SRTP with SDP key negotiation, SAVP profile 
    SecureMediaDtlsSrtp, // SRTP with DTLS key negotiation, SAVP profile
};

typedef NS_ENUM(NSInteger, AudioCodecs) {
    AudioCodecsOpus   = 65,
    AudioCodecsISAC16 = 66,
    AudioCodecsISAC32 = 67,
    AudioCodecsG722   = 68,
    AudioCodecsILBC   = 69,
    AudioCodecsPCMU   = 70,
    AudioCodecsPCMA   = 71,
    AudioCodecsDTMF   = 72,
    AudioCodecsCN     = 73,
    AudioCodecsG729   = 74,
};

typedef NS_ENUM(NSInteger, VideoCodecs) {
    VideoCodecsH264 = 80,
    VideoCodecsVP8  = 81,
    VideoCodecsVP9  = 82,
    VideoCodecsAV1  = 83
};

typedef NS_ENUM(NSInteger, VideoFrameRotation) {
    VideoFrameRotationRotation_0 = 0,
    VideoFrameRotationRotation_90 = 90,
    VideoFrameRotationRotation_180 = 180,
    VideoFrameRotationRotation_270 = 270
};

typedef NS_ENUM(NSInteger, VideoFrameRGBType) {
    VideoFrameRGBTypeARGB, 
    VideoFrameRGBTypeBGRA,
    VideoFrameRGBTypeABGR,
    VideoFrameRGBTypeRGBA
};

typedef NS_ENUM(NSInteger, UpgradeToVideoMode) {
    UpgradeToVideoModeSendRecv = 0,
    UpgradeToVideoModeRecvOnly = 1,
    UpgradeToVideoModeInactive = 2
};

static const int kErrorCodeEOK = 0;
static const NSInteger kInvalidId = 0;

EXPORT
@interface SiprixIniData : NSObject
@property(nonatomic, retain) NSString * _Nullable license;
@property(nonatomic, retain) NSString * _Nullable homeFolder;
@property(nonatomic, retain) NSNumber * _Nullable logLevelFile;
@property(nonatomic, retain) NSNumber * _Nullable logLevelIde;
@property(nonatomic, retain) NSNumber * _Nullable rtpStartPort;
@property(nonatomic, retain) NSNumber * _Nullable tlsVerifyServer;
@property(nonatomic, retain) NSNumber * _Nullable singleCallMode;
@property(nonatomic, retain) NSNumber * _Nullable shareUdpTransport;
@property(nonatomic, retain) NSNumber * _Nullable unregOnDestroy;
@property(nonatomic, retain) NSArray  * _Nullable dnsServers;
@property(nonatomic, retain) NSNumber * _Nullable useDnsSrv;
@property(nonatomic, retain) NSNumber * _Nullable recordStereo;
@property(nonatomic, retain) NSNumber * _Nullable enableVideoCall;
@property(nonatomic, retain) NSNumber * _Nullable transpForceIPv4;
@property(nonatomic, retain) NSNumber * _Nullable enableAes128Sha32;
@property(nonatomic, retain) NSNumber * _Nullable enableVUmeter;
@property(nonatomic, retain) NSString * _Nullable brandName;
@end

EXPORT
@interface SiprixAccData : NSObject
@property(nonatomic, assign) int  myAccId;
@property(nonatomic, retain) NSString * _Nonnull sipServer;
@property(nonatomic, retain) NSString * _Nonnull sipExtension;
@property(nonatomic, retain) NSString * _Nonnull sipPassword;
@property(nonatomic, retain) NSString * _Nullable sipAuthId;
@property(nonatomic, retain) NSString * _Nullable sipProxy;
@property(nonatomic, retain) NSString * _Nullable displName;
@property(nonatomic, retain) NSString * _Nullable userAgent;
@property(nonatomic, retain) NSNumber * _Nullable expireTime;
@property(nonatomic, retain) NSNumber * _Nullable port;
@property(nonatomic, assign) SipTransport transport;
@property(nonatomic, retain) NSString * _Nullable tlsCaCertPath;
@property(nonatomic, retain) NSNumber * _Nullable tlsUseSipScheme;
@property(nonatomic, retain) NSNumber * _Nullable rtcpMuxEnabled;
@property(nonatomic, retain) NSNumber * _Nullable iceEnabled;
@property(nonatomic, retain) NSNumber * _Nullable keepAliveTime;
@property(nonatomic, retain) NSNumber * _Nullable rewriteContactIp;
@property(nonatomic, retain) NSNumber * _Nullable verifyIncomingCall;
@property(nonatomic, retain) NSNumber * _Nullable forceSipProxy;
@property(nonatomic, retain) NSNumber * _Nullable secureMedia;
@property(nonatomic, retain) NSNumber * _Nullable transpPreferIPv6;
@property(nonatomic, retain) NSString * _Nullable instanceId;
@property(nonatomic, retain) NSString * _Nullable ringTonePath;
@property(nonatomic, retain) NSString * _Nullable stunServer;
@property(nonatomic, retain) NSString * _Nullable turnServer;
@property(nonatomic, retain) NSString * _Nullable turnUser;
@property(nonatomic, retain) NSString * _Nullable turnPassword;
@property(nonatomic, retain) NSNumber * _Nullable upgradeToVideo;
@property(nonatomic, retain) NSDictionary * _Nullable xheaders;
@property(nonatomic, retain) NSDictionary * _Nullable xContactUriParams;
@property(nonatomic, retain) NSArray  * _Nullable aCodecs;
@property(nonatomic, retain) NSArray  * _Nullable vCodecs;
- (NSDictionary* _Nonnull)toDictionary;
- (void)fromDictionary:(NSDictionary* _Nonnull)dictionary;
@end

EXPORT
@interface SiprixDestData : NSObject
@property(nonatomic, assign) int myCallId;
@property(nonatomic, assign) int fromAccId;
@property(nonatomic, retain) NSString * _Nonnull toExt;
@property(nonatomic, retain) NSNumber * _Nullable withVideo;
@property(nonatomic, retain) NSNumber * _Nullable inviteTimeoutSec;
@property(nonatomic, retain) NSDictionary * _Nullable xheaders;
@property(nonatomic, retain) NSString* _Nullable displName;
@end

EXPORT
@interface SiprixSubscrData : NSObject
@property(nonatomic, assign) int mySubscrId;
@property(nonatomic, assign) int fromAccId;
@property(nonatomic, retain) NSString* _Nonnull toExt;
@property(nonatomic, retain) NSString* _Nonnull mimeSubtype;
@property(nonatomic, retain) NSString* _Nonnull eventType;
@property(nonatomic, retain) NSNumber* _Nullable expireTime;
@end

EXPORT
@interface SiprixMsgData : NSObject
@property(nonatomic, assign) int myMessageId;
@property(nonatomic, assign) int fromAccId;
@property(nonatomic, retain) NSString* _Nonnull toExt;
@property(nonatomic, retain) NSString* _Nonnull body;
@end

EXPORT
@interface SiprixHoldData : NSObject
@property(nonatomic, assign) HoldState holdState;
@end

EXPORT
@interface SiprixVideoStateData : NSObject
@property(nonatomic, assign) BOOL hasVideo;
@end

EXPORT
@interface SiprixVideoData : NSObject
@property(nonatomic, retain) NSString* _Nullable noCameraImgPath;
@property(nonatomic, retain) NSNumber* _Nullable framerateFps;
@property(nonatomic, retain) NSNumber* _Nullable bitrateKbps;
@property(nonatomic, retain) NSNumber* _Nullable height;
@property(nonatomic, retain) NSNumber* _Nullable width;
@end

EXPORT
@interface SiprixPlayerData : NSObject
@property(nonatomic, assign) int playerId;
@end

EXPORT
@interface SiprixDevicesNumbData : NSObject
@property(nonatomic, assign) int number;
@end

EXPORT
@interface SiprixDeviceData : NSObject
@property(nonatomic, retain) NSString * _Nonnull name;
@property(nonatomic, retain) NSString * _Nonnull guid;
@end


@protocol SiprixVideoFrame <NSObject>
@required
- (int) width;
- (int) height;
- (VideoFrameRotation) rotation;
- (void)convertToARGB:(VideoFrameRGBType)type dstBuffer:(uint8_t* _Nonnull)dstBuffer
                    dstWidth:(int)dstWidth dstHeight:(int)dstHeight dstStride:(int)dstStride;
@end


@protocol SiprixVideoRendererDelegate <NSObject>
@required
- (void)onFrame:(id<SiprixVideoFrame> _Nonnull) videoFrame;
@end


@protocol SiprixEventDelegate <NSObject>
@required
- (void)onTrialModeNotified;
- (void)onDevicesAudioChanged;

- (void)onAccountRegState:(NSInteger)accId
            regState:(RegState)regState
            response:(NSString * _Nonnull)response;
- (void)onSubscriptionState:(NSInteger)subscrId
            subscrState:(SubscrState)subscrState
            response:(NSString * _Nonnull)response;
- (void)onNetworkState:(NSString * _Nonnull)name
              netState:(NetworkState)netState;
- (void)onPlayerState:(NSInteger)playerId
             playerState:(PlayerState)playerState;

- (void)onRingerState:(BOOL) started;


- (void)onCallProceeding:(NSInteger)callId
            response:(NSString * _Nonnull)response;

- (void)onCallTerminated:(NSInteger)callId
            statusCode:(NSInteger)statusCode;

- (void)onCallConnected:(NSInteger)callId
            hdrFrom:(NSString * _Nonnull)hdrFrom
            hdrTo:(NSString * _Nonnull)hdrTo
            withVideo:(BOOL)withVideo;

- (void)onCallIncoming:(NSInteger)callId accId:(NSInteger)accId
            withVideo:(BOOL)withVideo
            hdrFrom:(NSString * _Nonnull)from
            hdrTo:(NSString * _Nonnull)to;

- (void)onCallDtmfReceived:(NSInteger)callId
            tone:(NSInteger)tone;
            
- (void) onCallSwitched:(NSInteger)callId;

- (void)onCallTransferred:(NSInteger)callId
            statusCode:(NSInteger)statusCode;

- (void)onCallRedirected:(NSInteger)origCallId
            relatedCallId:(NSInteger)relatedCallId
            referTo:(NSString * _Nonnull)referTo;

- (void)onCallVideoUpgraded:(NSInteger) callId
          withVideo:(BOOL)withVideo;

- (void)onCallHeld:(NSInteger)callId
          holdState:(HoldState)holdState;

- (void)onMessageSentState:(NSInteger)messageId success:(BOOL)success
          response:(NSString * _Nonnull)response;
- (void)onMessageIncoming:(NSInteger)messageId accId:(NSInteger)accId
          hdrFrom:(NSString * _Nonnull)hdrFrom
          body:(NSString * _Nonnull)body;

- (void)onSipNotify:(NSInteger)accId
          hdrEvent:(NSString * _Nonnull)hdrFrom
          body:(NSString * _Nonnull)body;
- (void)onVuMeterLevel:(NSInteger)micLevel spkLevel:(NSInteger)spkLevel;

@end



EXPORT
@interface SiprixModule : NSObject
- (int)initialize:(id<SiprixEventDelegate> _Nonnull)delegate
            iniData:(SiprixIniData* _Nonnull)iniData;
- (int)unInitialize;
- (BOOL)isInitialized;
- (NSString* _Nonnull) version;
- (NSString* _Nonnull) homeFolder;
- (int) versionCode;
- (void)writeLog:(NSString * _Nonnull)str;

#if TARGET_OS_IPHONE
- (void)enableCallKit:(BOOL)enable;
- (void)activateSession:(AVAudioSession* _Nonnull)session;
- (void)deactivateSession:(AVAudioSession* _Nonnull)session;
- (BOOL)overrideAudioOutputToSpeaker:(BOOL)on;
 -(BOOL)routeAudioToBluetoth;
 -(BOOL)routeAudioToBuiltIn;
#endif

- (int)accountAdd:(SiprixAccData* _Nonnull)accData;
- (int)accountUpdate:(SiprixAccData* _Nonnull)accData accId:(int)accId;
- (int)accountRegister:(int)accId expireTime:(int)expireTime;
- (int)accountUnRegister:(int)accId;
- (int)accountDelete:(int)accId;
- (NSString * _Nonnull)accountGenInstId;

- (int)callInvite:(SiprixDestData* _Nonnull)destData;
- (int)callReject:(int)callId statusCode:(int)statusCode;
- (int)callAccept:(int)callId withVideo:(BOOL)withVideo;
- (int)callHold:(int)callId;
- (int)callGetHoldState:(int)callId holdState:(SiprixHoldData* _Nonnull)data;
- (int)callGetVideoState:(int)callId hasVideo:(SiprixVideoStateData * _Nonnull) data;
- (int)callMuteMic:(int)callId mute:(BOOL)mute;
- (int)callMuteCam:(int)callId mute:(BOOL)mute;
- (int)callSendDtmf:(int)callId dtmfs:(NSString* _Nonnull)dtmfs
         durationMs:(int)durationMs intertoneGapMs:(int)intertoneGapMs method:(DtmfMethod)method;
- (int)callSendDtmf:(int)callId dtmfs:(NSString* _Nonnull)dtmfs;
- (int)callPlayFile:(int)callId pathToMp3File:(NSString* _Nonnull)pathToMp3File loop:(BOOL)loop
                                     playerData:(SiprixPlayerData* _Nonnull)data;
- (int)callStopPlayFile:(int)playerId;
- (int)callRecordFile:(int)callId pathToMp3File : (NSString * _Nonnull)pathToMp3File;
- (int)callStopRecordFile:(int)callId;
- (int)callTransferBlind:(int)callId toExt:(NSString* _Nonnull)toExt;
- (int)callTransferAttended:(int)fromCallId toCallId:(int)toCallId;
- (int)callUpgradeToVideo:(int)callId;
- (int)callBye:(int)callId;

- (int)callSetVideoRenderer:(int)callId renderer:(id<SiprixVideoRendererDelegate> _Nullable) renderer;
- (NSString* _Nonnull)callGetSipHeader:(int)callId hdrName:(NSString * _Nonnull)hdrName;
- (NSString* _Nonnull)callGetStats:(int)callId;
- (void)callStopRingtone;

#if TARGET_OS_IPHONE
- (int)switchCamera;
- (int)callSetVideoWindow:(int)callId view : (UIView * _Nullable) view;
- (UIView* _Nonnull)createVideoWindow;
#else
- (int)callSetVideoWindow:(int)callId view : (NSView * _Nullable) view;
-(NSView* _Nonnull)createVideoWindow;
#endif

- (int)mixerSwitchCall:(int)callId;
- (int)mixerMakeConference;

#if (TARGET_OS_OSX)
- (int)dvcGetPlayoutDevices:(SiprixDevicesNumbData* _Nonnull)data;
- (int)dvcGetRecordingDevices:(SiprixDevicesNumbData* _Nonnull)data;
- (int)dvcGetVideoDevices:(SiprixDevicesNumbData* _Nonnull)data;
- (int)dvcGetPlayoutDevice:(int)index device:(SiprixDeviceData* _Nonnull)device;
- (int)dvcGetRecordingDevice:(int)index device:(SiprixDeviceData* _Nonnull)device;
- (int)dvcGetVideoDevice:(int)index device:(SiprixDeviceData* _Nonnull)device;
- (int)dvcSetPlayoutDevice:(int)index;
- (int)dvcSetRecordingDevice:(int)index;
- (int)dvcSetVideoDevice:(int)index;
#endif//(TARGET_OS_OSX)
- (int)dvcSetVideoParams:(SiprixVideoData* _Nonnull)vdoData;

- (int)subscrCreate:(SiprixSubscrData * _Nonnull)subscrData;
- (int)subscrDestroy:(int)subscrId;

- (int)messageSend:(SiprixMsgData * _Nonnull)msgData;

- (NSString* _Nonnull)getErrorText:(int)errCode;
- (void)dealloc;
@end

#endif /* SiprixCore_h */
