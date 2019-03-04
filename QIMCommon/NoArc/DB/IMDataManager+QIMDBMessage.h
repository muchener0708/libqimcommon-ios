//
//  IMDataManager+QIMDBMessage.h
//  QIMCommon
//
//  Created by 李露 on 11/24/18.
//  Copyright © 2018 QIM. All rights reserved.
//

#import "IMDataManager.h"
#import "QIMPublicRedefineHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMDataManager (QIMDBMessage)

- (void)qimDB_updateMsgTimeToMillSecond;

- (long long)qimDB_getMinMsgTimeStampByXmppId:(NSString *)xmppId RealJid:(NSString *)realJid;

- (long long)qimDB_getMinMsgTimeStampByXmppId:(NSString *)xmppId;

- (long long)qimDB_lastestGroupMessageTime;

- (long long)qimDB_getMaxMsgTimeStampByXmppId:(NSString *)xmppId;

- (void)qimDB_updateMessageWithMsgId:(NSString *)msgId
                       WithSessionId:(NSString *)sessionId
                            WithFrom:(NSString *)from
                              WithTo:(NSString *)to
                         WithContent:(NSString *)content
                        WithPlatform:(int)platform
                         WithMsgType:(int)msgType
                        WithMsgState:(int)msgState
                    WithMsgDirection:(int)msgDirection
                         WithMsgDate:(long long)msgDate
                       WithReadedTag:(int)readedTag
                        ExtendedFlag:(int)ExtendedFlag;

- (void)qimDB_updateMessageWithMsgId:(NSString *)msgId
                       WithSessionId:(NSString *)sessionId
                            WithFrom:(NSString *)from
                              WithTo:(NSString *)to
                         WithContent:(NSString *)content
                      WithExtendInfo:(NSString *)extendInfo
                        WithPlatform:(int)platform
                         WithMsgType:(int)msgType
                        WithMsgState:(int)msgState
                    WithMsgDirection:(int)msgDirection
                         WithMsgDate:(long long)msgDate
                       WithReadedTag:(int)readedTag
                        ExtendedFlag:(int)ExtendedFlag
                          WithMsgRaw:(NSString *)msgRaw;

- (void)qimDB_revokeMessageByMsgList:(NSArray *)revokeMsglist;

- (void)qimDB_revokeMessageByMsgId:(NSString *)msgId
                       WithContent:(NSString *)content
                       WithMsgType:(int)msgType;

- (void)qimDB_updateMessageWithExtendInfo:(NSString *)extendInfo ForMsgId:(NSString *)msgId;

- (void)qimDB_deleteMessageWithXmppId:(NSString *)xmppId;

- (void)qimDB_deleteMessageByMessageId:(NSString *)messageId ByJid:(NSString *)sid;

- (void)qimDB_updateMessageWithMsgId:(NSString *)msgId
                          WithMsgRaw:(NSString *)msgRaw;

- (void)qimDB_insertMessageWithMsgId:(NSString *)msgId
                          WithXmppId:(NSString *)xmppId
                            WithFrom:(NSString *)from
                              WithTo:(NSString *)to
                         WithContent:(NSString *)content
                      WithExtendInfo:(NSString *)extendInfo
                        WithPlatform:(int)platform
                         WithMsgType:(int)msgType
                        WithMsgState:(int)msgState
                    WithMsgDirection:(int)msgDirection
                         WithMsgDate:(long long)msgDate
                       WithReadedTag:(int)readedTag
                        WithChatType:(NSInteger)chatType;

- (void)qimDB_insertMessageWithMsgId:(NSString *)msgId
                          WithXmppId:(NSString *)xmppId
                            WithFrom:(NSString *)from
                              WithTo:(NSString *)to
                         WithContent:(NSString *)content
                      WithExtendInfo:(NSString *)extendInfo
                        WithPlatform:(int)platform
                         WithMsgType:(int)msgType
                        WithMsgState:(int)msgState
                    WithMsgDirection:(int)msgDirection
                         WithMsgDate:(long long)msgDate
                       WithReadedTag:(int)readedTag
                          WithMsgRaw:(NSString *)msgRaw
                        WithChatType:(NSInteger)chatType;

- (void)qimDB_insertMessageWithMsgId:(NSString *)msgId
                          WithXmppId:(NSString *)xmppId
                            WithFrom:(NSString *)from
                              WithTo:(NSString *)to
                         WithContent:(NSString *)content
                      WithExtendInfo:(NSString *)extendInfo
                        WithPlatform:(int)platform
                         WithMsgType:(int)msgType
                        WithMsgState:(int)msgState
                    WithMsgDirection:(int)msgDirection
                         WithMsgDate:(long long)msgDate
                       WithReadedTag:(int)readedTag
                          WithMsgRaw:(NSString *)msgRaw
                         WithRealJid:(NSString *)realJid
                        WithChatType:(NSInteger)chatType;

- (BOOL)qimDB_checkMsgId:(NSString *)msgId;

- (NSMutableArray *)qimDB_searchLocalMessageByKeyword:(NSString *)keyWord
                                               XmppId:(NSString *)xmppid
                                              RealJid:(NSString *)realJid;

#pragma mark - 插入群JSON消息
- (NSDictionary *)qimDB_bulkInsertIphoneHistoryGroupJSONMsg:(NSArray *)list WithMyNickName:(NSString *)myNickName WithReadMarkT:(long long)readMarkT WithDidReadState:(int)didReadState WithMyRtxId:(NSString *)rtxId WithAtAllMsgList:(NSMutableArray<NSDictionary *> **)atAllMsgList WithNormaleAtMsgList:(NSMutableArray <NSDictionary *> **)normalMsgList;

//群翻页消息
- (NSArray *)qimDB_bulkInsertIphoneMucJSONMsg:(NSArray *)list WithMyNickName:(NSString *)myNickName WithReadMarkT:(long long)readMarkT WithDidReadState:(int)didReadState WithMyRtxId:(NSString *)rtxId;

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

/**
 插入离线单人JSON消息
 
 @param list 消息数组
 @param meJid 自身Id
 @param didReadState 是否已读
 */
#pragma mark - 插入离线单人JSON消息
- (NSMutableDictionary *)qimDB_bulkInsertHistoryChatJSONMsg:(NSArray *)list
                                                         to:(NSString *)meJid
                                           WithDidReadState:(int)didReadState;

- (NSString *)qimDB_getC2BMessageFeedBackWithMsgId:(NSString *)msgId;

#pragma mark - 单人JSON历史消息翻页
- (NSArray *)qimDB_bulkInsertHistoryChatJSONMsg:(NSArray *)list
                                     WithXmppId:(NSString *)xmppId
                               WithDidReadState:(int)didReadState;

- (void)qimDB_bulkInsertMessage:(NSArray *)msgList;

- (void)qimDB_bulkInsertMessage:(NSArray *)msgList WithSessionId:(NSString *)sessionId;

- (void)qimDB_updateMsgState:(int)msgState WithMsgId:(NSString *)msgId;

- (void)qimDB_updateMsgDate:(long long)msgDate WithMsgId:(NSString *)msgId;

// 0 未读 1是读过了
- (void)qimDB_updateMessageReadStateWithMsgId:(NSString *)msgId;

//批量更新消息阅读状态
- (void)qimDB_bulkUpdateMessageReadStateWithMsg:(NSArray *)msgs;

- (long long)qimDB_getReadedTimeStampForUserId:(NSString *)userId WithMsgDirection:(int)msgDirection WithReadedState:(int)readedState;

- (NSArray *)qimDB_getNotReadMsgListForUserId:(NSString *)userId ForRealJid:(NSString *)realJid;

- (NSArray *)qimDB_getNotReadMsgListForUserId:(NSString *)userId;

- (NSArray *)qimDB_getMgsListBySessionId:(NSString *)sesId;

- (void)updateMsgsContent:(NSString *)content ByMsgId:(NSString *)msgId;

- (NSDictionary *)qimDB_getMsgsByMsgId:(NSString *)msgId;

- (NSArray *)qimDB_getMsgsByMsgType:(NSArray *)msgTypes ByXmppId:(NSString *)xmppId ByReadJid:(NSString *)realJid;

- (NSArray *)qimDB_getMsgsByMsgType:(int)msgType ByXmppId:(NSString *)xmppId;

- (NSArray *)qimDB_getMsgsByMsgType:(int)msgType;

- (NSArray *)qimDB_getMgsListBySessionId:(NSString *)sesId WithRealJid:(NSString *)realJid WithLimit:(int)limit WithOffset:(int)offset;

- (NSArray *)qimDB_getMsgListByXmppId:(NSString *)xmppId WithRealJid:(NSString *)realJid FromTimeStamp:(long long)timeStamp;

- (NSArray *)qimDB_getMsgListByXmppId:(NSString *)xmppId FromTimeStamp:(long long)timeStamp;

- (NSInteger)qimDB_getNotReaderMsgCountByDidReadState:(int)didReadState WidthReceiveDirection:(int)receiveDirection;

- (NSInteger)qimDB_getNotReaderMsgCountByJid:(NSString *)jid ByRealJid:(NSString *)realJid withChatType:(ChatType)chatType;

- (NSInteger)qimDB_getNotReaderMsgCountByJid:(NSString *)jid ByDidReadState:(int)didReadState WidthReceiveDirection:(int)receiveDirection;

- (NSInteger)qimDB_getNotReaderMsgCountByJid:(NSString *)jid ByRealJid:(NSString *)realJid ByDidReadState:(int)didReadState WidthReceiveDirection:(int)receiveDirection;

- (void)qimDB_updateMessageFromState:(int)fState ToState:(int)tState;

- (NSInteger)qimDB_getMessageStateWithMsgId:(NSString *)msgId;

- (NSArray *)qimDB_getMsgIdsForDirection:(int)msgDirection WithMsgState:(int)msgState;

- (NSArray *)qimDB_getMsgIdsByMsgState:(int)notReadMsgState WithDirection:(int)receiveDirection;

- (void)qimDB_updateMsgIdToDidreadForNotReadMsgIdList:(NSArray *)notReadList AndSourceMsgIdList:(NSArray *)sourceMsgIdList WithDidReadState:(int)didReadState;

- (NSArray *)qimDB_searchMsgHistoryWithKey:(NSString *)key;

- (NSArray *)qimDB_searchMsgIdWithKey:(NSString *)key ByXmppId:(NSString *)xmppId;

#pragma mark - 消息数据方法

- (long long)qimDB_lastestMessageTimeWithNotMessageState:(long long) messageState;

- (NSString *)qimDB_getLastMsgIdByJid:(NSString *)jid;

- (long long)qimDB_getMsgTimeWithMsgId:(NSString *)msgId;

- (long long)qimDB_getLastMsgTimeIdByJid:(NSString *)jid;

- (long long)qimDB_lastestMessageTime;

- (long long)qimDB_lastestSystemMessageTime;

- (long long)qimDB_bulkUpdateGroupMessageReadFlag:(NSArray *)mucArray;

- (void)qimDB_bulkUpdateChatMsgWithMsgState:(int)msgState ByMsgIdList:(NSArray *)msgIdList;

- (void)qimDB_clearHistoryMsg;

- (void)qimDB_updateSystemMsgState:(int)msgState WithXmppId:(NSString *)xmppId;

- (void)qimDB_updateAllMsgWithMsgState:(int)msgState ByMsgDirection:(int)msgDirection ByReadMarkT:(long long)readMarkT;


#pragma mark - 阅读状态

- (NSArray *)qimDB_getReceiveMsgIdListWithMsgReadFlag:(QIMMessageRemoteReadState)remoteReadState withChatType:(ChatType)chatType withMsgDirection:(QIMMessageDirection)receiveDirection;

- (void)qimDB_updateAllMsgWithMsgRemoteState:(NSInteger)msgRemoteFlag ByMsgDirection:(int)msgDirection ByReadMarkT:(long long)readMarkT;

- (void)qimDB_updateGroupMessageRemoteState:(NSInteger)msgRemoteFlag ByGroupReadList:(NSArray *)groupReadList;

- (void)qimDB_updateMsgWithMsgRemoteState:(NSInteger)msgRemoteFlag ByMsgIdList:(NSArray *)msgIdList;

#pragma mark - 本地消息搜索

- (NSArray *)qimDB_getLocalMediaByXmppId:(NSString *)xmppId ByReadJid:(NSString *)realJid;

- (NSArray *)qimDB_getMsgsByKeyWord:(NSString *)keywords ByXmppId:(NSString *)xmppId ByReadJid:(NSString *)realJid;

@end

NS_ASSUME_NONNULL_END
