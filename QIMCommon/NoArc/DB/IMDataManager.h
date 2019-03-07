//
//  IMDataManager.h
//  qunarChatIphone
//
//  Created by ping.xue on 14-3-19.
//  Copyright (c) 2014年 ping.xue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QIMCommonEnum.h"
#import "QIMPublicRedefineHeader.h"

@class UserInfo;

@interface IMDataManager : NSObject

//@property (nonatomic, strong) NSString *dbOwnerId;  //数据库所有者Id
//
//@property (nonatomic, copy) NSString *dbOwnerDomain;  //数据库z所有者Domain
//
//@property (nonatomic, copy) NSString *dbOwnerFullJid;   //数据库所有者XmppId

@property (nonatomic, strong) NSDateFormatter *timeSmtapFormatter;


+ (IMDataManager *) qimDB_SharedInstance;
+ (IMDataManager *) qimDB_sharedInstanceWithDBPath:(NSString *)dbPath withDBFullJid:(NSString *)dbOwnerFullJid;

- (NSString *)getDbOwnerFullJid;

+ (void)safeSaveForDic:(NSMutableDictionary *)dic setObject:(id)value forKey:(id)key;

- (NSString *) OriginalUUID;

- (NSString *)UUID;

- (id)initWithDBPath:(NSString *)dbPath;

- (id)dbInstance;

- (void)qimDB_closeDataBase;

+ (void)qimDB_clearDataBaseCache;
- (void)qimDB_dbCheckpoint;

- (NSInteger)qimDB_parserplatForm:(NSString *)platFormStr;

@end
