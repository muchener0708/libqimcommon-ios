//
//  IMDataManager+QIMDBUser.m
//  QIMCommon
//
//  Created by 李露 on 11/24/18.
//  Copyright © 2018 QIM. All rights reserved.
//

#import "IMDataManager+QIMDBUser.h"
#import "Database.h"
#import "QIMPublicRedefineHeader.h"

@implementation IMDataManager (QIMDBUser)

- (void)qimDB_bulkInsertOrgansUserInfos:(NSArray *)userInfos {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        /*
         //创建用户表
         result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Users(\
         UserId                TEXT,\
         XmppId                TEXT PRIMARY KEY,\
         Name                  TEXT,\
         DescInfo              TEXT,\
         HeaderSrc             TEXT,\
         SearchIndex           TEXT,\
         UserInfo              BLOB,\
         Mood                  TEXT,\
         LastUpdateTime        INTEGER,\
         Sex                   INTEGER,\
         UType                 INTEGER,\
         Email                 Email,\
         IncrementVersion      INTEGER,\
         ExtendedFlag          BLOB\
         );"
         withParameters:nil];
         */
        
        NSString *sql = @"insert or Replace into IM_Users(UserId, XmppId, Name, DescInfo, HeaderSrc, SearchIndex, UserInfo, LastUpdateTime, Sex, UType, Email) values(:UserID, :XmppId, :Name, :DescInfo, :HeaderSrc, :SearchIndex, :UserInfo, :LastUpdateTime, :Sex, :UType, :Email);";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *infoDic in userInfos) {
            NSString *userId = [infoDic objectForKey:@"U"];
            NSString *xmppId = [NSString stringWithFormat:@"%@@%@",userId, @"ejabhost1"];
            NSString *Name = [infoDic objectForKey:@"N"];
            Name = [Name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *DescInfo = [infoDic objectForKey:@"D"];
            NSString *HeaderSrc = @":NULL";
            NSString *pinyin = [infoDic objectForKey:@"pinyin"];
            NSString *UserInfo = @":NULL";
            NSString *LastUpdateTime = @"0";
            NSNumber *sex = [infoDic objectForKey:@"sex"];
            NSString *uType = [infoDic objectForKey:@"uType"];
            NSString *email = [infoDic objectForKey:@"email"];
            
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:userId];
            [param addObject:xmppId];
            [param addObject:(Name.length > 0) ? Name : userId];
            [param addObject:DescInfo];
            [param addObject:HeaderSrc];
            [param addObject:pinyin];
            [param addObject:UserInfo];
            [param addObject:LastUpdateTime];
            [param addObject:sex];
            [param addObject:uType];
            [param addObject:(email.length > 0) ? email : @":NULL"];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
}

- (NSString *)qimDB_getTimeSmtapMsgIdForDate:(NSDate *)date WithUserId:(NSString *)userId{
    if (self.timeSmtapFormatter) {
        NSString *dateStr = [self.timeSmtapFormatter stringFromDate:date];
        NSString *timeSmtapMsgId = [NSString stringWithFormat:@"Time Smtap %@ For %@",dateStr,userId];
        return timeSmtapMsgId;
    }
    return @"";
}

- (void)qimDB_bulkUpdateUserSearchIndexs:(NSArray *)searchIndexs{
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Users Set SearchIndex = :SearchIndex Where UserId=:UserId;";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *searchIndexDic in searchIndexs) {
            NSString *userId = [searchIndexDic objectForKey:@"U"];
            NSMutableString *searchIndex = [[NSMutableString alloc] init];
            for (NSString *str in searchIndexDic.allValues) {
                [searchIndex appendString:str];
                [searchIndex appendString:@"|"];
            }
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:searchIndex];
            [param addObject:userId];
            [params addObject:param];
            [param release];
            param = nil;
            [searchIndex release];
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
}

- (void)qimDB_bulkInsertUserInfosNotSaveDescInfo:(NSArray *)userInfos{
    
    if (userInfos.count <= 0) {
        return;
    }
    [[self dbInstance] usingTransaction:^(Database *database) {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        NSString *sql = @"insert or Replace into IM_Users(UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime) values(:UserID, :XmppId, :Name, :DescInfo, :HeaderSrc, :UserInfo, :LastUpdateTime);";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *infoDic in userInfos) {
            NSString *userId = [infoDic objectForKey:@"U"];
            NSString *domain = [infoDic objectForKey:@"Domain"];
            NSString *xmppId = [NSString stringWithFormat:@"%@@%@",userId, (domain.length > 0) ? domain : [self getDBOwnerDomain]];
            NSString *Name = [infoDic objectForKey:@"N"];
            NSString *DescInfo = [infoDic objectForKey:@"D"];
            NSString *HeaderSrc = @":NULL";
            NSString *UserInfo = @":NULL";
            NSInteger LastUpdateTime = [[infoDic objectForKey:@"V"] integerValue];
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:userId ? userId : @""];
            [param addObject:xmppId ? xmppId : @""];
            [param addObject:Name ? Name : @""];
            [param addObject:DescInfo ? DescInfo : @":NULL"];
            [param addObject:HeaderSrc ? HeaderSrc : @""];
            [param addObject:UserInfo ? UserInfo : @""];
            [param addObject:@(0)];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        QIMVerboseLog(@"更新组织架构%ld条数据 耗时 = %f s", userInfos.count, end - start); //s
    }];
}

- (void)qimDB_bulkUpdateUserBackInfo:(NSDictionary *)userBackInfo WithXmppId:(NSString *)xmppId {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *insertSql = @"insert or replace into IM_UsersWorkInfo(XmppId, UserWorkInfo, LastUpdateTime) values(:XmppId, :UserWorkInfo, :LastUpdateTime);";
        NSString *userWorkInfoStr = [userBackInfo objectForKey:@"UserWorkInfo"];
        NSDate *nowDate = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
        NSTimeInterval time=[nowDate timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
        
        NSMutableArray *insertParam = [[NSMutableArray alloc] init];
        [insertParam addObject:xmppId?xmppId:@":NULL"];
        [insertParam addObject:userWorkInfoStr?userWorkInfoStr:@":NULL"];
        [insertParam addObject:@(time)];
        
        [database executeNonQuery:insertSql withParameters:insertParam];
        [insertParam release];
        insertParam = nil;
    }];
}

- (void)qimDB_InsertOrUpdateUserInfos:(NSArray *)userInfos{
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"insert or replace into IM_Users(UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime) values(:UserID, :XmppId, :Name, :DescInfo, :HeaderSrc, :UserInfo, :LastUpdateTime);";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *infoDic in userInfos) {
            NSString *userId = [infoDic objectForKey:@"U"];
            NSString *xmppId = [NSString stringWithFormat:@"%@@%@",userId, [self getDBOwnerDomain]];
            NSString *Name = [infoDic objectForKey:@"N"];
            NSString *DescInfo = [infoDic objectForKey:@"D"] ? [infoDic objectForKey:@"D"] : @":NULL";
            NSString *HeaderSrc = [infoDic objectForKey:@"H"] ? [infoDic objectForKey:@"H"] : @":NULL";
            NSString *UserInfo = @":NULL";
            NSString *LastUpdateTime = @"0";
            
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:userId];
            [param addObject:xmppId];
            [param addObject:Name];
            [param addObject:DescInfo];
            [param addObject:HeaderSrc];
            [param addObject:UserInfo];
            [param addObject:LastUpdateTime];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
}

- (NSDictionary *)qimDB_selectUserByJID:(NSString *)jid{
    if (jid == nil) {
        return nil;
    }
    __block NSMutableDictionary *user = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql = @"Select UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime, SearchIndex, Mood from IM_Users Where XmppId = :XmppId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:jid];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        if ([reader read]) {
            user = [[NSMutableDictionary alloc] init];
            NSString *userId = [reader objectForColumnIndex:0];
            NSString *XmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSData *data = [reader objectForColumnIndex:5];
            NSNumber *dateTime = [reader objectForColumnIndex:6];
            NSString *searchIndex = [reader objectForColumnIndex:7];
            NSString *mood = [reader objectForColumnIndex:8];
            
            [IMDataManager safeSaveForDic:user setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:user setObject:XmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:user setObject:name?name:userId forKey:@"Name"];
            [IMDataManager safeSaveForDic:user setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:user setObject:headerSrc forKey:@"HeaderSrc"];
            [IMDataManager safeSaveForDic:user setObject:data forKey:@"UserInfo"];
            [IMDataManager safeSaveForDic:user setObject:dateTime forKey:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:user setObject:searchIndex forKey:@"SearchIndex"];
            [IMDataManager safeSaveForDic:user setObject:mood forKey:@"Mood"];
        }
    }];
    return [user autorelease];
}

- (void)qimDB_clearUserList {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSMutableString *deleteSql = [NSMutableString stringWithString:@"Delete From IM_Users"];
        [database executeNonQuery:deleteSql withParameters:nil];
    }];
}

- (void)qimDB_clearUserListForList:(NSArray *)userInfos{
    if (userInfos.count <= 0) {
        return;
    }
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSMutableString *deleteSql = [NSMutableString stringWithString:@"Delete From IM_Users Where UserId in ("];
        for (NSDictionary *infoDic in userInfos) {
            NSString *userId = [infoDic objectForKey:@"U"];
            if (userId) {
                [deleteSql appendFormat:@"'%@',",userId];
            }
        }
        [deleteSql deleteCharactersInRange:NSMakeRange(deleteSql.length - 1, 1)];
        [deleteSql appendString:@");"];
        [database executeNonQuery:deleteSql withParameters:nil];
    }];
}

- (void)qimDB_bulkInsertUserInfos:(NSArray *)userInfos{
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"insert or Replace into IM_Users(UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime) values(:UserID, :XmppId, :Name, :DescInfo, :HeaderSrc, :UserInfo, :LastUpdateTime);";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        for (NSDictionary *infoDic in userInfos) {
            NSString *userId = [infoDic objectForKey:@"U"];
            NSString *xmppId = [NSString stringWithFormat:@"%@@%@", userId, [self getDBOwnerDomain]];
            NSString *Name = [infoDic objectForKey:@"N"];
            NSString *DescInfo = [infoDic objectForKey:@"D"];
            NSString *HeaderSrc = @":NULL";
            NSString *UserInfo = @":NULL";
            NSString *LastUpdateTime = @"0";
            
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:userId];
            [param addObject:xmppId];
            [param addObject:Name];
            [param addObject:DescInfo];
            [param addObject:HeaderSrc];
            [param addObject:UserInfo];
            [param addObject:LastUpdateTime];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
}

- (void)qimDB_updateUser:(NSString *)userId WithHeaderSrc:(NSString *)headerSrc WithVersion:(NSString *)version{
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    [[self dbInstance] usingTransaction:^(Database *database) {
        NSString *sql = @"Update IM_Users Set HeaderSrc = :HeaderSrc,LastUpdateTime = :LastUpdateTime Where UserId=:UserId;";
        NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:3];
        [param addObject:headerSrc?headerSrc:@":NULL"];
        [param addObject:version];
        [param addObject:userId];
        [database executeNonQuery:sql withParameters:param];
        [param release];
        param = nil;
    }];
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    QIMVerboseLog(@"更新用户信息 耗时 = %f s userId : %@, headerSrc: %@, version: %@", end - start, userId, headerSrc, version); //s
}

- (void)qimDB_bulkUpdateUserCards:(NSArray *)cards{
    [[self dbInstance] usingTransaction:^(Database *database) {
        NSString *insertSql = @"insert or IGNORE into IM_Users(UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime, Mood) values(:UserID, :XmppId, :Name, :DescInfo, :HeaderSrc, :UserInfo, :LastUpdateTime, :Mood);";
        NSString *sql = @"Update IM_Users Set Name = (CASE WHEN :Name ISNULL then Name else :Name1 end), DescInfo = (CASE WHEN :DescInfo ISNULL then DescInfo else :DescInfo1 end), HeaderSrc = :HeaderSrc, UserInfo = :UserInfo, LastUpdateTime=:LastUpdateTime, Mood=:Mood Where XmppId = :XmppId;";
        NSMutableArray *params = [[NSMutableArray alloc] init];
        NSMutableArray *insertParams = [[NSMutableArray alloc] init];
        for (NSDictionary *userDic in cards) {
            NSString *userId = [userDic objectForKey:@"U"];
            NSString *xmppId = [userDic objectForKey:@"X"];
            NSString *Name = [userDic objectForKey:@"N"];
            if ([Name isKindOfClass:[NSNull class]] || Name.length <=0 || [Name.lowercaseString isEqualToString:@"undefined"]) {
                Name = @":NULL";
            }
            NSString *DescInfo = [userDic objectForKey:@"D"];
            if ([DescInfo isKindOfClass:[NSNull class]] || DescInfo.length <=0 || [DescInfo.lowercaseString isEqualToString:@"undefined"]) {
                DescInfo = @":NULL";
            }
            NSString *HeaderSrc = [userDic objectForKey:@"H"];
            NSString *UserInfo = [userDic objectForKey:@"I"];
            NSString *LastUpdateTime = [userDic objectForKey:@"V"];
            NSString *mood = [userDic objectForKey:@"mood"];
            
            NSMutableArray *insertParam = [[NSMutableArray alloc] init];
            [insertParam addObject:userId?userId:@":NULL"];
            [insertParam addObject:xmppId?xmppId:@":NULL"];
            [insertParam addObject:Name?Name:@":NULL"];
            [insertParam addObject:DescInfo?DescInfo:@":NULL"];
            [insertParam addObject:HeaderSrc?HeaderSrc:@":NULL"];
            [insertParam addObject:UserInfo?UserInfo:@":NULL"];
            [insertParam addObject:LastUpdateTime];
            [insertParam addObject:mood?mood:@":NULL"];
            [insertParams addObject:insertParam?insertParam:@":NULL"];
            [insertParam release];
            insertParam = nil;
            
            NSMutableArray *param = [[NSMutableArray alloc] initWithCapacity:11];
            [param addObject:Name?Name:@":NULL"];
            [param addObject:Name?Name:@":NULL"];
            [param addObject:DescInfo?DescInfo:@":NULL"];
            [param addObject:DescInfo?DescInfo:@":NULL"];
            [param addObject:HeaderSrc?HeaderSrc:@":NULL"];
            [param addObject:UserInfo?UserInfo:@":NULL"];
            [param addObject:LastUpdateTime];
            [param addObject:mood?mood:@":NULL"];
            [param addObject:xmppId?xmppId:@":NULL"];
            [params addObject:param];
            [param release];
            param = nil;
        }
        [database executeBulkInsert:insertSql withParameters:insertParams];
        [insertParams release];
        [database executeBulkInsert:sql withParameters:params];
        [params release];
    }];
}

- (NSString *)qimDB_getUserHeaderSrcByUserId:(NSString *)userId{
    
    if (userId == nil) {
        return nil;
    }
    __block NSString *headerSrc = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select HeaderSrc From IM_Users Where XmppId=:XmppId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:userId];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        param = nil;
        if ([reader read]) {
            headerSrc = [[reader objectForColumnIndex:0] retain];
        }
    }];
    return [headerSrc autorelease];
}

- (NSDictionary *)qimDB_selectUserByID:(NSString *)userId{
    if (userId == nil) {
        return nil;
    }
    __block NSMutableDictionary *user = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql = @"Select UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime, Mood from IM_Users Where UserId = :UserId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:userId];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        if ([reader read]) {
            user = [[NSMutableDictionary alloc] init];
            NSString *userId = [reader objectForColumnIndex:0];
            NSString *XmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSData *data = [reader objectForColumnIndex:5];
            NSNumber *dateTime = [reader objectForColumnIndex:6];
            NSString *mood = [reader objectForColumnIndex:7];
            
            [IMDataManager safeSaveForDic:user setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:user setObject:XmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:user setObject:name?name:userId forKey:@"Name"];
            [IMDataManager safeSaveForDic:user setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:user setObject:headerSrc forKey:@"HeaderSrc"];
            [IMDataManager safeSaveForDic:user setObject:data forKey:@"UserInfo"];
            [IMDataManager safeSaveForDic:user setObject:dateTime forKey:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:user setObject:mood forKey:@"Mood"];
        }
    }];
    return [user autorelease];
}

- (NSDictionary *)qimDB_selectUserBackInfoByXmppId:(NSString *)xmppId {
    if (!xmppId) {
        return nil;
    }
    __block NSMutableDictionary *userBackInfo = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"SELECT *from IM_UsersWorkInfo Where XmppId = :XmppId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:xmppId];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        if ([reader read]) {
            userBackInfo = [[NSMutableDictionary alloc] init];
            NSString *workInfo = [reader objectForColumnName:@"UserWorkInfo"];
            NSNumber *dateTime = [reader objectForColumnName:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:userBackInfo setObject:workInfo forKey:@"UserWorkInfo"];
            [IMDataManager safeSaveForDic:userBackInfo setObject:dateTime forKey:@"LastUpdateTime"];
        }
    }];
    return [userBackInfo autorelease];
}

- (NSDictionary *)qimDB_selectUserByIndex:(NSString *)index{
    if (index == nil) {
        return nil;
    }
    __block NSMutableDictionary *user = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql = @"Select UserId, XmppId, Name, DescInfo, HeaderSrc, SearchIndex, LastUpdateTime, Mood from IM_Users Where Name = :Name OR UserId = :UserId OR XmppId = :XmppId;";
        NSMutableArray *param = [[NSMutableArray alloc] init];
        [param addObject:index];
        [param addObject:index];
        [param addObject:index];
        DataReader *reader = [database executeReader:sql withParameters:param];
        [param release];
        if ([reader read]) {
            user = [[NSMutableDictionary alloc] init];
            NSString *userId = [reader objectForColumnIndex:0];
            NSString *XmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSString *searchIndex = [reader objectForColumnIndex:5];
            NSNumber *dateTime = [reader objectForColumnIndex:6];
            NSString *mood = [reader objectForColumnIndex:7];
            
            [IMDataManager safeSaveForDic:user setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:user setObject:XmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:user setObject:name?name:userId forKey:@"Name"];
            [IMDataManager safeSaveForDic:user setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:user setObject:headerSrc forKey:@"HeaderSrc"];
            [IMDataManager safeSaveForDic:user setObject:searchIndex forKey:@"SearchIndex"];
            [IMDataManager safeSaveForDic:user setObject:dateTime forKey:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:user setObject:mood forKey:@"Mood"];
        }
    }];
    return [user autorelease];
}

- (NSArray *)qimDB_selectXmppIdFromSessionList {
    __block NSMutableArray *list = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select XmppId From IM_SessionList Where XmppId not like '%conference.%'";
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            if (list == nil) {
                list = [[NSMutableArray alloc] init];
            }
            [list addObject:[reader objectForColumnIndex:0]];
        }
    }];
    return [list autorelease];
}

- (NSArray *)qimDB_selectXmppIdList{
    __block NSMutableArray *list = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select XmppId From IM_Users;";
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            if (list == nil) {
                list = [[NSMutableArray alloc] init];
            }
            [list addObject:[reader objectForColumnIndex:0]];
        }
    }];
    return [list autorelease];
}

- (NSArray *)qimDB_selectUserIdList{
    __block NSMutableArray *list = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select UserId From IM_Users;";
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            if (list == nil) {
                list = [[NSMutableArray alloc] init];
            }
            [list addObject:[reader objectForColumnIndex:0]];
        }
    }];
    return [list autorelease];
}

- (NSArray *)qimDB_getOrganUserList {
    __block NSMutableArray *list = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select UserId, XmppId, Name, DescInfo, HeaderSrc, SearchIndex, UserInfo, Mood, LastUpdateTime From IM_Users;";
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            if (list == nil) {
                list = [[NSMutableArray alloc] init];
            }
            NSString *userId = [reader objectForColumnIndex:0];
            NSString *XmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSString *searchIndex = [reader objectForColumnIndex:5];
            NSNumber *dateTime = [reader objectForColumnIndex:6];
            NSString *mood = [reader objectForColumnIndex:7];
            
            NSMutableDictionary *user = [[NSMutableDictionary alloc] init];
            [IMDataManager safeSaveForDic:user setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:user setObject:XmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:user setObject:name?name:userId forKey:@"Name"];
            [IMDataManager safeSaveForDic:user setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:user setObject:headerSrc forKey:@"HeaderSrc"];
            [IMDataManager safeSaveForDic:user setObject:searchIndex forKey:@"SearchIndex"];
            [IMDataManager safeSaveForDic:user setObject:dateTime forKey:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:user setObject:mood forKey:@"Mood"];
            
            [list addObject:user];
            [user release];
        }
    }];
    return [list autorelease];
}

//Select a.UserId, a.XmppId, a.Name, a.DescInfo, a.HeaderSrc, a.UserInfo, a.LastUpdateTime from IM_Group_Member as b left join IM_Users as a on a.Name = b.Name where GroupId = 'qtalk客户端开发群@conference.ejabhost1'

- (NSArray *)qimDB_selectUserListBySearchStr:(NSString *)searchStr inGroup:(NSString *) groupId {
    __block NSMutableArray *list = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"Select a.UserId, a.XmppId, a.Name, a.DescInfo, a.HeaderSrc, a.UserInfo, a.LastUpdateTime from IM_Group_Member as b left join IM_Users as a on a.Name = b.Name and (a.UserId like '%%%@%%' OR a.Name like '%%%@%%' OR a.SearchIndex like '%%%@%%') WHERE GroupId = ?;",searchStr,searchStr,searchStr];
        
        DataReader *reader = [database executeReader:sql withParameters:[NSArray arrayWithObject:groupId]];
        if (list == nil) {
            list = [[NSMutableArray alloc] init];
        }
        while ([reader read]) {
            NSString *userId = [reader objectForColumnIndex:0];
            if (userId == nil) {
                continue;
            }
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [IMDataManager safeSaveForDic:dic setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:dic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:dic setObject:name forKey:@"Name"];
            [IMDataManager safeSaveForDic:dic setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:dic setObject:headerSrc forKey:@"HeaderSrc"];
            [list addObject:dic];
        }
    }];
    return [list autorelease];
}

- (NSArray *)qimDB_searchUserBySearchStr:(NSString *)searchStr notInGroup:(NSString *)groupId {
    __block NSMutableArray *list = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"select *from IM_Users as a where a.XmppId not in (select MemberJid from IM_Group_Member where GroupId='%@') and (a.UserId like '%%%@%%' OR a.Name like '%%%@%%' OR a.SearchIndex like '%%%@%%');", groupId, searchStr,searchStr,searchStr];
        
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if (list == nil) {
            list = [[NSMutableArray alloc] init];
        }
        while ([reader read]) {
            NSString *userId = [reader objectForColumnIndex:0];
            if (userId == nil) {
                continue;
            }
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [IMDataManager safeSaveForDic:dic setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:dic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:dic setObject:name forKey:@"Name"];
            [IMDataManager safeSaveForDic:dic setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:dic setObject:headerSrc forKey:@"HeaderSrc"];
            [list addObject:dic];
        }
    }];
    return [list autorelease];
}

- (NSArray *)qimDB_selectUserListBySearchStr:(NSString *)searchStr {
    return [self qimDB_selectUserListBySearchStr:searchStr WithLimit:-1 WithOffset:-1];
}

- (NSInteger)qimDB_selectUserListTotalCountBySearchStr:(NSString *)searchStr {
    return [[self qimDB_selectUserListBySearchStr:searchStr] count];
}

- (NSArray *)qimDB_selectUserListBySearchStr:(NSString *)searchStr WithLimit:(NSInteger)limit WithOffset:(NSInteger)offset {
    __block NSMutableArray *list = nil;
    __block NSMutableArray *firstlist = [NSMutableArray array];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
        NSString *sql = [NSString stringWithFormat:@"Select UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime,SearchIndex from IM_Users as a LEFT JOIN (select *from IM_Client_Config where ConfigValue like '%%%@%%' and ConfigKey='kMarkupNames') as b where (a.XmppId=b.ConfigSubKey or a.UserId like '%%%@%%' OR a.Name like '%%%@%%' OR a.SearchIndex like '%%%@%%')", searchStr, searchStr, searchStr, searchStr];
        if (limit != -1 && offset != -1) {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@"LIMIT %ld OFFSET %ld", (long)limit, (long)offset]];
        }
        NSLog(@"search Sql : %@", sql);
        DataReader *reader = [database executeReader:sql withParameters:nil];
        while ([reader read]) {
            if (list == nil) {
                list = [[NSMutableArray alloc] init];
            }
            NSString *userId = [reader objectForColumnIndex:0];
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSString *searchIndex = [reader objectForColumnIndex:7];
            
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [IMDataManager safeSaveForDic:dic setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:dic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:dic setObject:name forKey:@"Name"];
            [IMDataManager safeSaveForDic:dic setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:dic setObject:headerSrc forKey:@"HeaderSrc"];
            searchIndex = [NSString stringWithFormat:@"|%@",searchIndex];
            if ([userId isEqualToString:searchStr] || [xmppId isEqualToString:searchStr] || [name isEqualToString:searchStr] || [searchIndex rangeOfString:[NSString stringWithFormat:@"|%@|",searchStr] options:NSCaseInsensitiveSearch].location != NSNotFound ) {
                [firstlist addObject:dic];
            } else {
                [list addObject:dic];
            }
        }
    }];
    
    if (firstlist.count > 0) {
        [list insertObjects:firstlist atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, firstlist.count)]];
    }
    return [list autorelease];
}

- (NSDictionary *)qimDB_selectUsersDicByXmppIds:(NSArray *)xmppIds{
    __block NSMutableDictionary *usersDic = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"Select UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime,SearchIndex from IM_Users Where XmppId in ("];
        NSString *lastXmppId = [xmppIds lastObject];
        for (NSString *xmppId in xmppIds) {
            if ([lastXmppId isEqualToString:xmppId]) {
                [sql appendFormat:@"'%@');",xmppId];
            } else {
                [sql appendFormat:@"'%@',",xmppId];
            }
        }
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if (usersDic == nil) {
            usersDic = [[NSMutableDictionary alloc] init];
        }
        while ([reader read]) {
            NSString *userId = [reader objectForColumnIndex:0];
            if (userId == nil)
                continue;
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSString *userInfo = [reader objectForColumnIndex:5];
            NSNumber *lastUpdateTime = [reader objectForColumnIndex:6];
            NSString *searchIndex = [reader objectForColumnIndex:7];
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [IMDataManager safeSaveForDic:dic setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:dic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:dic setObject:name forKey:@"Name"];
            [IMDataManager safeSaveForDic:dic setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:dic setObject:headerSrc forKey:@"HeaderSrc"];
            [IMDataManager safeSaveForDic:dic setObject:userInfo forKey:@"UserInfo"];
            [IMDataManager safeSaveForDic:dic setObject:lastUpdateTime forKey:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:dic setObject:searchIndex forKey:@"SearchIndex"];
            [usersDic setObject:dic forKey:xmppId];
        }
    }];
    return [usersDic autorelease];
}

- (NSArray *)qimDB_selectUserListByUserIds:(NSArray *)userIds{
    __block NSMutableArray *list = nil;
    if (userIds.count <= 0) {
        return nil;
    }
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"Select UserId, XmppId, Name, DescInfo, HeaderSrc, UserInfo,LastUpdateTime,SearchIndex from IM_Users Where UserId in ("];
        NSString *lastUserId = [userIds lastObject];
        for (NSString *userId in userIds) {
            if ([lastUserId isEqualToString:userId]) {
                [sql appendFormat:@"'%@');",userId];
            } else {
                [sql appendFormat:@"'%@',",userId];
            }
        }
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if (list == nil) {
            list = [[NSMutableArray alloc] init];
        }
        while ([reader read]) {
            NSString *userId = [reader objectForColumnIndex:0];
            if (userId == nil)
                continue;
            NSString *xmppId = [reader objectForColumnIndex:1];
            NSString *name = [reader objectForColumnIndex:2];
            NSString *descInfo = [reader objectForColumnIndex:3];
            NSString *headerSrc = [reader objectForColumnIndex:4];
            NSString *userInfo = [reader objectForColumnIndex:5];
            NSNumber *lastUpdateTime = [reader objectForColumnIndex:6];
            NSString *searchIndex = [reader objectForColumnIndex:7];
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [IMDataManager safeSaveForDic:dic setObject:userId forKey:@"UserId"];
            [IMDataManager safeSaveForDic:dic setObject:xmppId forKey:@"XmppId"];
            [IMDataManager safeSaveForDic:dic setObject:name forKey:@"Name"];
            [IMDataManager safeSaveForDic:dic setObject:descInfo forKey:@"DescInfo"];
            [IMDataManager safeSaveForDic:dic setObject:headerSrc forKey:@"HeaderSrc"];
            [IMDataManager safeSaveForDic:dic setObject:userInfo forKey:@"UserInfo"];
            [IMDataManager safeSaveForDic:dic setObject:lastUpdateTime forKey:@"LastUpdateTime"];
            [IMDataManager safeSaveForDic:dic setObject:searchIndex forKey:@"SearchIndex"];
            [list addObject:dic];
        }
    }];
    return [list autorelease];
}

- (BOOL)qimDB_checkExitsUser {
    __block BOOL exits = NO;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"Select UserId From IM_Users Limit 1;";
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if ([reader read]) {
            exits = YES;
        }
    }];
    return exits;
}

@end
