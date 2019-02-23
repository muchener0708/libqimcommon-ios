//
//  QIMKit+QIMWorkFeed.m
//  QIMCommon
//
//  Created by lilu on 2019/1/7.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "QIMKit+QIMWorkFeed.h"
#import "QIMPrivateHeader.h"

@implementation QIMKit (QIMWorkFeed)

- (void)updateLastWorkFeedMsgTime {
    [[QIMManager sharedInstance] updateLastWorkFeedMsgTime];
}

- (void)getRemoteMomentDetailWithMomentUUId:(NSString *)momentId withCallback:(QIMKitgetMomentDetailSuccessedBlock)callback {
    [[QIMManager sharedInstance] getRemoteMomentDetailWithMomentUUId:momentId withCallback:callback];
}

- (void)getAnonyMouseDicWithMomentId:(NSString *)momentId WithCallBack:(QIMKitgetAnonymouseSuccessedBlock)callback {
    [[QIMManager sharedInstance] getAnonyMouseDicWithMomentId:momentId WithCallBack:callback];
}

- (void)pushNewMomentWithMomentDic:(NSDictionary *)momentDic {
    [[QIMManager sharedInstance] pushNewMomentWithMomentDic:momentDic];
}

- (void)getMomentHistoryWithLastMomentId:(NSString *)momentId {
    [[QIMManager sharedInstance] getMomentHistoryWithLastMomentId:momentId];
}

- (void)deleteRemoteMomentWithMomentId:(NSString *)momentId {
    [[QIMManager sharedInstance] deleteRemoteMomentWithMomentId:momentId];
}

- (void)likeRemoteMomentWithMomentId:(NSString *)momentId withLikeFlag:(BOOL)likeFlag withCallBack:(QIMKitLikeContentSuccessedBlock)callback {
    [[QIMManager sharedInstance] likeRemoteMomentWithMomentId:momentId withLikeFlag:likeFlag withCallBack:callback];
}

- (void)likeRemoteCommentWithCommentId:(NSString *)commentId withMomentId:(NSString *)momentId withLikeFlag:(BOOL)likeFlag withCallBack:(QIMKitLikeMomentSuccessedBlock)callback {
    [[QIMManager sharedInstance] likeRemoteCommentWithCommentId:commentId withMomentId:momentId withLikeFlag:likeFlag withCallBack:callback];
}

- (void)uploadCommentWithCommentDic:(NSDictionary *)commentDic {
    [[QIMManager sharedInstance] uploadCommentWithCommentDic:commentDic];
}

- (void)getRemoteRecentHotCommentsWithMomentId:(NSString *)momentId withHotCommentCallBack:(QIMKitWorkCommentBlock)callback {
    [[QIMManager sharedInstance] getRemoteRecentHotCommentsWithMomentId:momentId withHotCommentCallBack:callback];
}

- (void)getRemoteRecentNewCommentsWithMomentId:(NSString *)momentId withNewCommentCallBack:(QIMKitWorkCommentBlock)callback {
    [[QIMManager sharedInstance] getRemoteRecentNewCommentsWithMomentId:momentId withNewCommentCallBack:callback];
}

- (NSDictionary *)getWorkMomentWithMomentId:(NSString *)momentId {
    return [[QIMManager sharedInstance] getWorkMomentWithMomentId:momentId];
}

- (void)getWorkMomentWithLastMomentTime:(long long)lastMomentTime withUserXmppId:(NSString *)xmppId WithLimit:(int)limit WithOffset:(int)offset withFirstLocalMoment:(BOOL)firstLocal WithComplete:(void (^)(NSArray *))complete {
    [[QIMManager sharedInstance] getWorkMomentWithLastMomentTime:lastMomentTime withUserXmppId:xmppId WithLimit:limit WithOffset:offset withFirstLocalMoment:firstLocal WithComplete:complete];
}

- (void)deleteRemoteCommentWithComment:(NSString *)commentId withPostUUId:(NSString *)postUUId withCallback:(QIMKitWorkCommentDeleteSuccessBlock)callback {
    [[QIMManager sharedInstance] deleteRemoteCommentWithComment:commentId withPostUUId:postUUId withCallback:callback];
}

#pragma mark - Remote Notice

- (void)updateRemoteWorkNoticeMsgReadStateWithTime:(long long)time {
    [[QIMManager sharedInstance] updateRemoteWorkNoticeMsgReadStateWithTime:time];
}

#pragma mark - Local Comment

- (void)getWorkCommentWithLastCommentRId:(NSInteger)lastCommentRId withMomentId:(NSString *)momentId WithLimit:(int)limit WithOffset:(int)offset withFirstLocalComment:(BOOL)firstLocal WithComplete:(void (^)(NSArray *))complete {
    [[QIMManager sharedInstance] getWorkCommentWithLastCommentRId:lastCommentRId withMomentId:momentId WithLimit:limit WithOffset:offset withFirstLocalComment:firstLocal WithComplete:complete];
}

#pragma mark - Local NoticeMsg

- (void)getRemoteLastWorkMoment {
    [[QIMManager sharedInstance] getRemoteLastWorkMoment];
}

- (NSDictionary *)getLastWorkMoment {
    return [[QIMManager sharedInstance] getLastWorkMoment];
}

- (NSInteger)getWorkNoticeMessagesCount {
    return [[QIMManager sharedInstance] getWorkNoticeMessagesCount];
}

- (NSArray *)getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset {
    return [[QIMManager sharedInstance] getWorkNoticeMessagesWithLimit:limit WithOffset:offset];
}

- (void)updateLocalWorkNoticeMsgReadStateWithTime:(long long)time {
    [[QIMManager sharedInstance] updateLocalWorkNoticeMsgReadStateWithTime:time];
}

@end
