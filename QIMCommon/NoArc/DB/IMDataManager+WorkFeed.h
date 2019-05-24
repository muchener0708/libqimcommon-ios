//
//  IMDataManager+WorkFeed.h
//  QIMCommon
//
//  Created by lilu on 2019/1/7.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "IMDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMDataManager (WorkFeed)

- (BOOL)qimDB_checkMomentWithMomentId:(NSString *)momentId;

- (void)qimDB_bulkinsertMoments:(NSArray *)moments;

- (NSDictionary *)qimDB_getWorkMomentWithMomentId:(NSString *)momentId;

- (void)qimDB_bulkdeleteMoments:(NSArray *)moments;

- (NSDictionary *)qimDB_getLastWorkMoment;

- (NSArray *)qimDB_getWorkMomentWithXmppId:(NSString *)xmppId WithLimit:(int)limit WithOffset:(int)offset;

- (void)qimDB_deleteMomentWithRId:(NSInteger)rId;

- (void)qimDB_updateMomentLike:(NSArray *)likeMoments;

- (void)qimDB_updateMomentWithLikeNum:(NSInteger)likeMomentNum WithCommentNum:(NSInteger)commentNum withPostId:(NSString *)postId;

#pragma mark - Comment

- (void)qimDB_bulkDeleteCommentsWithPostId:(NSString *)postUUID withcurCommentCreateTime:(long long)createTime;

- (long long)qimDB_getCommentCreateTimeWithCurCommentId:(NSInteger)commentId;

- (void)qimDB_bulkUpdateComments:(NSArray *)comments;

- (void)qimDB_bulkDeleteCommentsAndAllChildComments:(NSArray *)comments;

- (void)qimDB_bulkDeleteComments:(NSArray *)comments;

- (void)qimDB_bulkDeleteCommentsWithPostId:(NSString *)postUUID;

- (void)qimDB_bulkinsertComments:(NSArray *)comments;

- (NSArray *)qimDB_getWorkCommentsWithMomentId:(NSString *)momentId WithLimit:(int)limit WithOffset:(int)offset;

- (NSArray *)qimDB_getWorkChildCommentsWithParentCommentUUID:(NSString *)commentUUID;

#pragma mark - NoticeMessage

- (void)qimDB_bulkinsertNoticeMessage:(NSArray *)notices;

- (long long)qimDB_getWorkNoticeMessagesMaxTime;

- (NSInteger)qimDB_getWorkNoticeMessagesCountWithEventType:(NSArray *)eventTyps;

//新加
- (NSArray *)qimDB_getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset eventTypes:(NSArray *)eventTypes readState:(int)readState;

//新加
- (NSArray *)qimDB_getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset eventTypes:(NSArray *)eventTypes;

//临时
- (NSArray *)qimDB_getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset;

- (NSArray *)qimDB_getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset eventType1:(int)eventType1 eventType2:(int)eventType2 readState:(int)readState;

//驼圈数据库取数据库带参数方法
- (NSArray *)qimDB_getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset eventType:(int)eventType readState:(int)readState;

//我的驼圈儿根据uuid 数组删除deleteListArr
- (void)qimDB_deleteWorkNoticeMessageWithUUid:(NSArray *)deleteListArr;

- (void)qimDB_deleteWorkNoticeMessageWithEventTypes:(NSArray *)eventTypes;

- (void)qimDB_updateWorkNoticeMessageReadStateWithTime:(long long)time;

@end

NS_ASSUME_NONNULL_END
