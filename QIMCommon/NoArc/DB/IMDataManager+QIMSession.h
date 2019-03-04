//
//  IMDataManager+QIMSession.h
//  QIMCommon
//
//  Created by 李露 on 2018/7/5.
//  Copyright © 2018年 QIMKit. All rights reserved.
//

#import "IMDataManager.h"

@interface IMDataManager (QIMSession)

- (void)qimDB_updateSessionLastMsgIdWithSessionId:(NSString *)sessionId
                                    WithLastMsgId:(NSString *)lastMsgId;

- (void)qimDB_insertSessionWithSessionId:(NSString *)sessinId
                              WithUserId:(NSString *)userId
                           WithLastMsgId:(NSString *)lastMsgId
                      WithLastUpdateTime:(long long)lastUpdateTime
                                ChatType:(int)ChatType
                             WithRealJid:(id)realJid;

- (void)qimDB_deleteSession:(NSString *)xmppId RealJid:(NSString *)realJid;

- (void)qimDB_deleteSession:(NSString *)xmppId;

- (NSDictionary *)qimDB_getLastedSingleChatSession;

- (NSArray *)qimDB_getFullSessionListWithSingleChatType:(int)singleChatType;

- (NSArray *)qimDB_getNotReadSessionList;

- (NSArray *)qimDB_getSessionListWithSingleChatType:(int)singleChatType;

- (NSArray *)qimDB_getSessionListXMPPIDWithSingleChatType:(int)singleChatType;

- (NSDictionary *)qimDB_getChatSessionWithUserId:(NSString *)userId chatType:(int)chatType;

- (NSDictionary *)qimDB_getChatSessionWithUserId:(NSString *)userId WithRealJid:(NSString *)realJid;

- (NSDictionary *)qimDB_getChatSessionWithUserId:(NSString *)userId;

- (NSInteger)qimDB_getAppNotReadCount;

@end
