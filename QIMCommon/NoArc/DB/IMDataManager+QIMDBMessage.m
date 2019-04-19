//
//  IMDataManager+QIMDBMessage.m
//  QIMCommon
//
//  Created by 李露 on 11/24/18.
//  Copyright © 2018 QIM. All rights reserved.
//

#import "IMDataManager+QIMDBMessage.h"
#import "Database.h"

@implementation IMDataManager (QIMDBMessage)

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        QIMVerboseLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

#pragma mark - 获取消息时间戳

- (long long)qimDB_lastestMessageTime {
    __block long long maxRemoteTime = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *newSql = @"select valueInt from IM_Cache_Data Where key == 'singlelastupdatetime' and type == 10";
        DataReader *newReader = [database executeReader:newSql withParameters:nil];
        if ([newReader read]) {
            maxRemoteTime = [[newReader objectForColumnIndex:0] longLongValue];
        }
    }];
    QIMVerboseLog(@"");
    return maxRemoteTime;
}

- (long long)qimDB_lastestGroupMessageTime {
    __block long long maxRemoteTimeStamp = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *newSql = @"select valueInt from IM_Cache_Data Where key == 'grouplastupdatetime' and type == 10;";
        DataReader *newReader = [database executeReader:newSql withParameters:nil];
        if ([newReader read]) {
            maxRemoteTimeStamp = [[newReader objectForColumnIndex:0] longLongValue];
        }
    }];
    QIMVerboseLog(@"");
    return maxRemoteTimeStamp;
}

- (long long)qimDB_lastestSystemMessageTime {
    
    __block long long maxRemoteTime = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *newSql = @"select valueInt from IM_Cache_Data Where key == 'systemlastupdatetime' and type == 10";
        DataReader *newReader = [database executeReader:newSql withParameters:nil];
        if ([newReader read]) {
            maxRemoteTime = [[newReader objectForColumnIndex:0] longLongValue];
        }
    }];
    QIMVerboseLog(@"");
    return maxRemoteTime;
}

- (void)qimDB_updateMsgTimeToMillSecond {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"UpdateMsgTimeToMillSecond"] == nil) {
        [[self dbInstance] syncUsingTransaction:^(Database *database) {
            NSString *sql = @"Update IM_Message Set LastUpdateTime = LastUpdateTime * 1000 Where LastUpdateTime < 140000000000;";
            [database executeNonQuery:sql withParameters:nil];
            NSString *sql1 = @"Update IM_Public_Number_Message Set LastUpdateTime = LastUpdateTime * 1000 Where LastUpdateTime < 140000000000;";
            [database executeNonQuery:sql1 withParameters:nil];
        }];
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"UpdateMsgTimeToMillSecond"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    QIMVerboseLog(@"");
}

- (long long)qimDB_getMinMsgTimeStampByXmppId:(NSString *)xmppId RealJid:(NSString *)realJid {
    __block long long timeStamp = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select min(LastUpdateTime) From IM_Message Where XmppId = :XmppId And RealJid = :RealJid;";
        DataReader *reader = [database executeReader:sql withParameters:@[xmppId, realJid]];
        if ([reader read]) {
            id value = [reader objectForColumnIndex:0];
            if (value) {
                timeStamp = floor([value doubleValue]);
            } else {
                timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
            }
        } else {
            timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        }
    }];
    QIMVerboseLog(@"");
    return timeStamp;
}

- (long long)qimDB_getMinMsgTimeStampByXmppId:(NSString *)xmppId {
    __block long long timeStamp = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select min(LastUpdateTime) From IM_Message Where XmppId = :XmppId;";
        DataReader *reader = [database executeReader:sql withParameters:@[xmppId]];
        if ([reader read]) {
            id value = [reader objectForColumnIndex:0];
            if (value) {
                timeStamp = floor([value doubleValue]);
            } else {
                timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
            }
        } else {
            timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
        }
    }];
    QIMVerboseLog(@"");
    return timeStamp;
}

- (long long)qimDB_getMaxMsgTimeStampByXmppId:(NSString *)xmppId {
    __block long long timeStamp = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select max(LastUpdateTime) From IM_Message Where XmppId = :XmppId;";
        DataReader *reader = [database executeReader:sql withParameters:@[xmppId]];
        if ([reader read]) {
            timeStamp = ceil([[reader objectForColumnIndex:0] doubleValue]);
        }
    }];
    QIMVerboseLog(@"");
    return timeStamp;
}

- (long long)qimDB_getMaxMsgTimeStampByXmppId:(NSString *)xmppId ByRealJid:(NSString *)realJid {
    __block long long timeStamp = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select max(LastUpdateTime) From IM_Message Where XmppId = :XmppId and RealJid = :RealJid;";
        DataReader *reader = [database executeReader:sql withParameters:@[xmppId, realJid]];
        if ([reader read]) {
            timeStamp = ceil([[reader objectForColumnIndex:0] doubleValue]);
        }
    }];
    QIMVerboseLog(@"");
    return timeStamp;
}

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
                        ExtendedFlag:(int)ExtendedFlag {
    [self qimDB_updateMessageWithMsgId:msgId WithSessionId:sessionId WithFrom:from WithTo:to WithContent:content WithPlatform:platform WithMsgType:msgType WithMsgState:msgState WithMsgDirection:msgDirection WithMsgDate:msgDate WithReadedTag:readedTag ExtendedFlag:ExtendedFlag WithMsgRaw:nil];
}


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
                          WithMsgRaw:(NSString *)msgRaw {
    
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set XmppId=:XmppId, \"From\"=:from, \"To\"=:to, Content=:content, ExtendInfo=:ExtendInfo, Platform=:platform, Type=:type, State=:state, Direction=:Direction,LastUpdateTime=:LastUpdateTime,ReadState=:ReadState,ExtendedFlag=:ExtendedFlag,MessageRaw=:MessageRaw Where MsgId=:MsgId;";
        NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
        [param addObject:sessionId];
        [param addObject:from?from:@":NULL"];
        [param addObject:to?to:@":NULL"];
        [param addObject:content?content:@":NULL"];
        [param addObject:extendInfo?extendInfo:@":NULL"];
        [param addObject:[NSNumber numberWithInt:platform]];
        [param addObject:[NSNumber numberWithInt:msgType]];
        [param addObject:[NSNumber numberWithInt:msgState]];
        [param addObject:[NSNumber numberWithInt:msgDirection]];
        [param addObject:[NSNumber numberWithLongLong:msgDate]];
        [param addObject:[NSNumber numberWithInt:0]];
        [param addObject:[NSNumber numberWithInt:ExtendedFlag]];
        [param addObject:msgRaw?msgRaw:@":NULL"];
        [param addObject:msgId];
        [database executeNonQuery:sql withParameters:param];
        [param release];
        param = nil;
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_revokeMessageByMsgList:(NSArray *)revokeMsglist {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set Content = :content, Type = :type Where MsgId=:MsgId;";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *subItem in revokeMsglist) {
            NSString *msgId = [subItem objectForKey:@"messageId"];
            NSString *content = [subItem objectForKey:@"message"];
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:content];
            [param addObject:@(-1)];
            [param addObject:msgId];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_revokeMessageByMsgId:(NSString *)msgId
                       WithContent:(NSString *)content
                       WithMsgType:(int)msgType {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set Content=:content,Type=:type Where MsgId=:MsgId;";
        NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:3];
        [param addObject:content];
        [param addObject:@(msgType)];
        [param addObject:msgId];
        [database executeNonQuery:sql withParameters:param];
        [param release];
        param = nil;
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_updateMessageWithExtendInfo:(NSString *)extendInfo ForMsgId:(NSString *)msgId {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set ExtendedFlag=:ExtendedFlag Where MsgId=:MsgId;";
        [database executeNonQuery:sql withParameters:@[extendInfo,msgId]];
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_deleteMessageWithXmppId:(NSString *)xmppId {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Delete From IM_Message Where XmppId=:XmppId;";
        [database executeNonQuery:sql withParameters:@[xmppId]];
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_deleteMessageByMessageId:(NSString *)messageId ByJid:(NSString *)sid {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Delete From IM_Message Where MsgId=:MsgId;";
        [database executeNonQuery:sql withParameters:@[messageId]];
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_updateMessageWithMsgId:(NSString *)msgId
                          WithMsgRaw:(NSString *)msgRaw {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set MessageRaw=:MessageRaw Where MsgId=:MsgId;";
        NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
        [param addObject:msgRaw?msgRaw:@":NULL"];
        [param addObject:msgId];
        [database executeNonQuery:sql withParameters:param];
        [param release];
        param = nil;
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_insertMessageWithMsgDic:(NSDictionary *)msgDic {
    /*
     {
     MessageBody = "\U5b9d\U8d1d";
     MessageExtendInfo = "";
     MessageId = D2F571119EFD4D0F89A0F2BDA8B646FE;
     MessageType = 1;
     ToJid = "lilulucas.li@ejabhost1";
     chatType = 0;
     from = "qtalktest@ejabhost1";
     messageDate = 1551759518215;
     messageDirection = 1;
     messageReadState = 1;
     messageSendState = 2;
     originChatType = 0;
     platform = 0;
     readTag = 0;
     realJid = "qtalktest@ejabhost1";
     remoteReadState = 0;
     version = 0;
     }
     */
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"insert or IGNORE into IM_Message(MsgId, XmppId, \"From\", \"To\", Content, ExtendInfo, Platform, Type, ChatType, State, Direction,LastUpdateTime,ReadState,ExtendedFlag,MessageRaw,RealJid) values(:MsgId, :XmppId, :From, :To, :Content, :ExtendInfo, :Platform, :Type, :ChatType, :State, :Direction, :LastUpdateTime, :ReadState,:ExtendedFlag,:MessageRaw,:RealJid);";
        NSString *msgId = [msgDic objectForKey:@"MessageId"];
        NSString *xmppId = [msgDic objectForKey:@"xmppId"];
        NSString *from = [msgDic objectForKey:@"from"];
        NSString *to = [msgDic objectForKey:@"ToJid"];
        NSString *content = [msgDic objectForKey:@"MessageBody"];
        NSString *extendInfo = [msgDic objectForKey:@"MessageExtendInfo"];
        IMPlatform platform = [[msgDic objectForKey:@"platform"] integerValue];
        QIMMessageType msgType = [[msgDic objectForKey:@"MessageType"] integerValue];
        ChatType chatType = [[msgDic objectForKey:@"chatType"] integerValue];
        QIMMessageSendState msgState = [[msgDic objectForKey:@"messageSendState"] integerValue];
        QIMMessageDirection msgDirection = [[msgDic objectForKey:@"messageDirection"] integerValue];
        long long msgDate = [[msgDic objectForKey:@"messageDate"] longLongValue];
        id msgRaw = [msgDic objectForKey:@""];
        NSString *realJid = [msgDic objectForKey:@"realJid"];
        QIMMessageRemoteReadState readState = [[msgDic objectForKey:@"messageReadState"] integerValue];
        
        NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
        [param addObject:msgId?msgId:@":NULL"];
        [param addObject:xmppId?xmppId:@":NULL"];
        [param addObject:from?from:@":NULL"];
        [param addObject:to?to:@":NULL"];
        [param addObject:content?content:@":NULL"];
        [param addObject:extendInfo?extendInfo:@":NULL"];
        [param addObject:[NSNumber numberWithInt:platform]];
        [param addObject:[NSNumber numberWithInt:msgType]];
        [param addObject:[NSNumber numberWithInteger:chatType]];
        [param addObject:[NSNumber numberWithInt:msgState]];
        [param addObject:[NSNumber numberWithInt:msgDirection]];
        [param addObject:[NSNumber numberWithLongLong:msgDate]];
        [param addObject:[NSNumber numberWithLongLong:readState]];
        [param addObject:[NSNumber numberWithInt:0]];
        [param addObject:msgRaw?msgRaw:@":NULL"];
        [param addObject:realJid?realJid:@":NULL"];
        [database executeNonQuery:sql withParameters:param];
        [param release];
        param = nil;
    }];
    QIMVerboseLog(@"");
}

- (BOOL)qimDB_checkMsgId:(NSString *)msgId{
    __block BOOL flag = NO;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select 1 From IM_Message Where MsgId = :MsgId;";
        DataReader *reader = [database executeReader:sql withParameters:@[msgId]];
        if ([reader read]) {
            flag = YES;
        }
    }];
    QIMVerboseLog(@"");
    return flag;
}

- (NSMutableArray *)qimDB_searchLocalMessageByKeyword:(NSString *)keyWord
                                               XmppId:(NSString *)xmppid
                                              RealJid:(NSString *)realJid {
    __block NSMutableArray *resultList = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"select a.'From',a.Content,a.LastUpdateTime,b.Name,b.HeaderSrc,a.MsgId from IM_Message as a left join IM_Users as b on a.'from' = b.Xmppid  where a.Content like '%%%@%%' and a.XmppId = '%@'  ORDER by a.LastUpdateTime desc limit 1000;",keyWord,xmppid];
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            
            if (resultList == nil) {
                resultList = [[NSMutableArray alloc] init];
            }
            
            NSString *from = [reader objectForColumnIndex:0];
            double time = [[reader objectForColumnIndex:2]doubleValue];
            NSString *content = [reader objectForColumnIndex:1];
            NSString *nickName = [reader objectForColumnIndex:3];
            NSString *headUrl = [reader objectForColumnIndex:4];
            NSString *msgId = [reader objectForColumnIndex:5];
 
            NSString *date = [[NSDate qim_dateWithTimeIntervalInMilliSecondSince1970:time] qim_formattedDateDescription];
            NSMutableDictionary *value = [[NSMutableDictionary alloc] init];
            [IMDataManager safeSaveForDic:value setObject:from forKey:@"from"];
            [IMDataManager safeSaveForDic:value setObject:date forKey:@"time"];
            [IMDataManager safeSaveForDic:value setObject:@(time) forKey:@"timeLong"];
            [IMDataManager safeSaveForDic:value setObject:content forKey:@"content"];
            [IMDataManager safeSaveForDic:value setObject:nickName forKey:@"nickName"];
            [IMDataManager safeSaveForDic:value setObject:headUrl forKey:@"headerUrl"];
            [IMDataManager safeSaveForDic:value setObject:msgId forKey:@"msgId"];
            [resultList addObject:value];
            [value release];
            value = nil;
        }
    }];
    QIMVerboseLog(@"");
    return [resultList autorelease];
}

#pragma mark - 插入群JSON消息
- (long long)qimDB_bulkInsertIphoneHistoryGroupJSONMsg:(NSArray *)list WithAtAllMsgList:(NSMutableArray<NSDictionary *> **)atAllMsgList WithNormaleAtMsgList:(NSMutableArray <NSDictionary *> **)normalMsgList {
    
    QIMVerboseLog(@"群消息插入本地数据库数量 : %lld", list.count);
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    NSMutableDictionary *groupMsgTimeDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *msgList = [[NSMutableArray alloc] init];
    
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *updateMsgList = [[NSMutableArray alloc] init];
    if (!*normalMsgList) {
        *normalMsgList = [[NSMutableArray alloc] init];
    }
    if (!*atAllMsgList) {
        *atAllMsgList = [[NSMutableArray alloc] init];
    }
    for (NSDictionary *dic in list) {
        
        NSDictionary *message = [dic objectForKey:@"message"];
        NSDictionary *msgBody = [dic objectForKey:@"body"];
        if (msgBody) {
            int platform = 0;
            int msgType = [[msgBody objectForKey:@"msgType"] intValue];
            NSString *extendInfo = [msgBody objectForKey:@"extendInfo"];
            
            //红包消息详情，AA收款详情
            if (msgType == 1024 || msgType == 1025) {
                NSDictionary *infoDic = [self dictionaryWithJsonString:extendInfo];
                NSString *fId = [infoDic objectForKey:@"From_User"];
                NSString *openId = [infoDic objectForKey:@"Open_User"];
                
                if ([fId isEqualToString:[self getDbOwnerFullJid]] == NO || [openId isEqualToString:[self getDbOwnerFullJid]] == NO) {
                    continue;
                }
            }
            NSString *msgId = [msgBody objectForKey:@"id"];
            NSString *msg = [msgBody objectForKey:@"content"];
            if (msgType == -1) {
                //撤销消息
                [updateMsgList addObject:@{@"messageId":msgId?msgId:@"", @"message":msg?msg:@"该消息被撤回"}];
            }
            NSString *xmppId = [message objectForKey:@"to"];
            NSString *sendJid = [message objectForKey:@"sendjid"];
            NSString *compensateJid = [message objectForKey:@"from"];
            //默认取sendJid，revoke特殊一些，补偿取from
            compensateJid = (sendJid.length > 0) ? sendJid : compensateJid;
            long long msec_times = [[dic objectForKey:@"t"] doubleValue] * 1000;
            NSDate *date = nil;
            if (msec_times > 0) {
                
            } else {
                msec_times = [[message objectForKey:@"msec_times"] longLongValue];
            }
            date = [NSDate dateWithTimeIntervalSince1970:msec_times / 1000.0];
            if (date == nil) {
                date = [NSDate date];
            }
            platform = [self qimDB_parserplatForm:[message objectForKey:@"client_type"]];
            long long lastGroupMsgDate = [[groupMsgTimeDic objectForKey:xmppId] longLongValue];
            if (lastGroupMsgDate < date.timeIntervalSince1970 - 60 * 2) {
                lastGroupMsgDate = date.timeIntervalSince1970;
                [groupMsgTimeDic setObject:@(lastGroupMsgDate) forKey:xmppId];
                NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
                [msgDic setObject:[self qimDB_getTimeSmtapMsgIdForDate:date WithUserId:xmppId] forKey:@"MsgId"];
                [msgDic setObject:xmppId forKey:@"SessionId"];
                [msgDic setObject:xmppId forKey:@"RealJid"];
                [msgDic setObject:@(101) forKey:@"MsgType"];
                [msgDic setObject:@(platform) forKey:@"Platform"];
                [msgDic setObject:@(QIMMessageDirection_Sent) forKey:@"MsgDirection"];
                [msgDic setObject:@(msec_times-1) forKey:@"MsgDateTime"];
                [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
                [msgDic setObject:@(QIMMessageRemoteReadStateGroupReaded|QIMMessageRemoteReadStateDidReaded) forKey:@"ReadState"];
                [msgDic setObject:@(ChatType_GroupChat) forKey:@"ChatType"];
                [msgList addObject:msgDic];
            }
            if (msgId == nil) {
                msgId = [date description];
            }
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            [msgDic setObject:msgId forKey:@"MsgId"];
            [msgDic setObject:xmppId forKey:@"SessionId"];
            [msgDic setObject:compensateJid?compensateJid:@"" forKey:@"From"];
            [msgDic setObject:xmppId forKey:@"RealJid"];
            [msgDic setObject:[self getDbOwnerFullJid]?[self getDbOwnerFullJid]:@"" forKey:@"To"];
            [msgDic setObject:msg?msg:@"" forKey:@"Content"];
            [msgDic setObject:extendInfo?extendInfo:@"" forKey:@"ExtendInfo"];
            [msgDic setObject:@(platform) forKey:@"Platform"];
            int direction = ([[self getDbOwnerFullJid] isEqualToString:compensateJid]) ? 0 : 1;
            [msgDic setObject:@(direction) forKey:@"MsgDirection"];
            [msgDic setObject:@(msgType) forKey:@"MsgType"];
            [msgDic setObject:@(msec_times) forKey:@"MsgDateTime"];
            [msgDic setObject:@(ChatType_GroupChat) forKey:@"ChatType"];
            [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
            [msgDic setObject:@(QIMMessageRemoteReadStateDidSent) forKey:@"ReadState"];
            NSData *xmlData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
            [msgDic setObject:xml?xml:@"" forKey:@"MsgRaw"];
            [msgList addObject:msgDic];
            [resultDic setObject:msgDic forKey:xmppId];
            
            if (direction == 1) {
                if ([msg rangeOfString:@"@"].location != NSNotFound) {
                    NSArray *array = [msg componentsSeparatedByString:@"@"];
                    BOOL hasAt = NO;
                    BOOL hasAtAll = NO;
                    for (NSString *str in array) {
                        if ([[str lowercaseString] hasPrefix:@"all"] || [str hasPrefix:@"全体成员"]) {
                            hasAtAll = YES;
                            break;
                        }
                        NSString *prefix = [self getDbOwnerFullJid];
                        if (prefix && [str hasPrefix:prefix]) {
                            hasAt = YES;
                            break;
                        }
                    }
                    if (hasAtAll) {
                        [*atAllMsgList addObject:msgDic];
                    }
                    if (hasAt) {
                        [*normalMsgList addObject:msgDic];
                    }
                    [msgDic release];
                    msgDic = nil;
                }
            }
        }
    }
    long long lastTime = [self qimDB_insertGroupSessionWithMsgList:resultDic];
    [self qimDB_bulkInsertMessage:msgList];
    if (updateMsgList.count > 0) {
        [self qimDB_revokeMessageByMsgList:updateMsgList];
    }
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    QIMVerboseLog(@"插入群消息历史记录%ld条，耗时%fs", msgList.count, end - start); //s
    [resultDic autorelease];
    QIMVerboseLog(@"");
    return lastTime;
}

//群翻页消息
- (NSArray *)qimDB_bulkInsertIphoneMucPageJSONMsg:(NSArray *)list {
    
    NSMutableArray *msgList = [[NSMutableArray alloc] init];
    NSMutableArray *updateMsgList = [[NSMutableArray alloc] init];
    long long lastGroupMsgDate = 0;
    for (NSDictionary *dic in list) {
        
        NSDictionary *message = [dic objectForKey:@"message"];
        NSDictionary *msgBody = [dic objectForKey:@"body"];
        if (msgBody) {
            int platform = 0;
            int msgType = [[msgBody objectForKey:@"msgType"] intValue];
            NSString *extendInfo = [msgBody objectForKey:@"extendInfo"];
            if (msgType == 1024 || msgType == 1025) {
                NSDictionary *infoDic = [self dictionaryWithJsonString:extendInfo];
                NSString *fId = [infoDic objectForKey:@"From_User"];
                NSString *openId = [infoDic objectForKey:@"Open_User"];
                
                if ([fId isEqualToString:[self getDbOwnerFullJid]] == NO || [openId isEqualToString:[self getDbOwnerFullJid]] == NO) {
                    continue;
                }
            }
            NSString *sendJid = [message objectForKey:@"sendjid"];
            NSString *compensateJid = [message objectForKey:@"from"];
            compensateJid = (sendJid.length > 0) ? sendJid : compensateJid;
            NSString *msgId = [msgBody objectForKey:@"id"];
            NSString *msg = [msgBody objectForKey:@"content"];
            if (msgType == -1) {
                //撤销消息
                [updateMsgList addObject:@{@"messageId":msgId?msgId:@"", @"message":msg?msg:@"该消息被撤回"}];
            }
            //翻页消息Check下
            if ([self qimDB_checkMsgId:msgId]) {
                continue;
            }
            NSString *xmppId = [message objectForKey:@"to"];
            long long msec_times = [[dic objectForKey:@"t"] doubleValue] * 1000;
            NSDate *date = nil;
            if (msec_times > 0) {
                
            } else {
                msec_times = [[message objectForKey:@"msec_times"] longLongValue];
            }
            date = [NSDate dateWithTimeIntervalSince1970:msec_times / 1000.0];
            if (date == nil) {
                date = [NSDate date];
            }
            platform = [self qimDB_parserplatForm:[message objectForKey:@"client_type"]];
            
            if (lastGroupMsgDate < date.timeIntervalSince1970 - 60 * 2) {
                lastGroupMsgDate = date.timeIntervalSince1970;
                NSMutableDictionary *msgDic = [NSMutableDictionary dictionary];
                [msgDic setObject:[self qimDB_getTimeSmtapMsgIdForDate:date WithUserId:xmppId] forKey:@"MsgId"];
                [msgDic setObject:xmppId forKey:@"SessionId"];
                [msgDic setObject:xmppId forKey:@"RealJid"];
                [msgDic setObject:@(101) forKey:@"MsgType"];
                [msgDic setObject:@(platform) forKey:@"Platform"];
                [msgDic setObject:@(QIMMessageDirection_Sent) forKey:@"MsgDirection"];
                [msgDic setObject:@(msec_times-1) forKey:@"MsgDateTime"];
                [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
                [msgDic setObject:@(QIMMessageRemoteReadStateGroupReaded|QIMMessageRemoteReadStateDidReaded) forKey:@"ReadState"];
                [msgDic setObject:@(ChatType_GroupChat) forKey:@"ChatType"];
                [msgList addObject:msgDic];
            }
            if (msgId == nil) {
                msgId = [date description];
            }
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            [msgDic setObject:msgId forKey:@"MsgId"];
            [msgDic setObject:xmppId forKey:@"SessionId"];
            [msgDic setObject:xmppId forKey:@"RealJid"];
            [msgDic setObject:compensateJid?compensateJid:@"" forKey:@"From"];
            [msgDic setObject:[self getDbOwnerFullJid]?[self getDbOwnerFullJid]:@"" forKey:@"To"];
            [msgDic setObject:msg?msg:@"" forKey:@"Content"];
            [msgDic setObject:extendInfo?extendInfo:@"" forKey:@"ExtendInfo"];
            [msgDic setObject:@(platform) forKey:@"Platform"];
            int direction = ([compensateJid isEqualToString:[self getDbOwnerFullJid]]) ? 0 : 1;
            [msgDic setObject:@(direction) forKey:@"MsgDirection"];
            [msgDic setObject:@(msgType) forKey:@"MsgType"];
            [msgDic setObject:@(msec_times) forKey:@"MsgDateTime"];
            [msgDic setObject:@(ChatType_GroupChat) forKey:@"ChatType"];
            [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
            [msgDic setObject:@(QIMMessageRemoteReadStateGroupReaded) forKey:@"ReadState"];
            NSData *xmlData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
            [msgDic setObject:xml?xml:@"" forKey:@"MsgRaw"];
            [msgList addObject:msgDic];
        }
    }
    [self qimDB_bulkInsertMessage:msgList];
    if (updateMsgList.count > 0) {
        [self qimDB_revokeMessageByMsgList:updateMsgList];
    }
    QIMVerboseLog(@"");
    return [msgList autorelease];
}

/**
 插入离线单人JSON消息
 
 @param list 消息数组
 @param meJid 自身Id
 @param didReadState 是否已读
 */
#pragma mark - 插入离线单人JSON消息
- (long long)qimDB_bulkInsertHistoryChatJSONMsg:(NSArray *)list {
    QIMVerboseLog(@"插入离线单人JSON消息数量 : %lu", (unsigned long)list.count);
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *updateMsgList = [[NSMutableArray alloc] init];
    NSMutableArray *insertMsgList = [[NSMutableArray alloc] init];
    NSMutableArray *collectionOriginMsgList = [[NSMutableArray alloc] init];
    for (NSDictionary *dic in list) {
        NSMutableDictionary *result = nil;
        NSString *key = nil;
        NSMutableArray *msgList = nil;
        long long lastDate = 0;
        NSString *realJid = nil;
        NSString *userId = nil;
        
        NSString *from = [dic objectForKey:@"from"];
        NSString *fromDomain = [dic objectForKey:@"from_host"];
        NSString *fromJid = [from stringByAppendingFormat:@"@%@", fromDomain ? fromDomain : [self getDBOwnerDomain]];
        NSString *to = [dic objectForKey:@"to"];
        NSString *toDomain = [dic objectForKey:@"to_host"];
        NSString *toJid = [to stringByAppendingFormat:@"@%@", toDomain ? toDomain : [self getDBOwnerDomain]];
        NSDictionary *message = [dic objectForKey:@"message"];
        
        
        NSString *type = nil;
        NSString *client_type = nil;
        ChatType chatType = ChatType_SingleChat;
        if (message) {
            type = [message objectForKey:@"type"];
            client_type = [message objectForKey:@"client_type"];
        }
        if ([type isEqualToString:@"headline"]) {
            from = @"SystemMessage";
            chatType = ChatType_System;
            fromJid = [from stringByAppendingFormat:@"@%@", fromDomain?fromDomain:[self getDBOwnerDomain]];
        }
        NSDictionary *msgBody = [dic objectForKey:@"body"];
        if (msgBody != nil) {
            
            NSString *extendInfo = [msgBody objectForKey:@"extendInfo"];
            int msgType = [[msgBody objectForKey:@"msgType"] intValue];
            
            //Message
            NSString *msgId = [msgBody objectForKey:@"id"];
            NSString *chatId = [message objectForKey:@"qchatid"];
            if (chatId == nil) {
                chatId = [message objectForKey:@"chatid"];
            }
            if (chatId == nil) {
                chatId = @"4";
            }
            NSInteger platForm = [self qimDB_parserplatForm:client_type];
            BOOL isConsult = NO;
            if (msgId == nil) {
                msgId = [self UUID];
            }
            NSString *msg = [msgBody objectForKey:@"content"];
            NSString *channelInfo = [message objectForKey:@"channelInfo"];
            
            if ([type isEqualToString:@"revoke"]) {
                [updateMsgList addObject:@{@"messageId":msgId?msgId:@"", @"message":msg?msg:@"该消息已被撤回"}];
            } else if ([type isEqualToString:@"collection"]) {
                
                NSString *originFrom = [message objectForKey:@"originfrom"];
                NSString *originTo = [message objectForKey:@"originto"];
                NSString *originType = [message objectForKey:@"origintype"];
                NSDictionary *originMessageDict = @{@"Originfrom":originFrom?originFrom:originFrom, @"Originto":originTo?originTo:@"", @"Origintype":originType?originType:@"chat", @"MsgId":msgId?msgId:@""};
                [collectionOriginMsgList addObject:originMessageDict];
            } else {
                
            }
            
            if (msgType == 1024) {
                chatId = @"4";
            } else if (msgType == 1002) {
                chatId = @"4";
            }
            
            if ([type isEqualToString:@"note"]) {
                msgType = -11;
            } else if ([type isEqualToString:@"consult"]) {
                isConsult = YES;
            }else if (![type isEqualToString:@"chat"] && ![type isEqualToString:@"revoke"] && ![type isEqualToString:@"subscription"] && ![type isEqualToString:@"headline"] && ![type isEqualToString:@"collection"]){
                continue;
            }
            
            // 初始化缓存结构
            int direction = 0;
            if ([fromJid isEqualToString:[self getDbOwnerFullJid]]) {
                if (isConsult) {
                    NSString *realTo = [message objectForKey:@"realto"];
                    // 自己发的
                    realJid = [realTo componentsSeparatedByString:@"/"].firstObject;
                    if (chatId.intValue == 4) {
                        key = [[NSString stringWithFormat:@"%@-%@",toJid,toJid] retain];
                    } else {
                        key = [[NSString stringWithFormat:@"%@-%@",toJid,realJid] retain];
                    }
                    userId = toJid;
                } else {
                    key = [toJid retain];
                }
                direction = 0;
                result = [[resultDic objectForKey:key] retain];
                if (result == nil) {
                    result = [[NSMutableDictionary alloc] init];
                    if (key) {
                        [resultDic setObject:result forKey:key];
                    }
                }
                if (msgType == 1003 || msgType == 1004) {
                    continue;
                } else if (msgType == 1004) {
                    chatId = @"5";
                } else if (msgType == 1002) {
                    chatId = @"5";
                    NSString *content = extendInfo.length > 0?extendInfo:msg;
                    NSDictionary *contentDic = [self dictionaryWithJsonString:content];
                    realJid = [contentDic objectForKey:@"u"];
                }
            } else {
                direction = 1;
                if (isConsult) {
                    NSString *realfrom = [message objectForKey:@"realfrom"];
                    // 自己收的
                    if (msgType == 1004) {
                        NSString *content = extendInfo.length>0?extendInfo:msg;
                        NSDictionary *infoDic = [self dictionaryWithJsonString:content];
                        realJid = [infoDic objectForKey:@"u"];
                    } else {
                        realJid = [realfrom componentsSeparatedByString:@"/"].firstObject;
                    }
                    if (chatId.intValue == 4) {
                        key = [[NSString stringWithFormat:@"%@-%@",fromJid,realJid] retain];
                    } else {
                        key = [[NSString stringWithFormat:@"%@-%@",fromJid,fromJid] retain];
                    }
                    userId = fromJid;
                } else {
                    key = [fromJid retain];
                }
                result = [[resultDic objectForKey:key] retain];
                if (result == nil) {
                    result = [[NSMutableDictionary alloc] init];
                    if (key) {
                        [resultDic setObject:result forKey:key];
                    }
                }
                if (msgType == 1004) {
                    // 转移会话给同事的回馈 但是 显示位置不应该在两个同事之间的会话 所以换from 并且 去除 多点登陆时候的产生的多余消息
                    chatId = @"4";
                    NSString *content = extendInfo.length > 0?extendInfo:msg;
                    NSDictionary *contentDic = [self dictionaryWithJsonString:content];
                    realJid = [contentDic objectForKey:@"u"];
                } else if (msgType == 1002) {
                    chatId = @"4";
                    NSString *content = extendInfo.length > 0?extendInfo:msg;
                    NSDictionary *contentDic = [self dictionaryWithJsonString:content];
                    realJid = [contentDic objectForKey:@"u"];
                    continue;
                }
            }
            lastDate = [[result objectForKey:@"lastDate"] longLongValue];
            msgList = [[result objectForKey:@"msgList"] retain];
            if (msgList == nil) {
                msgList = [[NSMutableArray alloc] initWithCapacity:100];
            }
            
            NSDate *date = nil;
            long long msecTime = [[dic objectForKey:@"t"] doubleValue] * 1000.0;
            if (msecTime > 0) {
                date = [NSDate dateWithTimeIntervalSince1970:msecTime / 1000.0];
            } else {
                msecTime = [[message objectForKey:@"msec_times"] longLongValue];
                if (msecTime > 0) {
                    date = [NSDate dateWithTimeIntervalSince1970:msecTime / 1000.0];
                } else {
                    NSString *stampValue = [dic[@"time"] objectForKey:@"stamp"];
                    //zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息。
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
                    NSDate *date1 = [dateFormatter dateFromString:stampValue];
                    if (date1) {
                        date = date1;
                    }
                }
            }
            if (date == nil) {
                date = [NSDate date];
            }
            if (lastDate / 1000.0 < date.timeIntervalSince1970 - 60 * 2 || lastDate == 0 && msgType != 2004) {
                lastDate = date.timeIntervalSince1970 * 1000;
                [result setObject:@(lastDate) forKey:@"lastDate"];
                NSMutableDictionary *msgDic = [NSMutableDictionary dictionary];
                [msgDic setObject:[self qimDB_getTimeSmtapMsgIdForDate:date WithUserId:key] forKey:@"MsgId"];
                [result setObject:[self qimDB_getTimeSmtapMsgIdForDate:date WithUserId:key] forKey:@"MsgId"];
                [msgDic setObject:isConsult?userId:key forKey:@"SessionId"];
                [msgDic setObject:@(101) forKey:@"MsgType"];
                [msgDic setObject:@(platForm) forKey:@"Platform"];
                [msgDic setObject:@(0) forKey:@"MsgDirection"];
                [msgDic setObject:@(msecTime - 1) forKey:@"MsgDateTime"];
                [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
                [msgDic setObject:@(1) forKey:@"ReadedTag"];
                [msgDic setObject:@(chatType) forKey:@"ChatType"];
                [msgDic setObject:@(QIMMessageRemoteReadStateDidReaded) forKey:@"ReadState"];
                if (isConsult) {
                    if (direction == 0) {
                        if (chatId.intValue == 5) {
                            if (realJid) {
                                [msgDic setObject:realJid forKey:@"RealJid"];
                            }
                        } else {
                            if (userId) {
                                [msgDic setObject:userId forKey:@"RealJid"];
                            }
                        }
                    } else {
                        if (chatId.intValue == 5) {
                            if (userId) {
                                [msgDic setObject:userId forKey:@"RealJid"];
                            }
                        } else {
                            if (realJid) {
                                [msgDic setObject:realJid forKey:@"RealJid"];
                            }
                        }
                    }
                } else {
                    if (direction == 0) {
                        [msgDic setObject:toJid forKey:@"RealJid"];
                    } else {
                        [msgDic setObject:fromJid forKey:@"RealJid"];
                    }
                }
                [msgList addObject:msgDic];
                [insertMsgList addObject:msgDic];
            }
            if (msgId==nil) {
                msgId = [date description];
            }
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            [msgDic setObject:msgId forKey:@"MsgId"];
            [result setObject:msgId forKey:@"MsgId"];
            [msgDic setObject:isConsult?userId:key forKey:@"SessionId"];
            NSString *realXmppId = realJid?realJid:from;
            if ([type isEqualToString:@"collection"]) {
                NSString *originFrom = [message objectForKey:@"originfrom"];
                NSString *realfrom = [message objectForKey:@"realfrom"];
                realXmppId = realfrom.length?realfrom:originFrom;
                [msgDic setObject:realXmppId forKey:@"From"];
            } else {
                [msgDic setObject:(isConsult && direction == 1) ? realXmppId : fromJid forKey:@"From"];
            }
            [msgDic setObject:toJid?toJid:@"" forKey:@"To"];
            [msgDic setObject:@(platForm) forKey:@"Platform"];
            [msgDic setObject:@(direction) forKey:@"MsgDirection"];
            [msgDic setObject:@(msgType) forKey:@"MsgType"];
            NSData *msgRawData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *msgRaw = [[NSString alloc] initWithData:msgRawData encoding:NSUTF8StringEncoding];
            [msgDic setObject:msgRaw?msgRaw:@"" forKey:@"MsgRaw"];
            [msgRaw release];
            msgRaw = nil;
            if (channelInfo) {
                [msgDic setObject:channelInfo forKey:@"channelid"];
            }
            [msgDic setObject:msg forKey:@"Content"];
            [msgDic setObject:extendInfo?extendInfo:@"" forKey:@"ExtendInfo"];
            [msgDic setObject:@(msecTime) forKey:@"MsgDateTime"];
            [msgDic setObject:@(chatType) forKey:@"ChatType"];
            [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
            NSInteger readFlag = [[dic objectForKey:@"read_flag"] integerValue];
            if (readFlag == 0) {
                readFlag = QIMMessageRemoteReadStateNotSent;
            } else if (readFlag == 1) {
                readFlag = QIMMessageRemoteReadStateDidSent;
            } else if (readFlag == 3) {
                readFlag = QIMMessageRemoteReadStateDidReaded;
            } else if (readFlag == 4) {
                readFlag = QIMMessageRemoteReadStateDidOperated;
            } else {
                readFlag = QIMMessageRemoteReadStateNotSent;
            }
            [msgDic setObject:@(readFlag) forKey:@"ReadState"];
            [msgDic setObject:@(0) forKey:@"ReadedTag"];
            if (isConsult) {
                [result setObject:@(YES) forKey:@"Consult"];
                if (userId) {
                    [result setObject:userId forKey:@"UserId"];
                }
                if (direction == 0) {
                    if (chatId.intValue == ChatType_ConsultServer) {
                        [result setObject:@(ChatType_ConsultServer) forKey:@"ChatType"];
                        if (realJid) {
                            [msgDic setObject:realJid forKey:@"RealJid"];
                            [result setObject:realJid forKey:@"RealJid"];
                        }
                    } else {
                        [result setObject:@(ChatType_Consult) forKey:@"ChatType"];
                        if (userId) {
                            [msgDic setObject:userId forKey:@"RealJid"];
                            [result setObject:userId forKey:@"RealJid"];
                        }
                    }
                } else {
                    if (chatId.intValue == ChatType_ConsultServer) {
                        [result setObject:@(ChatType_Consult) forKey:@"ChatType"];
                        if (userId) {
                            [msgDic setObject:userId forKey:@"RealJid"];
                            [result setObject:userId forKey:@"RealJid"];
                        }
                    } else {
                        [result setObject:@(ChatType_ConsultServer) forKey:@"ChatType"];
                        if (realJid) {
                            [msgDic setObject:realJid forKey:@"RealJid"];
                            [result setObject:realJid forKey:@"RealJid"];
                        }
                    }
                }
            } else {
                if (direction == 0) {
                    [msgDic setObject:toJid forKey:@"RealJid"];
                } else {
                    [msgDic setObject:fromJid forKey:@"RealJid"];
                }
                [result setObject:@(chatType) forKey:@"ChatType"];
            }
            [msgList addObject:msgDic];
            [insertMsgList addObject:msgDic];
            [msgDic release];
            msgDic = nil;
        }
        [result setObject:@(lastDate) forKey:@"lastDate"];
    }
    long long lastMaxTime = [self qimDB_insertSessionWithMsgList:resultDic];
    [self qimDB_bulkInsertMessage:insertMsgList];
    if (updateMsgList.count > 0) {
        [self qimDB_revokeMessageByMsgList:updateMsgList];
    }
    if (collectionOriginMsgList.count > 0) {
        [self qimDB_bulkInsertCollectionMsgWithMsgDics:collectionOriginMsgList];
    }
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    QIMVerboseLog(@"插入单人历史消息%ld条， 耗时 = %f s", insertMsgList.count, end - start);
    [insertMsgList release];
    [updateMsgList release];
    [resultDic release];
    QIMVerboseLog(@"");
    return lastMaxTime;
}

- (NSString *)qimDB_getC2BMessageFeedBackWithMsgId:(NSString *)msgId {
    
    __block NSString *c2BMessageFeedBackStr = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"Select Content from IM_Message Where Type = 2004 AND Content like '%%%@%%';", msgId];
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if ([reader read]) {
            c2BMessageFeedBackStr = [[reader objectForColumnIndex:0] retain];
        }
    }];
    QIMVerboseLog(@"");
    return [c2BMessageFeedBackStr autorelease];
}

#pragma mark - 单人JSON历史消息翻页
- (NSArray *)qimDB_bulkInsertPageHistoryChatJSONMsg:(NSArray *)list
                                         WithXmppId:(NSString *)xmppId {
#pragma mark - bulkInsertHistoryChatJSONMsg JSOn
    NSMutableArray *msgList = [[NSMutableArray alloc] init];
    NSMutableArray *updateMsgList = [[NSMutableArray alloc] initWithCapacity:100];
    NSMutableArray *insertMsgList = [[NSMutableArray alloc] initWithCapacity:100];
    long long lastDate = 0;
    for (NSDictionary *dic in list) {
        NSString *key = nil;
        NSString *realJid = nil;
        NSString *userId = nil;
        
        NSString *from = [dic objectForKey:@"from"];
        NSString *fromDomain = [dic objectForKey:@"from_host"];
        NSString *fromJid = [from stringByAppendingFormat:@"@%@", fromDomain ? fromDomain : [self getDBOwnerDomain]];
        NSString *to = [dic objectForKey:@"to"];
        NSString *toDomain = [dic objectForKey:@"to_host"];
        NSString *toJid = [to stringByAppendingFormat:@"@%@", toDomain ? toDomain : [self getDBOwnerDomain]];
        NSDictionary *message = [dic objectForKey:@"message"];
        
        NSString *type = nil;
        NSString *client_type = nil;
        
        BOOL systemMessage = NO;
        ChatType chatType = ChatType_SingleChat;
        if (message) {
            type = [message objectForKey:@"type"];
            client_type = [message objectForKey:@"client_type"];
        }
        if ([type isEqualToString:@"headline"]) {
            chatType = ChatType_System;
            from = @"SystemMessage";
            fromJid = [from stringByAppendingFormat:@"@%@", fromDomain?fromDomain:[self getDBOwnerDomain]];
        } else if ([type isEqualToString:@"chat"]) {
            chatType = ChatType_SingleChat;
        }
        
        NSDictionary *msgBody = [dic objectForKey:@"body"];
        if (msgBody) {
            NSString *extendInfo = [msgBody objectForKey:@"extendInfo"];
            int msgType = [[msgBody objectForKey:@"msgType"] intValue];
            
            //Message
            NSString *msgId = [msgBody objectForKey:@"id"];
            NSString *chatId = [message objectForKey:@"qchatid"];
            if (chatId == nil) {
                chatId = [message objectForKey:@"chatid"];
            }
            if (chatId == nil) {
                chatId = @"4";
            }
            NSInteger platForm = [self qimDB_parserplatForm:client_type];
            BOOL isConsult = NO;
            if (msgId == nil) {
                msgId = [self UUID];
            }
            NSString *msg = [msgBody objectForKey:@"content"];
            long long msecTime = [[message objectForKey:@"msec_times"] longLongValue];
            NSString *channelInfo = [message objectForKey:@"channelInfo"];
            
            if ([type isEqualToString:@"revoke"]) {
                [updateMsgList addObject:@{@"messageId":msgId?msgId:@"", @"message":msg?msg:@"该消息已被撤回"}];
            } else {
                
            }
            
            if (msgType == 1024) {
                chatId = @"4";
            } else if (msgType == 1002) {
                chatId = @"4";
            }
            
            if ([type isEqualToString:@"note"]) {
                msgType = -11;
            } else if ([type isEqualToString:@"consult"]) {
                isConsult = YES;
            } else if (![type isEqualToString:@"chat"] && ![type isEqualToString:@"revoke"] && ![type isEqualToString:@"subscription"] && ![type isEqualToString:@"headline"] && ![type isEqualToString:@"collection"]){
                continue;
            }
            
            // 初始化缓存结构
            int direction = 0;
            if (isConsult) {
                NSString *tempRealXmppFrpm = [message objectForKey:@"realfrom"];
                NSString *realXmppFrom = [[[message objectForKey:@"realfrom"] componentsSeparatedByString:@"@"] firstObject];
                NSString *realXmppTo = [message objectForKey:@"realto"];
                if ([tempRealXmppFrpm isEqualToString:[self getDbOwnerFullJid]]) {
                    //自己发的
                    if (chatId.intValue == 4) {
                        key = [[NSString stringWithFormat:@"%@-%@",toJid,toJid] retain];
                    } else {
                        key = [[NSString stringWithFormat:@"%@-%@",toJid,realJid] retain];
                    }
                    direction = 0;
                    if (msgType == 1003 || msgType == 1004) {
                        continue;
                    } else if (msgType == 1004) {
                        chatId = @"5";
                    } else if (msgType == 1002) {
                        chatId = @"5";
                        NSString *content = extendInfo.length > 0?extendInfo:msg;
                        NSDictionary *contentDic = [self dictionaryWithJsonString:content];
                        realJid = [contentDic objectForKey:@"u"];
                    } else {
                        realJid = realXmppTo;
                    }
                } else {
                    direction = 1;
                    NSString *realfrom = @"";
                    if (chatId.intValue == 4) {
                        realfrom = [message objectForKey:@"realfrom"];
                    } else {
                        realfrom = [message objectForKey:@"realto"];
                    }
                    // 自己收的
                    if (msgType == 1004) {
                        NSString *content = extendInfo.length>0?extendInfo:msg;
                        NSDictionary *infoDic = [self dictionaryWithJsonString:content];
                        realJid = [infoDic objectForKey:@"u"];
                    } else {
                        realJid = [realfrom componentsSeparatedByString:@"/"].firstObject;
                    }
                    if (chatId.intValue == 4) {
                        key = [[NSString stringWithFormat:@"%@-%@",fromJid,realJid] retain];
                    } else {
                        key = [[NSString stringWithFormat:@"%@-%@",fromJid,fromJid] retain];
                    }
                    userId = fromJid;
                    if (msgType == 1004) {
                        // 转移会话给同事的回馈 但是 显示位置不应该在两个同事之间的会话 所以换from 并且 去除 多点登陆时候的产生的多余消息
                        chatId = @"4";
                        NSString *content = extendInfo.length > 0?extendInfo:msg;
                        NSDictionary *contentDic = [self dictionaryWithJsonString:content];
                        realJid = [contentDic objectForKey:@"u"];
                    } else if (msgType == 1002) {
                        chatId = @"4";
                        NSString *content = extendInfo.length > 0?extendInfo:msg;
                        NSDictionary *contentDic = [self dictionaryWithJsonString:content];
                        realJid = [contentDic objectForKey:@"u"];
                        continue;
                    }
                }
            } else {
                if ([fromJid isEqualToString:[self getDbOwnerFullJid]] == YES) {
                    
                    key = [toJid retain];
                    direction = QIMMessageDirection_Sent;
                } else {
                    direction = QIMMessageDirection_Received;
                    key = [fromJid retain];
                }
            }
            
            NSDate *date = nil;
            if (msecTime > 0) {
                date = [NSDate dateWithTimeIntervalSince1970:msecTime / 1000.0];
            } else {
                NSString *stampValue = [dic[@"time"] objectForKey:@"stamp"];
                //zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息。
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:@"yyyyMMdd'T'HH:mm:ss"];
                NSDate *date1 = [dateFormatter dateFromString:stampValue];
                if (date1) {
                    date = date1;
                }
            }
            if (date == nil) {
                date = [NSDate date];
            }
            
            if (lastDate < date.timeIntervalSince1970 - 60 * 2 && msgType != 2004) {
                lastDate = date.timeIntervalSince1970;
                NSMutableDictionary *msgDic = [NSMutableDictionary dictionary];
                [msgDic setObject:[self qimDB_getTimeSmtapMsgIdForDate:date WithUserId:key] forKey:@"MsgId"];
                [msgDic setObject:isConsult?xmppId:key forKey:@"SessionId"];
                [msgDic setObject:@(101) forKey:@"MsgType"];
                [msgDic setObject:@(platForm) forKey:@"Platform"];
                [msgDic setObject:@(QIMMessageDirection_Sent) forKey:@"MsgDirection"];
                [msgDic setObject:@(date.timeIntervalSince1970*1000-1) forKey:@"MsgDateTime"];
                [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
                [msgDic setObject:@(QIMMessageRemoteReadStateDidReaded) forKey:@"ReadState"];
                [msgDic setObject:@(chatType) forKey:@"ChatType"];
                [msgDic setObject:@(1) forKey:@"ReadedTag"];
                [msgDic setObject:@(chatType) forKey:@"ChatType"];
                if (isConsult) {
                    if (direction == 0) {
                        if (chatId.intValue == 5) {
                            if (realJid) {
                                [msgDic setObject:realJid forKey:@"RealJid"];
                            }
                        } else {
                            if (userId) {
                                [msgDic setObject:userId forKey:@"RealJid"];
                            }
                        }
                    } else {
                        if (chatId.intValue == 5) {
                            if (userId) {
                                [msgDic setObject:userId forKey:@"RealJid"];
                            }
                        } else {
                            if (realJid) {
                                [msgDic setObject:realJid forKey:@"RealJid"];
                            }
                        }
                    }
                } else {
                    if (direction == 0) {
                        [msgDic setObject:toJid forKey:@"RealJid"];
                    } else {
                        [msgDic setObject:fromJid forKey:@"RealJid"];
                    }
                }
                [msgList addObject:msgDic];
                [insertMsgList addObject:msgDic];
            }
            if (msgId==nil) {
                msgId = [date description];
            }
            NSMutableDictionary *msgDic = [NSMutableDictionary dictionary];
            [msgDic setObject:msgId forKey:@"MsgId"];
            [msgDic setObject:isConsult ? xmppId : key forKey:@"SessionId"];
            NSString *realXmppId = realJid ? realJid : fromJid;
            NSString *realXmppFrom = [[[message objectForKey:@"realfrom"] componentsSeparatedByString:@"@"] firstObject];
            NSString *realXmppTo = [[[message objectForKey:@"realto"] componentsSeparatedByString:@"@"] firstObject];
            if ([type isEqualToString:@"collection"]) {
                NSString *originFrom = [message objectForKey:@"originfrom"];
                NSString *realfrom = [message objectForKey:@"realfrom"];
                realXmppId = realfrom.length ? realfrom : originFrom;
                [msgDic setObject:realXmppId forKey:@"From"];
            } else {
                [msgDic setObject:(isConsult && direction == 1) ? realXmppFrom : realXmppId forKey:@"From"];
            }
            [msgDic setObject:realXmppTo?realXmppTo:toJid forKey:@"To"];
            [msgDic setObject:@(platForm) forKey:@"Platform"];
            [msgDic setObject:@(direction) forKey:@"MsgDirection"];
            [msgDic setObject:@(msgType) forKey:@"MsgType"];
            [msgDic setObject:@(chatType) forKey:@"ChatType"];
            NSData *msgRawData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            NSString *msgRaw = [[NSString alloc] initWithData:msgRawData encoding:NSUTF8StringEncoding];
            [msgDic setObject:msgRaw?msgRaw:@"" forKey:@"MsgRaw"];
            if (channelInfo) {
                [msgDic setObject:channelInfo forKey:@"channelid"];
            }
            [msgDic setObject:msg forKey:@"Content"];
            [msgDic setObject:extendInfo?extendInfo:@"" forKey:@"ExtendInfo"];
            [msgDic setObject:@(date.timeIntervalSince1970*1000) forKey:@"MsgDateTime"];
            NSInteger readFlag = [[dic objectForKey:@"read_flag"] integerValue];
            if (readFlag == 0) {
                readFlag = QIMMessageRemoteReadStateNotSent;
            } else if (readFlag == 1) {
                readFlag = QIMMessageRemoteReadStateDidSent;
            } else if (readFlag == 3) {
                readFlag = QIMMessageRemoteReadStateDidReaded;
            } else if (readFlag == 4) {
                readFlag = QIMMessageRemoteReadStateDidOperated;
            } else {
                readFlag = QIMMessageRemoteReadStateNotSent;
            }
            [msgDic setObject:@(readFlag) forKey:@"ReadState"];
            [msgDic setObject:@(QIMMessageSendState_Success) forKey:@"MsgState"];
            if (channelInfo) {
                [msgDic setObject:channelInfo forKey:@"channelid"];
            }
            if (isConsult) {
                if (direction == 0) {
                    if (realJid) {
                        [msgDic setObject:realJid forKey:@"RealJid"];
                    }
                } else {
                    if (realJid) {
                        [msgDic setObject:realJid forKey:@"RealJid"];
                    }
                }
            } else {
                if (direction == 0) {
                    [msgDic setObject:toJid forKey:@"RealJid"];
                } else {
                    [msgDic setObject:fromJid forKey:@"RealJid"];
                }
            }
            [msgList addObject:msgDic];
        }
    }
    [self qimDB_bulkInsertMessage:msgList WithSessionId:xmppId];
    QIMVerboseLog(@"");
    return [msgList autorelease];
}

- (void)qimDB_bulkInsertMessage:(NSArray *)msgList {
    if (msgList.count <= 0) {
        return;
    }
//    [[QIMWatchDog sharedInstance] start];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql = @"insert or IGNORE into IM_Message(MsgId, XmppId, \"From\", \"To\", Content, Platform, Type, ChatType, State, Direction, LastUpdateTime, ReadState, MessageRaw, RealJid, ExtendInfo) values(:MsgId, :XmppId, :From, :To, :Content, :Platform, :Type, :ChatType, :State, :Direction, :LastUpdateTime, :ReadState,:MessageRaw,:RealJid, :ExtendInfo);";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *msgDic in msgList) {
            NSString *msgId = [msgDic objectForKey:@"MsgId"];
            NSString *sessionId = [msgDic objectForKey:@"SessionId"];
            NSString *from = [msgDic objectForKey:@"From"];
            NSString *to = [msgDic objectForKey:@"To"];
            NSString *content = [msgDic objectForKey:@"Content"];
            NSNumber *platform = [msgDic objectForKey:@"Platform"];
            NSNumber *msgType = [msgDic objectForKey:@"MsgType"];
            NSNumber *chatType = [msgDic objectForKey:@"ChatType"];
            NSNumber *msgState = [msgDic objectForKey:@"MsgState"];
            NSNumber *msgDirection = [msgDic objectForKey:@"MsgDirection"];
            NSNumber *lastUpdateTime = [msgDic objectForKey:@"MsgDateTime"];
            NSNumber *readState = [msgDic objectForKey:@"ReadState"];
            NSString *msgRaw = [msgDic objectForKey:@"MsgRaw"];
            NSString *realJid = [msgDic objectForKey:@"RealJid"];
            NSString *extendInfo = [msgDic objectForKey:@"ExtendInfo"];
            NSMutableArray *param = [[NSMutableArray alloc] init];
            [param addObject:msgId?msgId:@":NULL"];
            [param addObject:sessionId?sessionId:@":NULL"];
            [param addObject:from?from:@":NULL"];
            [param addObject:to?to:@":NULL"];
            [param addObject:content?content:@":NULL"];
            [param addObject:platform];
            [param addObject:msgType];
            [param addObject:chatType?chatType:@(0)];
            [param addObject:msgState];
            [param addObject:msgDirection];
            [param addObject:lastUpdateTime];
            [param addObject:readState?readState:@(0)];
            [param addObject:msgRaw?msgRaw:@":NULL"];
            [param addObject:realJid?realJid:@":NULL"];
            [param addObject:extendInfo?extendInfo:@":NULL"];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
        
    }];
//    QIMVerboseLog(@"插入%ld条消息， 耗时 : %lf", msgList.count, [[QIMWatchDog sharedInstance] escapedTime]);
}

- (void)qimDB_bulkInsertMessage:(NSArray *)msgList WithSessionId:(NSString *)sessionId{
    
    [[self dbInstance] usingTransaction:^(Database *database) {
        
        NSString *sql = @"insert or IGNORE into IM_Message(MsgId, XmppId, \"From\", \"To\", Content, Platform, Type, ChatType, State, Direction, LastUpdateTime, ReadState, MessageRaw, RealJid, ExtendInfo) values(:MsgId, :XmppId, :From, :To, :Content, :Platform, :Type, :ChatType, :State, :Direction, :LastUpdateTime, :ReadState,:MessageRaw, :RealJid, :ExtendInfo);";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *msgDic in msgList) {
            NSString *msgId = [msgDic objectForKey:@"MsgId"];
            NSString *sessionId = [msgDic objectForKey:@"SessionId"];
            NSString *from = [msgDic objectForKey:@"From"];
            NSString *to = [msgDic objectForKey:@"To"];
            NSString *content = [msgDic objectForKey:@"Content"];
            NSNumber *platform = [msgDic objectForKey:@"Platform"];
            NSNumber *msgType = [msgDic objectForKey:@"MsgType"];
            NSNumber *chatType = [msgDic objectForKey:@"ChatType"];
            NSNumber *msgState = [msgDic objectForKey:@"MsgState"];
            NSNumber *msgDirection = [msgDic objectForKey:@"MsgDirection"];
            NSNumber *lastUpdateTime = [msgDic objectForKey:@"MsgDateTime"];
            NSNumber *readState = [msgDic objectForKey:@"ReadState"];
            NSString *msgRaw = [msgDic objectForKey:@"MsgRaw"];
            NSString *realJid = [msgDic objectForKey:@"RealJid"];
            NSString *extendInfo = [msgDic objectForKey:@"ExtendInfo"];
            
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:msgId?msgId:@":NULL"];
            [param addObject:sessionId?sessionId:@":NULL"];
            [param addObject:from?from:@":NULL"];
            [param addObject:to?to:@":NULL"];
            [param addObject:content?content:@":NULL"];
            [param addObject:platform];
            [param addObject:msgType];
            [param addObject:chatType?chatType:@(0)];
            [param addObject:msgState];
            [param addObject:msgDirection];
            [param addObject:lastUpdateTime];
            [param addObject:readState?readState:@(0)];
            [param addObject:msgRaw?msgRaw:@":NULL"];
            [param addObject:realJid?realJid:@":NULL"];
            [param addObject:extendInfo?extendInfo:@":NULL"];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
    QIMVerboseLog(@"");
}

//更新消息发送状态
- (void)qimDB_updateMsgState:(int)msgState WithMsgId:(NSString *)msgId{
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql = @"Update IM_Message Set State = :State Where MsgId = :MsgId;";
        [database executeNonQuery:sql withParameters:[NSArray arrayWithObjects:@(msgState), msgId, nil]];
    }];
    QIMVerboseLog(@"");
}

//更新消息发送时间戳
- (void)qimDB_updateMsgDate:(long long)msgDate WithMsgId:(NSString *)msgId{
    if (msgDate <= 0) {
        return;
    }
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set LastUpdateTime = :LastUpdateTime Where MsgId = :MsgId;";
        [database executeNonQuery:sql withParameters:[NSArray arrayWithObjects:@(msgDate),msgId, nil]];
    }];
    QIMVerboseLog(@"");
}

- (long long)qimDB_getReadedTimeStampForUserId:(NSString *)userId WithRealJid:(NSString *)realJid WithMsgDirection:(int)msgDirection withUnReadCount:(NSInteger)unReadCount {
    __block long long timeStamp = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"Select LastUpdateTime From IM_Message Where XmppId = :XmppId And RealJid = :RealJid And Direction = :MsgDirection And Type <> 101 order by LastUpdateTime desc limit 1 offset %d;", unReadCount];
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:userId];
        [param addObject:realJid];
        [param addObject:@(msgDirection)];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        if ([reader read]) {
            timeStamp = [[reader objectForColumnIndex:0] longLongValue];
            if (timeStamp <= 0) {
                timeStamp = -1;
            }
        }
    }];
    QIMVerboseLog(@"");
    return timeStamp;
}

- (NSArray *)qimDB_getMgsListBySessionId:(NSString *)sesId{
    __block NSMutableArray *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid Where XmppId = :XmppId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:sesId];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        while ([reader read]) {
            
            if (result == nil) {
                result = [[NSMutableArray alloc] init];
            }
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:msgDic setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
            
            [result addObject:msgDic];
            [msgDic release];
        }
    }];
    QIMVerboseLog(@"");
    return [result autorelease];
}

- (NSDictionary *)qimDB_getMsgsByMsgId:(NSString *)msgId {
    if (!msgId) {
        return nil;
    }
    __block NSMutableDictionary *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql =@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where MsgId=:MsgId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:msgId];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        if (!result) {
            result = [[NSMutableDictionary alloc] init];
        }
        if ([reader read]) {
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            [IMDataManager safeSaveForDic:result setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:result setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:result setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:result setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:result setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:result setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:result setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:result setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:result setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:result setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:result setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:result setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:result setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:result setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:result setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:result setObject:realJid forKey:@"RealJid"];
        }
    }];
    QIMVerboseLog(@"");
    return [result autorelease];
}

- (NSArray *)qimDB_getMsgsByMsgType:(NSArray *)msgTypes ByXmppId:(NSString *)xmppId ByReadJid:(NSString *)realJid {
    
    __block NSMutableArray * msgs = [NSMutableArray arrayWithCapacity:1];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"";
        if (realJid.length > 0) {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = '%@' And RealJid = '%@' And (", xmppId, realJid];
            for (NSInteger i = 0; i < msgTypes.count; i++) {
                NSInteger msgType = [[msgTypes objectAtIndex:i] integerValue];
                if (i == 0) {
                    sql = [sql stringByAppendingFormat:[NSString stringWithFormat:@"Type = %d", msgType]];
                } else {
                    sql = [sql stringByAppendingFormat:[NSString stringWithFormat:@" Or Type = %d", msgType]];
                }
            }
            sql = [sql stringByAppendingFormat:@") Order By LastUpdateTime DESC;"];
        } else {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = '%@' And (", xmppId];
            for (NSInteger i = 0; i < msgTypes.count; i++) {
                NSInteger msgType = [[msgTypes objectAtIndex:i] integerValue];
                if (i == 0) {
                    sql = [sql stringByAppendingFormat:[NSString stringWithFormat:@"Type = %d", msgType]];
                } else {
                    sql = [sql stringByAppendingFormat:[NSString stringWithFormat:@" Or Type = %d", msgType]];
                }
            }
            sql = [sql stringByAppendingFormat:@") Order By LastUpdateTime DESC;"];
        }
        DataReader *reader = [database executeReader:sql withParameters:nil];
        
        while ([reader read]) {
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
            [IMDataManager safeSaveForDic:result setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:result setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:result setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:result setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:result setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:result setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:result setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:result setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:result setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:result setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:result setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:result setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:result setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:result setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:result setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:result setObject:realJid forKey:@"RealJid"];
            
            [msgs addObject:result];
        }
    }];
    QIMVerboseLog(@"");
    return msgs;
}

- (NSArray *)qimDB_getMsgsByMsgType:(int)msgType ByXmppId:(NSString *)xmppId{
    __block NSMutableArray * msgs = [NSMutableArray arrayWithCapacity:1];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql =@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where Type=:Type And XmppId=:Xmppid Order By LastUpdateTime DESC;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:[NSNumber numberWithInt:msgType]];
        [param addObject:xmppId];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        
        while ([reader read]) {
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary * result = [[NSMutableDictionary alloc] init];
            [IMDataManager safeSaveForDic:result setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:result setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:result setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:result setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:result setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:result setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:result setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:result setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:result setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:result setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:result setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:result setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:result setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:result setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:result setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:result setObject:realJid forKey:@"RealJid"];
            [msgs addObject:result];
        }
    }];
    QIMVerboseLog(@"");
    return msgs;
}

- (NSArray *)qimDB_getMsgsByMsgType:(int)msgType {
    __block NSMutableArray * msgs = [NSMutableArray arrayWithCapacity:1];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql =@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where Type=:Type Order By LastUpdateTime DESC;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:[NSNumber numberWithInt:msgType]];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        
        while ([reader read]) {
            NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            [IMDataManager safeSaveForDic:result setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:result setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:result setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:result setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:result setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:result setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:result setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:result setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:result setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:result setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:result setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:result setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:result setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:result setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:result setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:result setObject:realJid forKey:@"RealJid"];
            [msgs addObject:result];
        }
    }];
    QIMVerboseLog(@"");
    return msgs;
}

- (NSArray *)qimDB_getMgsListBySessionId:(NSString *)sesId WithRealJid:(NSString *)realJid WithLimit:(int)limit WithOffset:(int)offset {
//    [[QIMWatchDog sharedInstance] start];
    if (sesId == nil) {
        return nil;
    }
    __block NSMutableArray *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = nil;
        NSMutableArray *param = [[NSMutableArray alloc] init];
        if (limit) {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = :XmppId And RealJid = :RealJid Order By LastUpdateTime DESC Limit %d OFFSET %d;",limit,offset];
        } else {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = :XmppId And RealJid = :RealJid Order By LastUpdateTime DESC;"];
        }
        [param addObject:sesId];
        [param addObject:realJid?realJid:@":NULL"];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        
        NSMutableArray *tempList = nil;
        if (result == nil) {
            result = [[NSMutableArray alloc] init];
            tempList = [[NSMutableArray alloc] init];
        }
        
        while ([reader read]) {
            
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            
            /*
             return @{@"message" : @"MessageBody",
             @"to" : @"ToJid",
             @"messageId" : @"MessageId",
             @"messageType" : @"MessageType",
             @"extendInformation" : @"MessageExtendInfo",
             @"backupInfo" : @"MessageBackUpInfo",
             @"channelInfo" : @"MessageChannelInfo",
             @"chatId" : @"MessageChatId",
             @"appendInfoDict" : @"MessageAppendInfoDict"
             };
             */
            
            [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:msgDic setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
            
            [tempList addObject:msgDic];
            [msgDic release];
        }
        for (int i = (int)tempList.count - 1;i>= 0;i--) {
            [result addObject:[tempList objectAtIndex:i]];
        }
        [tempList release];
    }];
//    QIMVerboseLog(@"sql取消息耗时。: %llf", [[QIMWatchDog sharedInstance] escapedTime]);
    QIMVerboseLog(@"");
    return [result autorelease];
}

- (NSArray *)qimDB_getMsgListByXmppId:(NSString *)xmppId WithRealJid:(NSString *)realJid FromTimeStamp:(long long)timeStamp {
    if (xmppId == nil) {
        return nil;
    }
    __block NSMutableArray *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = nil;
        NSMutableArray *param = nil;
        if (realJid) {
            sql =[NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = :XmppId And RealJid = :RealJid And LastUpdateTime >= :LastUpdateTime Order By LastUpdateTime DESC;"];
            param = [[NSMutableArray alloc] init];
            [param addObject:xmppId];
            [param addObject:realJid];
            [param addObject:@(timeStamp)];
        } else {
            sql =[NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = :XmppId And RealJid is null And LastUpdateTime >= :LastUpdateTime Order By LastUpdateTime DESC;"];
            param = [[NSMutableArray alloc] init];
            [param addObject:xmppId];
            [param addObject:@(timeStamp)];
        }
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        
        NSMutableArray *tempList = nil;
        if (result == nil) {
            result = [[NSMutableArray alloc] init];
            tempList = [[NSMutableArray alloc] init];
        }
        
        while ([reader read]) {
            
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            
            [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:msgDic setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
        
            [tempList addObject:msgDic];
            [msgDic release];
        }
        for (int i = (int)tempList.count - 1; i>= 0;i--) {
            [result addObject:[tempList objectAtIndex:i]];
        }
        [tempList release];
    }];
    QIMVerboseLog(@"");
    return [result autorelease];
}

- (NSArray *)qimDB_getMsgListByXmppId:(NSString *)xmppId FromTimeStamp:(long long)timeStamp {
    if (xmppId == nil) {
        return nil;
    }
    __block NSMutableArray *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql =[NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = :XmppId And LastUpdateTime >= :LastUpdateTime Order By LastUpdateTime DESC;"];
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:xmppId];
        [param addObject:@(timeStamp)];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        
        NSMutableArray *tempList = nil;
        if (result == nil) {
            result = [[NSMutableArray alloc] init];
            tempList = [[NSMutableArray alloc] init];
        }
        
        while ([reader read]) {
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            
            [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:msgDic setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
            
            [tempList addObject:msgDic];
            [msgDic release];
        }
        for (int i = (int)tempList.count - 1;i>= 0;i--) {
            [result addObject:[tempList objectAtIndex:i]];
        }
        [tempList release];
    }];
    QIMVerboseLog(@"");
    return [result autorelease];
}

- (NSInteger)qimDB_getNotReaderMsgCountByJid:(NSString *)jid ByRealJid:(NSString *)realJid withChatType:(ChatType)chatType {
    __block NSInteger count = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"SELECT UnreadCount FROM IM_SessionList Where XmppId = :XmppId And RealJid = :RealJid And ChatType = :ChatType;";
        DataReader *reader = [database executeReader:sql withParameters:@[jid, realJid, @(chatType)]];
        if ([reader read]) {
            count = [[reader objectForColumnIndex:0] integerValue];
        }
    }];
    QIMVerboseLog(@"");
    return count;
}

- (NSInteger)qimDB_getNotReaderMsgCountByJid:(NSString *)jid ByRealJid:(NSString *)realJid {
    __block NSInteger count = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"SELECT UnreadCount FROM IM_SessionList Where XmppId = :XmppId And RealJid = :RealJid;";
        DataReader *reader = [database executeReader:sql withParameters:@[jid, realJid]];
        if ([reader read]) {
            count = [[reader objectForColumnIndex:0] integerValue];
        }
    }];
    QIMVerboseLog(@"");
    return count;
}

- (void)qimDB_updateMessageFromState:(int)fState ToState:(int)tState {
    [[self dbInstance] usingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set State=:tMsgState Where State=:fMsgState;";
        [database executeNonQuery:sql withParameters:@[@(tState),@(fState)]];
    }];
    QIMVerboseLog(@"");
}

- (NSInteger)qimDB_getMessageStateWithMsgId:(NSString *)msgId {
    __block NSInteger msgState = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"select State from IM_Message where MsgId='%@';", msgId];
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if ([reader read]) {
            msgState = [[reader objectForColumnIndex:0] integerValue];
        }
    }];
    QIMVerboseLog(@"");
    return msgState;
}

- (NSInteger)qimDB_getReadStateWithMsgId:(NSString *)msgId {
    __block NSInteger readState = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"select ReadState from IM_Message where MsgId='%@';", msgId];
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if ([reader read]) {
            readState = [[reader objectForColumnIndex:0] integerValue];
        }
    }];
    return readState;
}

- (NSArray *)qimDB_getMsgIdsForDirection:(int)msgDirection WithMsgState:(int)msgState {
    __block NSMutableArray *resultList = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select MsgId From IM_Message Where State = :State And Direction=:Direction;";
        DataReader *reader = [database executeReader:sql withParameters:@[@(msgState),@(msgDirection)]];
        while ([reader read]) {
            if (resultList == nil) {
                resultList = [[NSMutableArray alloc] init];
            }
            NSString *msgId = [reader objectForColumnIndex:0];
            [resultList addObject:msgId];
        }
    }];
    QIMVerboseLog(@"");
    return [resultList autorelease];
}

#pragma mark - 消息数据方法

- (NSString *)qimDB_getLastMsgIdByJid:(NSString *)jid {
    __block NSString *lastMsgId = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"select MsgId from IM_Message Where XmppId=:XmppId And Type != 101 order by LastUpdateTime desc limit 1";
        DataReader *reader = [database executeReader:sql withParameters:@[jid]];
        if ([reader read]) {
            lastMsgId = [[reader objectForColumnIndex:0] retain];
        }
    }];
    QIMVerboseLog(@"");
    return [lastMsgId autorelease];
}

- (long long)qimDB_getMsgTimeWithMsgId:(NSString *)msgId {
    if (!msgId) {
        return 0;
    }
    __block long long maxRemoteTime = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"select LastUpdateTime from IM_Message Where MsgId=:MsgId";
        DataReader *reader = [database executeReader:sql withParameters:@[msgId]];
        if ([reader read]) {
            maxRemoteTime = [[reader objectForColumnIndex:0] longLongValue];
        }
    }];
    QIMVerboseLog(@"");
    return maxRemoteTime;
}

- (void)qimDB_clearHistoryMsg {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Delete From IM_Message;";
        [database executeNonQuery:sql withParameters:nil];
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_updateSystemMsgState:(int)msgState withReadState:(QIMMessageRemoteReadState)readState WithXmppId:(NSString *)xmppId {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set State=:State, ReadState = :ReadState Where XmppId=:XmppId;";
        [database executeNonQuery:sql withParameters:@[@(msgState), @(readState), xmppId]];
    }];
    QIMVerboseLog(@"");
}


#pragma mark - 消息阅读状态

- (NSArray *)qimDB_getReceiveMsgIdListWithMsgReadFlag:(QIMMessageRemoteReadState)remoteReadState withChatType:(ChatType)chatType withMsgDirection:(QIMMessageDirection)receiveDirection {
    __block NSMutableArray *resultList = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"SELECT a.'XmppId', GROUP_CONCAT(MsgId) as msgIdList FROM IM_Message as a WHERE a.ReadState & %d != %d AND a.Direction = %d And a.ChatType = %d GROUP By a.'XmppId';", QIMMessageRemoteReadStateDidReaded, remoteReadState, receiveDirection, chatType];
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            if (resultList == nil) {
                resultList = [[NSMutableArray alloc] init];
            }
            NSString *xmppId = [reader objectForColumnIndex:0];
            NSString *msgIds = [reader objectForColumnIndex:1];
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [IMDataManager safeSaveForDic:dict setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:dict setObject:msgIds forKey:@"MsgIds"];
            [resultList addObject:dict];
            [dict release];
            dict = nil;
        }
    }];
    QIMVerboseLog(@"");
    return [resultList autorelease];
}

- (NSArray *)qimDB_getNotReadMsgListForUserId:(NSString *)userId ForRealJid:(NSString *)realJid {
    
    if (userId.length <=0 || realJid.length <= 0) {
        return nil;
    }
    __block NSMutableArray *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"Select MsgId From IM_Message Where XmppId = :XmppId And RealJid = :RealJid And ReadState & %d != %d And Direction = :MsgDirection;", QIMMessageRemoteReadStateDidReaded, QIMMessageRemoteReadStateDidReaded];
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:userId];
        [param addObject:realJid];
        [param addObject:@(QIMMessageDirection_Received)];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        while ([reader read]) {
            
            if (result == nil) {
                result = [[NSMutableArray alloc] init];
            }
            
            NSString *msgId = [reader objectForColumnIndex:0];
            if (msgId.length > 0) {
                [result addObject:msgId];
            }
        }
    }];
    QIMVerboseLog(@"");
    return [result autorelease];
}

- (NSArray *)qimDB_getNotReadMsgListForUserId:(NSString *)userId {
    __block NSMutableArray *result = nil;
    //    [[QIMWatchDog sharedInstance] start];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"Select MsgId From IM_Message Where XmppId = :XmppId And ReadState & %d != %d And Direction = :MsgDirection;", QIMMessageRemoteReadStateDidReaded, QIMMessageRemoteReadStateDidReaded];
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:userId];
        [param addObject:@(QIMMessageDirection_Received)];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        while ([reader read]) {
            
            if (result == nil) {
                result = [[NSMutableArray alloc] init];
            }
            
            NSString *msgId = [reader objectForColumnIndex:0];
            if (msgId.length > 0) {
                [result addObject:msgId];
            }
        }
    }];
    //    QIMVerboseLog(@"查未读消息MsgIds耗时: %llf", [[QIMWatchDog sharedInstance] escapedTime]);
    QIMVerboseLog(@"");
    return [result autorelease];
}

// 0 未读 1是读过了
- (void)qimDB_updateMessageReadStateWithMsgId:(NSString *)msgId{
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set ReadedTag = 1 Where  MsgId = :MsgId;";
        [database executeNonQuery:sql withParameters:[NSArray arrayWithObjects:msgId, nil]];
    }];
    QIMVerboseLog(@"");
}

//批量更新消息阅读状态
- (void)qimDB_bulkUpdateMessageReadStateWithMsg:(NSArray *)msgs {
    if (msgs.count <= 0) {
        return;
    }
    
    //    0 - 已发送， 更新MsgState = MessageSuccess
    //    1 - 已送达, 更新MsgState = MessageNotRead
    //    0， 1 - 对方未读， 更新ReadFlag = 0
    //    3 - 对方已读，更新readFlag = 1， 更新msgState = MessgaeRead
    
    QIMVerboseLog(@"批量更新消息阅读状态 : %@", msgs);
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set ReadState = :ReadState Where MsgId=:MsgId;";
        NSMutableArray *paramList = [NSMutableArray array];
        for (NSDictionary *msgInfo in msgs) {
            NSString *msgId = [msgInfo objectForKey:@"msgid"];
            NSInteger readFlag = [[msgInfo objectForKey:@"readflag"] integerValue];
            QIMMessageRemoteReadState remoteReadState = QIMMessageRemoteReadStateNotSent;
            switch (readFlag) {
                case 0: {
                    remoteReadState = QIMMessageRemoteReadStateNotSent;
                }
                    break;
                case 1: {
                    remoteReadState = QIMMessageRemoteReadStateDidSent;
                }
                    break;
                case 3: {
                    remoteReadState = QIMMessageRemoteReadStateDidReaded;
                }
                    break;
                case 7: {
                    remoteReadState = QIMMessageRemoteReadStateDidOperated;
                }
                    break;
                default:
                    break;
            }
//            QIMVerboseLog(@"MsgId : %@, 阅读状态 : %@", msgId, msgStateLog);
            [paramList addObject:@[@(remoteReadState), msgId]];
        }
        [database executeBulkInsert:sql withParameters:paramList];
    }];
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    QIMVerboseLog(@"批量更新%ld条消息阅读状态 耗时 = %f s", msgs.count, end - start); //
    QIMVerboseLog(@"");
}

- (long long)qimDB_bulkUpdateGroupMessageReadFlag:(NSArray *)mucArray {
    
    if (mucArray.count <= 0) {
        return 0;
    }
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    __block NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSDictionary *mucDic in mucArray) {
        NSString *domain = [mucDic objectForKey:@"domain"];
        NSString *mucName = [mucDic objectForKey:@"muc_name"];
        NSString *groupId = [mucName stringByAppendingFormat:@"@%@", domain];
        [[self dbInstance] syncUsingTransaction:^(Database *database) {
            NSString *sql1 = [NSString stringWithFormat:@"select XmppId, LastUpdateTime from IM_Message where XmppId = :XmppId and ReadState & %d = %d and Direction = %d order by LastUpdateTime asc LIMIT 1;", QIMMessageRemoteReadStateDidReaded, QIMMessageRemoteReadStateDidReaded, QIMMessageDirection_Received];
            DataReader *reader = [database executeReader:sql1 withParameters:@[groupId]];
            QIMVerboseLog(@"DB获取群阅读指针参数 ：%@", @[groupId]);
            if ([reader read]) {
                NSString *xmppId = [reader objectForColumnIndex:0];
                NSNumber *lastupdateTime = [reader objectForColumnIndex:1];
                [dict setObject:lastupdateTime forKey:xmppId];
            }
        }];
    }
    QIMVerboseLog(@"DB获取群阅读指针结果 ：%@", dict);
    NSString *sql2 = [NSString stringWithFormat:@"UPDATE IM_Message SET ReadState = (ReadState|%d) WHERE XmppId = :XmppId and LastUpdateTime <= :LastUpdateTime1 and LastUpdateTime >= :LastUpdateTime2;", QIMMessageRemoteReadStateDidReaded];
    __block long long maxRemarkUpdateTime = 0;
    [[self dbInstance] usingTransaction:^(Database *database) {
        NSMutableArray *params = nil;
        for (NSDictionary *mucDic in mucArray) {
            NSString *domain = [mucDic objectForKey:@"domain"];
            NSString *mucName = [mucDic objectForKey:@"muc_name"];
            NSString *groupId = [mucName stringByAppendingFormat:@"@%@", domain];
            long long mucLastReadFlagTime = [[mucDic objectForKey:@"date"] longLongValue];
            long long mucMaxReadFlagTime = [[dict objectForKey:groupId] longLongValue];
            if (maxRemarkUpdateTime < mucLastReadFlagTime) {
                maxRemarkUpdateTime = mucLastReadFlagTime;
            }
            if (params == nil) {
                params = [NSMutableArray array];
            }
            NSMutableArray *param = [NSMutableArray array];
            [param addObject:groupId?groupId:@""];
            [param addObject:@(mucLastReadFlagTime)];
            [param addObject:@(mucMaxReadFlagTime)];
            [params addObject:param];
        }
        QIMVerboseLog(@"DB更新群阅读指针参数 ：%@", params);
        [database executeBulkInsert:sql2 withParameters:params];
    }];
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    QIMVerboseLog(@"DB更新群阅读指针%ld条数据 耗时 = %f s", mucArray.count, end - start); //s
    QIMVerboseLog(@"");
    return maxRemarkUpdateTime;
}

- (void)qimDB_updateAllMsgWithMsgRemoteState:(int)msgRemoteFlag ByMsgDirection:(int)msgDirection ByReadMarkT:(long long)readMarkT {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set ReadState=:ReadState Where Direction = :Direction;";
        [database executeNonQuery:sql withParameters:@[@(msgRemoteFlag),@(msgDirection)]];
    }];
    QIMVerboseLog(@"");
}

- (void)qimDB_updateGroupMessageRemoteState:(NSInteger)msgRemoteFlag ByGroupReadList:(NSArray *)groupReadList {
    
    QIMVerboseLog(@"在线groupReadList : %@", groupReadList);
    if (groupReadList.count <= 0) {
        return;
    }
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    __block NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    /*
    for (NSDictionary *mucDic in groupReadList) {
        NSString *domain = [mucDic objectForKey:@"domain"];
        NSString *mucName = [mucDic objectForKey:@"id"];
        NSString *groupId = [mucName stringByAppendingFormat:@"@%@", domain];
        [[self dbInstance] syncUsingTransaction:^(Database *database) {
            NSString *sql1 = [NSString stringWithFormat:@"select XmppId, LastUpdateTime from IM_Message where XmppId = :XmppId and ReadState & %d = %d order by LastUpdateTime desc LIMIT 1;", QIMMessageRemoteReadStateDidReaded, QIMMessageRemoteReadStateDidReaded];
            DataReader *reader = [database executeReader:sql1 withParameters:@[groupId]];
            QIMVerboseLog(@"在线DB获取群阅读指针参数 ：%@", @[groupId]);
            if ([reader read]) {
                NSString *xmppId = [reader objectForColumnIndex:0];
                NSNumber *lastupdateTime = [reader objectForColumnIndex:1];
                [dict setObject:lastupdateTime forKey:xmppId];
            }
        }];
    } */
    for (NSDictionary *mucDic in groupReadList) {
        NSString *domain = [mucDic objectForKey:@"domain"];
        NSString *mucName = [mucDic objectForKey:@"id"];
        NSString *groupId = [mucName stringByAppendingFormat:@"@%@", domain];
        [[self dbInstance] syncUsingTransaction:^(Database *database) {
            NSString *sql1 = [NSString stringWithFormat:@"select XmppId, Min(LastUpdateTime) from IM_Message where XmppId = :XmppId and ReadState & %d != %d;", QIMMessageRemoteReadStateDidReaded, QIMMessageRemoteReadStateDidReaded, QIMMessageDirection_Received];
            DataReader *reader = [database executeReader:sql1 withParameters:@[groupId]];
            QIMVerboseLog(@"在线DB获取群阅读指针参数 ：%@", @[groupId]);
            if ([reader read]) {
                NSString *xmppId = [reader objectForColumnIndex:0];
                NSNumber *lastupdateTime = [reader objectForColumnIndex:1];
                if (xmppId.length > 0) {
                    [dict setObject:lastupdateTime?lastupdateTime:@(0) forKey:xmppId];
                }
            }
        }];
    }
    QIMVerboseLog(@"在线DB获取群阅读指针结果 ：%@", dict);
    NSString *sql2 = [NSString stringWithFormat:@"UPDATE IM_Message SET ReadState = (ReadState|%d) WHERE XmppId = :XmppId and LastUpdateTime <= :LastUpdateTime1 and LastUpdateTime >= :LastUpdateTime2;", QIMMessageRemoteReadStateDidReaded];
    __block long long maxRemarkUpdateTime = 0;
    [[self dbInstance] usingTransaction:^(Database *database) {
        NSMutableArray *params = nil;
        for (NSDictionary *mucDic in groupReadList) {
            NSString *domain = [mucDic objectForKey:@"domain"];
            NSString *mucName = [mucDic objectForKey:@"id"];
            NSString *groupId = [mucName stringByAppendingFormat:@"@%@", domain];
            long long mucLastReadFlagTime = [[mucDic objectForKey:@"t"] longLongValue];
            long long mucMaxReadFlagTime = [[dict objectForKey:groupId] longLongValue];
            if (maxRemarkUpdateTime < mucLastReadFlagTime) {
                maxRemarkUpdateTime = mucLastReadFlagTime;
            }
            if (params == nil) {
                params = [NSMutableArray array];
            }
            NSMutableArray *param = [NSMutableArray array];
            [param addObject:groupId?groupId:@""];
            [param addObject:@(mucLastReadFlagTime)];
            [param addObject:@(mucMaxReadFlagTime)];
            [params addObject:param];
        }
        QIMVerboseLog(@"在线DB更新群阅读指针参数 ：%@", params);
        [database executeBulkInsert:sql2 withParameters:params];
    }];
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    QIMVerboseLog(@"在线DB更新群阅读指针%ld条数据 耗时 = %f s", groupReadList.count, end - start); //s
    QIMVerboseLog(@"");
}

- (void)qimDB_updateMsgWithMsgRemoteState:(NSInteger)msgRemoteFlag ByMsgIdList:(NSArray *)msgIdList {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Message Set ReadState=:ReadState Where MsgId=:MsgId And ReadState < :ReadState2";
        NSMutableArray *paramList = [NSMutableArray array];
        for (NSDictionary *msgInfo in msgIdList) {
            [paramList addObject:@[@(msgRemoteFlag),[msgInfo objectForKey:@"id"], @(msgRemoteFlag)]];
        }
        
        BOOL success = [database executeBulkInsert:sql withParameters:paramList];
        if (success) {
            QIMVerboseLog(@"更新消息RemoteState状态的参数成功 : %@", paramList);
        }
    }];
    QIMVerboseLog(@"");
}

#pragma mark - 本地消息搜索

- (NSArray *)qimDB_searchMsgHistoryWithKey:(NSString *)key {
    __block NSMutableArray *contactList = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select XmppId from IM_Message WHERE Content like :key and Type = 1 group by XmppId;";
        DataReader *reader = [database executeReader:sql withParameters:@[[NSString stringWithFormat:@"%%%@%%",key]]];
        while ([reader read]) {
            if (contactList == nil) {
                contactList = [[NSMutableArray alloc] init];
            }
            NSString *xmppId = [reader objectForColumnIndex:0];
            [contactList addObject:@{@"XmppId":xmppId}];
        }
    }];
    QIMVerboseLog(@"");
    return contactList;
}

- (NSArray *)qimDB_searchMsgIdWithKey:(NSString *)key ByXmppId:(NSString *)xmppId {
    __block NSMutableArray *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select MsgId,Content from IM_Message WHERE Content like :key and Type = 1 and XmppId = :XmppId;";
        DataReader *reader = [database executeReader:sql withParameters:@[[NSString stringWithFormat:@"%%%@%%",key],xmppId]];
        while ([reader read]) {
            if (result == nil) {
                result = [[NSMutableArray alloc] init];
            }
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *content = [reader objectForColumnIndex:1];
            [result addObject:@{@"MsgId":msgId,@"Content":content}];
        }
    }];
    QIMVerboseLog(@"");
    return result;
}

- (NSArray *)qimDB_getLocalMediaByXmppId:(NSString *)xmppId ByReadJid:(NSString *)realJid {
    __block NSMutableArray * msgs = [NSMutableArray arrayWithCapacity:1];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"";
        if (realJid.length > 0) {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = '%@' And RealJid = '%@' And (Type = 32 Or Content Like '%%%@%%') Order By LastUpdateTime DESC;", xmppId, realJid, [NSString stringWithFormat:@"obj type=\"image"]];
        } else {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = '%@' And (Type = 32 Or Content Like '%%%@%%') Order By LastUpdateTime DESC;", xmppId, [NSString stringWithFormat:@"obj type=\"image"]];
        }
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            
            [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:msgDic setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
            [msgs addObject:msgDic];
        }
    }];
    QIMVerboseLog(@"");
    return msgs;
}

- (NSArray *)qimDB_getMsgsByKeyWord:(NSString *)keywords ByXmppId:(NSString *)xmppId ByReadJid:(NSString *)realJid {
    
    __block NSMutableArray * msgs = [NSMutableArray arrayWithCapacity:1];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"";
        if (realJid.length > 0) {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = '%@' And RealJid = '%@' And Content like '%%%@%%'  Order By LastUpdateTime DESC limit(1000);", xmppId, realJid, keywords];
        } else {
            sql = [NSString stringWithFormat:@"Select MsgId, XmppId, Platform, \"From\", \"To\", Content, ExtendInfo, Type, ChatType, State, Direction, ContentResolve, ReadState,LastUpdateTime, MessageRaw, RealJid From IM_Message Where XmppId = '%@' And Content like '%%%@%%' Order By LastUpdateTime DESC limit(1000);", xmppId, keywords];
        }
        DataReader *reader = [database executeReader:sql withParameters:nil];
        
        while ([reader read]) {
            NSString *msgId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSNumber *platform = [reader objectForColumnIndex:2];
            NSString *from = [reader objectForColumnIndex:3];
            NSString *to = [reader objectForColumnIndex:4];
            NSString *content = [reader objectForColumnIndex:5];
            NSString *extendInfo = [reader objectForColumnIndex:6];
            NSNumber *msgType = [reader objectForColumnIndex:7];
            NSNumber *chatType = [reader objectForColumnIndex:8];
            NSNumber *msgState = [reader objectForColumnIndex:9];
            NSNumber *msgDirection = [reader objectForColumnIndex:10];
            NSString *contentResolve = [reader objectForColumnIndex:11];
            NSNumber *readState = [reader objectForColumnIndex:12];
            NSNumber *msgDateTime = [reader objectForColumnIndex:13];
            id msgRaw = [reader objectForColumnIndex:14];
            NSString *realJid = [reader objectForColumnIndex:15];
            
            NSMutableDictionary *msgDic = [[NSMutableDictionary alloc] init];
            
            [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
            [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
            [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
            [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
            [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
            [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
            [IMDataManager safeSaveForDic:msgDic setObject:chatType forKey:@"ChatType"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgState forKey:@"MsgState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDirection forKey:@"MsgDirection"];
            [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
            [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
            [IMDataManager safeSaveForDic:msgDic setObject:msgRaw forKey:@"MsgRaw"];
            [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
            
            [msgs addObject:msgDic];
        }
    }];
    QIMVerboseLog(@"");
    return msgs;
}

@end
