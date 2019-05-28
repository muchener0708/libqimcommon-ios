
//
//  IMDataManager.m
//  qunarChatIphone
//
//  Created by ping.xue on 14-3-19.
//  Copyright (c) 2014年 ping.xue. All rights reserved.
//

#import "IMDataManager.h"
#import "Database.h"
#import "QIMDBLogger.h"
#import "QIMWatchDog.h"
#import "IMDataManager+QIMDBMessage.h"

static IMDataManager *__global_data_manager = nil;
@interface IMDataManager()
@end

@implementation IMDataManager{
    NSString *_dbPath;
    NSString *_dbOwnerDomain;
    NSString *_dbOwnerFullJid;
    NSDateFormatter *_timeSmtapFormatter;
}

+ (IMDataManager *)qimDB_SharedInstance {
    return __global_data_manager;
}

- (void)setdbPath:(NSString *)dbPath {
    _dbPath = dbPath;
}

- (void)setDBOwnerFullJid:(NSString *)dbFullJid {
    _dbOwnerFullJid = dbFullJid;
}

static dispatch_once_t _onceDBToken;
+ (IMDataManager *) qimDB_sharedInstanceWithDBPath:(NSString *)dbPath withDBFullJid:(NSString *)dbOwnerFullJid {

    dispatch_once(&_onceDBToken, ^{
        __global_data_manager = [[IMDataManager alloc] initWithDBPath:dbPath];
        [__global_data_manager setdbPath:dbPath];
        [__global_data_manager setDBOwnerFullJid:dbOwnerFullJid];
        [__global_data_manager setDomain:[[dbOwnerFullJid componentsSeparatedByString:@"@"] lastObject]];
        __global_data_manager.dataBasePoolManager = [QIMDataBaseQueueManager databasePoolWithPath:dbPath];
        [__global_data_manager openDB];
    });
    return __global_data_manager;
}

- (id)dataBasePoolManager {
    return _dataBasePoolManager;
}

- (NSString *)getDbOwnerFullJid {

    return _dbOwnerFullJid;
}

- (void)setDomain:(NSString*)domain{
    _dbOwnerDomain = domain;
}

- (NSString *)getDBOwnerDomain {
    return _dbOwnerDomain;
}

- (NSString *) OriginalUUID {
    CFUUIDRef UUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDString = CFUUIDCreateString(kCFAllocatorDefault, UUID);
    NSString *result = [[NSString alloc] initWithString:(__bridge NSString*)UUIDString];
    if (UUID)
    CFRelease(UUID);
    if (UUIDString)
    CFRelease(UUIDString);
    return result;
}

- (NSString *)UUID{
    return [[self OriginalUUID] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}


- (id)initWithDBPath:(NSString *)dbPath{
    self = [super init];
    if (self) {
        
        _dbPath = [dbPath copy];
        
        _timeSmtapFormatter = [[NSDateFormatter alloc] init];
        [_timeSmtapFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        
        QIMVerboseLog(@"DB Path %@", _dbPath);
        
    }
    return self;
}

- (void)openDB {
    DatabaseOperator *op = [_dataBasePoolManager getDatabaseOperator];
    Database *dataBase = op.database;
    BOOL isSuccess = [dataBase open:_dbPath usingCurrentThread:YES];
    if (isSuccess == NO) {
        // 防止数据库文件无效 But 有一种数据库文件能打开 缺不是有效文件 不知怎么解
        [[NSFileManager defaultManager] removeItemAtPath:_dbPath error:nil];
        [self reCreateDB];
    } else {
        
    }
    
    [self reCreateDB];
//    [self initSQLiteLog];
    [self qimDB_updateMsgTimeToMillSecond];
}

- (void)reCreateDB {
    BOOL notCheckCreateDataBase = [[NSFileManager defaultManager] fileExistsAtPath:_dbPath] == NO;
    NSArray *paths = [_dbPath pathComponents];
    NSString *dbValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"dbVersion"];
    NSString *currentValue = [NSString stringWithFormat:@"%@_%lld",[paths objectAtIndex:paths.count-2] , [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] longLongValue]];
    if (notCheckCreateDataBase || [currentValue isEqualToString:dbValue] == NO) {
        QIMVerboseLog(@"reCreateDB");
        __block BOOL result = NO;
        [[self dbInstance] syncUsingTransaction:^(Database *database) {
            result = [self createDb:database];
        }];
        if (result) {
            QIMVerboseLog(@"创建DB文件成功");
            [self insertUserCacheData];
            [[NSUserDefaults standardUserDefaults] setObject:currentValue forKey:@"dbVersion"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            QIMVerboseLog(@"创建DB文件失败");
        }
    } else {
        QIMVerboseLog(@"notCheckCreateDataBase : %d, [currentValue isEqualToString:dbValue] : %d", notCheckCreateDataBase, [currentValue isEqualToString:dbValue]);
    }
}

- (void)initSQLiteLog {
    QIMDBLogger *sqliteLogger = [[QIMDBLogger alloc] initWithLogDirectory:[self sqliteLogFilesDirectory] WithDBOperator:[self dbInstance]];
    sqliteLogger.saveThreshold     = 500;
    sqliteLogger.saveInterval      = 60;               // 60 seconds
    sqliteLogger.maxAge            = 60 * 60 * 24 * 7; //  7 days
    sqliteLogger.deleteInterval    = 60 * 5;           //  5 minutes
    sqliteLogger.deleteOnEverySave = NO;
    
    [DDLog addLogger:sqliteLogger];
}

- (NSString *)sqliteLogFilesDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    
    return [basePath stringByAppendingPathComponent:@"SQLiteLogger"];
}

- (void)insertUserCacheData {
    [self qimDB_InsertUserCacheDataWithKey:@"singlelastupdatetime" withType:10 withValue:@"单人聊天时间戳" withValueInt:0];
    [self qimDB_InsertUserCacheDataWithKey:@"grouplastupdatetime" withType:10 withValue:@"群聊聊天时间戳" withValueInt:0];
    [self qimDB_InsertUserCacheDataWithKey:@"systemlastupdatetime" withType:10 withValue:@"系统聊天时间戳" withValueInt:0];
}

- (void)qimDB_InsertUserCacheDataWithKey:(NSString *)key withType:(NSInteger)type withValue:(NSString *)value withValueInt:(long long)valueInt {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"insert or IGNORE into IM_Cache_Data(key, type, value, valueInt) Values(:key, :type, :value, :valueInt);";
        NSMutableArray *parames = [[NSMutableArray alloc] init];
        [parames addObject:key];
        [parames addObject:@(type)];
        [parames addObject:value?value:@":NULL"];
        [parames addObject:@(valueInt)];
        [database executeNonQuery:sql withParameters:parames];
    }];
}

- (void)qimDB_UpdateUserCacheDataWithKey:(NSString *)key withType:(NSInteger)type withValue:(NSString *)value withValueInt:(long long)valueInt {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"insert or replace into IM_Cache_Data(key, type, value, valueInt) Values(:key, :type, :value, :valueInt);";
        NSMutableArray *parames = [[NSMutableArray alloc] init];
        [parames addObject:key];
        [parames addObject:@(type)];
        [parames addObject:value?value:@":NULL"];
        [parames addObject:@(valueInt)];
        [database executeNonQuery:sql withParameters:parames];
    }];
}

- (long long)qimDB_getUserCacheDataWithKey:(NSString *)key withType:(NSInteger)type {
    __block long long maxRemoteTime = 0;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *newSql = [NSString stringWithFormat:@"select valueInt from IM_Cache_Data Where key == '%@' and type == %d", key, type];
        DataReader *newReader = [database executeReader:newSql withParameters:nil];
        if ([newReader read]) {
            maxRemoteTime = [[newReader objectForColumnIndex:0] longLongValue];
        }
    }];
    return maxRemoteTime;
}

- (BOOL)qimDB_checkExistUserCacheDataWithKey:(NSString *)key withType:(NSInteger)type {
    __block BOOL exist = NO;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        
    }];
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = [NSString stringWithFormat:@"select 1 from IM_Cache_Data Where key == '%@' and type == %d", key, type];
        DataReader *reader = [database executeReader:sql withParameters:nil];
        if ([reader read]) {
            exist = YES;
        }
    }];
    return exist;
}

- (DatabaseOperator *)dbInstance {
    return [self.dataBasePoolManager getDatabaseOperator];
}

+ (void)safeSaveForDic:(NSMutableDictionary *)dic setObject:(id)value forKey:(id)key{
    if (dic && value && key) {
        [dic setObject:value forKey:key];
    }
}

- (BOOL)createDb:(Database *)database {
    BOOL result = NO;
    
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
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_Users_USERID ON \
                  IM_Users(UserId);" withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_Users_XMPPID ON \
                  IM_Users(XmppId);" withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_Users_NAME ON \
                  IM_Users(Name);" withParameters:nil];
    }
    
    //创建群组列表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Group(\
              GroupId               TEXT PRIMARY KEY,\
              Name                  TEXT,\
              Introduce             TEXT,\
              HeaderSrc             TEXT,\
              Topic                 TEXT,\
              LastUpdateTime        INTEGER,\
              MsgState              INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
       
    }
    
    //创建群成员列表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Group_Member(\
              MemberId              TEXT PRIMARY KEY,\
              GroupId               TEXT,\
              MemberJid             TEXT,\
              Name                  TEXT,\
              Affiliation           TEXT,\
              LastUpdateTime        INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_GROUP_MEMBER_MEMBERID ON \
                  IM_Group_Member(MemberId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_GROUP_MEMBER_GROUPID ON \
                  IM_Group_Member(GroupId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE unique index IF NOT EXISTS IX_IM_GROUP_MEMBER_GROUPID_JID_UINDEX ON \
                  IM_Group_Member(GroupId,MemberJid);"
                            withParameters:nil];
    }
    
    //创建消息列表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_SessionList(\
              XmppId                TEXT,\
              RealJid               TEXT,\
              UserId                TEXT,\
              LastMessageId         TEXT,\
              LastUpdateTime        INTEGER,\
              ChatType              INTEGER,\
              ExtendedFlag          BLOB,\
              UnreadCount           INTEGER DEFAULT 0,\
              primary key (XmppId,RealJid));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_SESSION_MESSAGEID ON \
                  IM_SessionList(LastMessageId);"
                            withParameters:nil];
    }
    
    //创建消息表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Message(\
              MsgId                 TEXT PRIMARY KEY,\
              XmppId                TEXT,\
              Platform              INTEGER,\
              'From'                TEXT,\
              'To'                  TEXT,\
              Content               TEXT,\
              ExtendInfo            TEXT,\
              Type                  INTEGER,\
              ChatType              INTEGER,\
              State                 INTEGER,\
              Direction             INTEGER,\
              ContentResolve        TEXT,\
              ReadState             INTEGER DEFAULT 0,\
              LastUpdateTime        INTEGER,\
              MessageRaw            TEXT,\
              RealJid               TEXT,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_MESSAGE_XMPPID_LastUpdateTime ON \
                  IM_Message(XmppId, LastUpdateTime);"
                            withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_MESSAGE_XMPPID_REALJID ON \
                  IM_Message(XmppId, RealJid);" withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_MESSAGE_STATE ON \
                  IM_Message(State);" withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_MESSAGE_TO ON \
                  IM_Message('To');" withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_MESSAGE_TO ON \
                  IM_Message('From');" withParameters:nil];
        
        //创建消息列表插入未读数触发器
//        INSERT INTO logs(context, level, message, timestamp) VALUES (new.ReadState, '创建消息列表插入未读数触发器', new.XmppId||'--'||new.MsgId, datetime('now')) ;\
        
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS sessionlist_unread_insert after insert on IM_Message\
                  for each row begin\
                  update IM_SessionList set UnreadCount = case when ((new.ReadState&2)<>2) then UnreadCount+1 else UnreadCount end where XmppId = new.XmppId and RealJid = new.RealJid and new.Direction=1 ;\
                  update IM_SessionList set LastMessageId = new.MsgId, LastUpdateTime = new.LastUpdateTime where XmppId = new.XmppId and RealJid = new.RealJid and LastUpdateTime <= new.LastUpdateTime;\
                  end" withParameters:nil];
        
        //创建消息列表未读数更新触发器
//        INSERT INTO logs(context, level, message, timestamp) VALUES (new.ReadState, '创建消息列表未读数更新触发器', new.XmppId||'--'||new.MsgId, datetime('now')) ;\

        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS sessionlist_unread_update after update of ReadState on IM_Message\
                  for each row begin\
                  update IM_SessionList set UnreadCount = case when (new.ReadState& 2) =2 and old.ReadState & 2 <>2 then (case when\ UnreadCount >0 then (unreadcount -1) else 0 end ) when (new.ReadState & 2) <>2 and old.ReadState & 2 =2 then\ UnreadCount + 1 else UnreadCount end where XmppId = new.XmppId and RealJid = new.RealJid and new.Direction = 1;\
                  end" withParameters:nil];
        
        result = [database executeNonQuery:@"DROP TRIGGER if EXISTS singlelastupdatetime_insert;" withParameters:nil];
        result = [database executeNonQuery:@"DROP TRIGGER if EXISTS grouplastupdatetime_insert;" withParameters:nil];
        result = [database executeNonQuery:@"DROP TRIGGER if EXISTS systemlastupdatetime_insert;" withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS lastupdatetime_insert after insert on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and new.State&2=2 and (new.ChatType=0 or new.ChatType=4 or new.ChatType=5 or new.ChatType=6)) then new.LastUpdateTime else valueInt end where key='singlelastupdatetime' and type=10 ;\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and new.State&2=2 and new.ChatType=1) then new.LastUpdateTime else valueInt end where key='grouplastupdatetime' and type=10 ;\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and new.State&2=2 and new.ChatType=2) then new.LastUpdateTime else valueInt end where key='systemlastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        /*
        //插入单人消息时更新单人消息最后一条消息时间戳
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS singlelastupdatetime_insert after insert on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and new.State&2=2 and (new.ChatType=0 or new.ChatType=4 or new.ChatType=5 or new.ChatType=6)) then new.LastUpdateTime else valueInt end where key='singlelastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        //更新群消息最后一条消息时间戳
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS grouplastupdatetime_insert after insert on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and new.State&2=2 and new.ChatType=1) then new.LastUpdateTime else valueInt end where key='grouplastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        //更新系统消息最后一条消息时间戳
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS systemlastupdatetime_insert after insert on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and new.State&2=2 and new.ChatType=2) then new.LastUpdateTime else valueInt end where key='systemlastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        */
        
        result = [database executeNonQuery:@"DROP TRIGGER if EXISTS singlelastupdatetime_update;" withParameters:nil];
        result = [database executeNonQuery:@"DROP TRIGGER if EXISTS grouplastupdatetime_update;" withParameters:nil];
        result = [database executeNonQuery:@"DROP TRIGGER if EXISTS systemlastupdatetime_update;" withParameters:nil];
        //更新时间
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS updatetime_update after update of State on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and old.State&2<>2 and new.State&2=2 and (new.ChatType=0 or new.ChatType=4 or new.ChatType=5 or new.ChatType=6)) then new.LastUpdateTime else valueInt end where key='singlelastupdatetime' and type=10 ;\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and old.State&2<>2 and new.State&2=2 and new.ChatType=1) then new.LastUpdateTime else valueInt end where key='grouplastupdatetime' and type=10 ;\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and old.State&2<>2 and new.State&2=2 and new.ChatType=2) then new.LastUpdateTime else valueInt end where key='systemlastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        /*
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS singlelastupdatetime_update after update of State on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and old.State&2<>2 and new.State&2=2 and (new.ChatType=0 or new.ChatType=4 or new.ChatType=5 or new.ChatType=6)) then new.LastUpdateTime else valueInt end where key='singlelastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS grouplastupdatetime_update after update of State on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and old.State&2<>2 and new.State&2=2 and new.ChatType=1) then new.LastUpdateTime else valueInt end where key='grouplastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE TRIGGER IF NOT EXISTS systemlastupdatetime_update after update of State on IM_Message\
                  for each row begin\
                  update IM_Cache_Data set valueInt = case when (valueInt<new.LastUpdateTime and old.State&2<>2 and new.State&2=2 and new.ChatType=2) then new.LastUpdateTime else valueInt end where key='systemlastupdatetime' and type=10 ;\
                  end" withParameters:nil];
        */
    }
    
    //创建公众号表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Public_Number(\
              XmppId                TEXT PRIMARY KEY,\
              PublicNumberId        TEXT,\
              PublicNumberType      INTEGER,\
              Name                  TEXT,\
              DescInfo              TEXT,\
              HeaderSrc             TEXT,\
              SearchIndex           TEXT,\
              PublicNumberInfo      BLOB,\
              LastUpdateTime        INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_PUBLIC_NUMBER_PNID ON \
                  IM_Public_Number(PublicNumberId);"
                            withParameters:nil];
    }
    
    //创建公众号消息表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Public_Number_Message(\
              MsgId                 TEXT PRIMARY KEY,\
              XmppId                TEXT,\
              'From'                TEXT,\
              'To'                  TEXT,\
              Content               TEXT,\
              Type                  INTEGER,\
              State                 INTEGER,\
              Direction             INTEGER,\
              ReadedTag             INTEGER DEFAULT 0,\
              LastUpdateTime        INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_PUBLIC_NUMBER_MESSAGE_XMPPID ON \
                  IM_Public_Number_Message(XmppId);"
                            withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_PUBLIC_NUMBER_MESSAGE_FROM ON \
                  IM_Public_Number_Message('From');"
                            withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_PUBLIC_NUMBER_MESSAGE_TO ON \
                  IM_Public_Number_Message('To');"
                            withParameters:nil];
    }
    
    //创建IM_Collection_User 已绑定的账号
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Collection_User(\
              XmppId                TEXT PRIMARY KEY,\
              BIND                  BLOB\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_USER_XMPPID ON \
                  IM_Collection_User(XmppId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_USER_BIND ON \
                  IM_Collection_User(BIND);"
                            withParameters:nil];
    }
    
    //创建IM_Collection_User_Card 代收用户名片
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Collection_User_Card(\
              UserId                TEXT,\
              XmppId                TEXT PRIMARY KEY,\
              Name                  TEXT,\
              DescInfo              TEXT,\
              HeaderSrc             TEXT,\
              SearchIndex           TEXT,\
              UserInfo              BLOB,\
              LastUpdateTime        INTEGER,\
              IncrementVersion      INTEGER,\
              ExtendedFlag          BLOB\
              );"
                        withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_USER_CARD_USERID ON \
                  IM_Collection_User_Card(UserId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_USER_CARD_NAME ON \
                  IM_Collection_User_Card(Name);"
                            withParameters:nil];
    }
    
    //创建IM_Collection_Group_Card 代收群名片
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Collection_Group_Card(\
              GroupId               TEXT PRIMARY KEY,\
              Name                  TEXT,\
              Introduce             TEXT,\
              HeaderSrc             TEXT,\
              Topic                 TEXT,\
              LastUpdateTime        INTEGER,\
              ExtendedFlag          BLOB\
              );"
                        withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_GROUP_CARD_NAME ON \
                  IM_Collection_Group_Card(Name);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_GROUP_CARD_LASTUPDATETIME ON \
                  IM_Collection_Group_Card(LastUpdateTime);"
                            withParameters:nil];
    }
    
    //创建代收消息列表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Collection_SessionList(\
              XmppId                TEXT,\
              BindId                TEXT,\
              RealJid               TEXT,\
              UserId                TEXT,\
              LastMessageId         TEXT,\
              LastUpdateTime        INTEGER,\
              ChatType              INTEGER,\
              ExtendedFlag          BLOB,\
              primary key (XmppId,BindId,RealJid));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_COLLECTION_SESSIONLIST_LASTMESSAGEID ON \
                  IM_Collection_SessionList(LastMessageId);"
                            withParameters:nil];
    }
    
    //创建IM_Message_Collection 代收消息附属表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Message_Collection(\
              MsgId                 TEXT PRIMARY KEY,\
              Originfrom            TEXT,\
              Originto              TEXT,\
              Origintype            TEXT\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_MESSAGE_COLLECTION_ORIGINFROM ON \
                  IM_Message_Collection(ORIGINFROM);"
                            withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_MESSAGE_COLLECTION_ORIGINTO ON \
                  IM_Message_Collection(Originto);"
                            withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_MESSAGE_COLLECTION_ORIGINTYPE ON \
                  IM_Message_Collection(Origintype);"
                            withParameters:nil];
    }
    
    //创建回复表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Friendster_Message(\
              MsgId                 TEXT PRIMARY KEY,\
              XmppId                TEXT,\
              FromUser              TEXT,\
              ReplyMsgId            TEXT,\
              ReplyUser             TEXT,\
              Content               Text,\
              LastUpdateTime        INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIENDSTER_MESSAGE_XMPPID ON \
                  IM_Friendster_Message(XmppId);"
                            withParameters:nil];
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIENDSTER_MESSAGE_REPLYMSGID ON \
                  IM_Friendster_Message(ReplyMsgId);"
                            withParameters:nil];
    }
    
    //创建好友列表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Friend_List(\
              UserId                TEXT,\
              XmppId                TEXT PRIMARY KEY,\
              Name                  TEXT,\
              DescInfo              TEXT,\
              HeaderSrc             TEXT,\
              SearchIndex           TEXT,\
              UserInfo              BLOB,\
              LastUpdateTime        INTEGER,\
              IncrementVersion      INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIEND_LIST_USERID ON \
                  IM_Friend_List(UserId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIEND_LIST_XMPPID ON \
                  IM_Friend_List(XmppId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIEND_LIST_NAME ON \
                  IM_Friend_List(Name);"
                            withParameters:nil];
    }
    
    //创建好友通知表
    result = [database executeNonQuery: @"CREATE TABLE IF NOT EXISTS IM_Friend_Notify(\
              UserId                TEXT ,\
              XmppId                TEXT PRIMARY KEY,\
              Name                  TEXT,\
              DescInfo              TEXT,\
              HeaderSrc             TEXT,\
              SearchIndex           TEXT,\
              UserInfo              BLOB,\
              State                 INTEGER,\
              Version               INTEGER,\
              LastUpdateTime        INTEGER,\
              ExtendedFlag          BLOB\
              );" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIEND_NOTIFY_USERID ON \
                  IM_Friend_Notify(UserId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIEND_NOTIFY_XMPPID ON \
                  IM_Friend_Notify(XmppId);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_FRIEND_NOTIFY_NAME ON \
                  IM_Friend_Notify(Name);"
                            withParameters:nil];
    }
    
    //q_id 服务器返值 qc_id 本地生成
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS qcloud_main(\
              q_id                  INTEGER, \
              c_id                  INTEGER PRIMARY KEY, \
              q_type                INTEGER, \
              q_title               TEXT,\
              q_introduce           TEXT,\
              q_content             TEXT,\
              q_time                INTEGER,\
              q_state               INTEGER,\
              q_ExtendedFlag        INTRGER\
              );" withParameters:nil];
    if (result) {
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_MAIN_Q_ID ON \
                  qcloud_main(q_id);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_MAIN_Q_TYPE ON \
                  qcloud_main(q_type);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_MAIN_Q_TIME_TYPE ON \
                  qcloud_main(q_time,q_type);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_MAIN_Q_STATE ON \
                  qcloud_main(q_state);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_MAIN_Q_Flag ON \
                  qcloud_main(q_ExtendedFlag);" withParameters:nil];
    }
    //q_id qs_id 服务器返值 qc_id qcs_id 本地生成
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS qcloud_sub(\
              c_id                  INTEGER,\
              qs_id                 INTEGER, \
              cs_id                 INTEGER PRIMARY KEY, \
              qs_type               INTEGER, \
              qs_title              TEXT,\
              qs_introduce          TEXT,\
              qs_content            TEXT,\
              qs_time               INTEGER,\
              qs_state              INTEGER,\
              qs_ExtendedFlag       INTEGER\
              );" withParameters:nil];
    if (result) {
        
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_SUB_C_ID ON \
                  qcloud_sub(c_id);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_SUB_QS_ID ON \
                  qcloud_sub(qs_id);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_SUB_Q_TYPE ON \
                  qcloud_sub(qs_type);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_SUB_Q_TIME ON \
                  qcloud_sub(qs_time);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_SUB_QS_STATE ON \
                  qcloud_sub(qs_state);"
                            withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS QCLOUD_SUB_QS_ExtendedFlag ON \
                  qcloud_sub(qs_ExtendedFlag);"
                            withParameters:nil];
    }
    
    //创建用户直属Leader表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_UsersWorkInfo(\
              XmppId                 TEXT PRIMARY KEY, \
              UserWorkInfo           TEXT,\
              LastUpdateTime         INTEGER\
              );" withParameters:nil];
    
    //创建客户端配置表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_Client_Config(\
               ConfigKey             TEXT,\
               ConfigSubKey          TEXT,\
               ConfigValue           TEXT,\
               ConfigVersion         INTEGER,\
               DeleteFlag            INTEGER,\
              primary key (ConfigKey,ConfigSubKey));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_CLIENT_CONFIG_CONFIGKEY ON \
                  IM_Client_Config(ConfigKey);" withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_CLIENT_CONFIG_CONFIGVERSION ON \
                  IM_Client_Config(ConfigVersion);" withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_CLIENT_CONFIG_DELETEFLAG ON \
                  IM_Client_Config(DeleteFlag);" withParameters:nil];
    }
    
    //快捷回复组表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_QUICK_REPLY_GROUP(\
              sid              LONG,\
              groupname        TEXT,\
              groupseq         LONG,\
              version          LONG DEFAULT 1,\
              primary key      (sid));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_QUICK_REPLY_GROUP_SID ON \
                  IM_QUICK_REPLY_GROUP(sid);" withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_QUICK_REPLY_GROUP_GROUPSEQ ON \
                  IM_QUICK_REPLY_GROUP(groupseq);" withParameters:nil];
    }
    
    //快捷回复单条记录表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_QUICK_REPLY_CONTENT(\
              sid             LONG,\
              gid             LONG,\
              content         TEXT,\
              contentseq      LONG,\
              version         LONG DEFAULT 1,\
              primary key     (gid, sid));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_QUICK_REPLY_CONTENT_GID ON \
                  IM_QUICK_REPLY_CONTENT(gid);" withParameters:nil];
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IX_IM_QUICK_REPLY_CONTENT_CONTENTSEQ ON \
                  IM_QUICK_REPLY_CONTENT(contentseq);" withParameters:nil];
    }
    
    //创建行程区域表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_TRIP_AREA (\
              AreaID TEXT PRIMARY KEY,\
              Enable TEXT,\
              AreaName TEXT,\
              MorningStarts TEXT,\
              EveningEnds TEXT,\
              Description TEXT);" withParameters:nil];
    
    //创建行程详情表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_TRIP_INFO (\
              tripId TEXT PRIMARY KEY,\
              tripName TEXT,\
              tripDate TEXT,\
              tripType TEXT,\
              tripIntr TEXT,\
              tripInviter TEXT,\
              beginTime TEXT,\
              endTime TEXT,scheduleTime TEXT,\
              appointment TEXT,\
              tripLocale TEXT,\
              tripLocaleNumber TEXT,\
              tripRoom TEXT,\
              tripRoomNumber TEXT,\
              memberList TEXT,\
              tripRemark TEXT,\
              canceled Text);" withParameters:nil];
    
    //创建log表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS logs (\
              context integer,\
              level integer,\
              message text,\
              timestamp double);" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS timestamp ON logs (timestamp);" withParameters:nil];
    }
    
    //创建用户勋章表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_Users_Medal (\
              XmppId                TEXT,\
              Type                  TEXT,\
              URL                   TEXT,\
              URLDesc               TEXT,\
              LastUpdateTime        INTEGER DEFAULT 0,\
              primary key (XmppId,Type));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_Users_MEDAL_XMPPID ON IM_Users_Medal (XmppId);" withParameters:nil];
    }
    
    //创建工作圈表
    result = [database executeNonQuery:@"CREATE TABLE IF NOT EXISTS IM_Work_World (\
              id                    INTEGER,\
              uuid                  TEXT PRIMARY KEY,\
              owner                 TEXT,\
              ownerHost             TEXT,\
              isAnonymous           INTEGER DEFAULT 0,\
              anonymousName         TEXT,\
              anonymousPhoto        TEXT,\
              createTime            INTEGER,\
              updateTime            INTEGER,\
              content               INTEGER,\
              atList                TEXT,\
              isDelete              INTEGER DEFAULT 0,\
              isLike                INTEGER DEFAULT 0,\
              likeNum               INTEGER,\
              commentsNum           INTEGER,\
              review_status         INTEGER,\
              attachCommentList     TEXT);" withParameters:nil];
    if (result) {
        if ([database checkExistsOnTable:@"IM_Work_World" withColumn:@"postType"] == NO) {
            [database executeNonQuery:@"ALTER TABLE IM_Work_World ADD postType INTEGER DEFAULT 1;" withParameters:nil];
        }
    }
    //创建工作圈评论表
    result = [database executeNonQuery:@"create table IF NOT EXISTS IM_Work_CommentV2 (\
              anonymousName         TEXT,\
              anonymousPhoto        TEXT,\
              commentUUID           TEXT PRIMARY KEY,\
              content               TEXT,\
              createTime            INTEGER,\
              fromHost              TEXT,\
              fromUser              TEXT,\
              id                    INTEGER,\
              isAnonymous           INTEGER,\
              isDelete              INTEGER,\
              isLike                INTEGER,\
              likeNum               INTEGER,\
              parentCommentUUID     TEXT,\
              superParentUUID       TEXT,\
              postUUID              TEXT,\
              reviewStatus          INTEGER,\
              toAnonymousName       TEXT,\
              toAnonymousPhoto      TEXT,\
              toHost                TEXT,\
              toUser                TEXT,\
              toisAnonymous         INTEGER,\
              updateTime            INTEGER);" withParameters:nil];
    /*
     
     CREATE TABLE IM_Work_World_Comment (anonymousName TEXT,anonymousPhoto TEXT,commentUUID TEXT PRIMARY KEY,content TEXT,createTime INTEGER DEFAULT 0,fromHost TEXT,fromUser TEXT,id INTEGER,isAnonymous INTEGER,isDelete INTEGER,isLike INTEGER,likeNum INTEGER,parentCommentUUID TEXT,postUUID TEXT,reviewStatus INTEGER,toHost TEXT,toUser TEXT,updateTime INTEGER DEFAULT 0,toisAnonymous INTEGER,toAnonymousName TEXT,toAnonymousPhoto TEXT,superParentUUID TEXT,newChildString TEXT,commentStatus INTEGER DEFAULT 0,atList TEXT)
     */
    
    if (result) {
        if ([database checkExistsOnTable:@"IM_Work_CommentV2" withColumn:@"superParentUUID"] == NO) {
            [database executeNonQuery:@"ALTER TABLE IM_Work_CommentV2 ADD superParentUUID TEXT;" withParameters:nil];
        }
        if ([database checkExistsOnTable:@"IM_Work_CommentV2" withColumn:@"commentStatus"] == NO) {
            [database executeNonQuery:@"ALTER TABLE IM_Work_CommentV2 ADD commentStatus TEXT;" withParameters:nil];
        }
        if ([database checkExistsOnTable:@"IM_Work_CommentV2" withColumn:@"atList"] == NO) {
            [database executeNonQuery:@"ALTER TABLE IM_Work_CommentV2 ADD atList TEXT;" withParameters:nil];
        }
    }
    
    //创建工作圈通知消息表
    result = [database executeNonQuery:@"create table IF NOT EXISTS IM_Work_NoticeMessage (\
              userFrom              TEXT,\
              readState             INTEGER,\
              postUUID              TEXT,\
              fromIsAnonymous       INTEGER,\
              toIsAnonymous         INTEGER,\
              toAnonymousName       TEXT,\
              toAnonymousPhoto      TEXT,\
              eventType             INTEGER,\
              fromAnonymousPhoto    TEXT,\
              userTo                TEXT,\
              uuid                  TEXT PRIMARY KEY,\
              content               TEXT,\
              userToHost            TEXT,\
              createTime            INTEGER,\
              userFromHost          TEXT,\
              fromAnonymousName     TEXT);" withParameters:nil];
    
    //创建一个缓存表
    result = [database executeNonQuery:@"create table IF NOT EXISTS IM_Cache_Data(\
              key           TEXT,\
              type          INTEGER,\
              value         TEXT,\
              valueInt      INTEGER DEFAULT 0,\
              primary key(key , type));" withParameters:nil];
    
    //创建一个At消息表
    result = [database executeNonQuery:@"create table IF NOT EXISTS IM_At_Message(\
              GroupId           TEXT,\
              MsgId             TEXT,\
              Type              INTEGER DEFAULT 0,\
              MsgTime           INTEGER,\
              ReadState         INTEGER DEFAULT 0,\
              primary key (GroupId,MsgId));" withParameters:nil];
    if (result) {
        result = [database executeNonQuery:@"CREATE INDEX IF NOT EXISTS IM_AT_MESSAGE_GROUPID ON IM_At_Message (GroupId);" withParameters:nil];
    }
    
    result = [database executeNonQuery:@"create table IF NOT EXISTS IM_Found_List(\
              version                  TEXT PRIMARY KEY,\
              foundList     TEXT);" withParameters:nil];
    
    return result;
}

- (void)qimDB_closeDataBase{
    QIMDataBaseQueueManager *manager = [QIMDataBaseQueueManager databasePoolWithPath:_dbPath];
    [manager releaseAllDatabases];
    __global_data_manager = nil;
    _onceDBToken = 0;
    /*
    BOOL result = [DatabaseManager CloseByFullPath:_dbPath];
    if (result) {
        __global_data_manager = nil;
        _onceDBToken = 0;
    }
     */
}

+ (void)qimDB_clearDataBaseCache{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"dbVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)qimDB_dbCheckpoint {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        [database dbCheckpoint];
    }];
}

- (NSInteger)qimDB_parserplatForm:(NSString *)platFormStr {
    NSInteger platForm = 2;
    if ([platFormStr isEqualToString:@"ClientTypeMac"]) {
        platForm = 1;
    } else if ([platFormStr isEqualToString:@"ClientTypeiOS"]) {
        platForm = 2;
    } else if ([platFormStr isEqualToString:@"ClientTypePc"]) {
        platForm = 3;
    } else if ([platFormStr isEqualToString:@"ClientTypeAndroid"]) {
        platForm = 4;
    } else if ([platFormStr isEqualToString:@"ClientTypeLinux"]) {
        platForm = 5;
    } else if ([platFormStr isEqualToString:@"ClientTypeWeb"]) {
        platForm = 6;
    } else {
        platForm = 2;
    }
    return platForm;
}

@end
