//
//  QIMManager+DB.m
//  qunarChatIphone
//
//  Created by 李露 on 2018/4/3.
//

#import "QIMManager+DB.h"
#import "QIMPrivateHeader.h"

@implementation QIMManager (DB)

- (void)initDBWithUserXmppId:(NSString *)userJid {

    NSString *dbPath = [UserCachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"QIMDB/%@%@/", [userJid lowercaseString], UserPath]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //UrlWithString 会报CFURLSetResourcePropertyForKey failed because it was passed an URL which has no scheme 错误，使用fileURLWithPath正常
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:[dbPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    dbPath = [dbPath stringByAppendingPathComponent:@"data.dat"];
    [IMDataManager qimDB_sharedInstanceWithDBPath:dbPath];
    [[IMDataManager qimDB_SharedInstance] setDbOwnerId:[QIMManager getLastUserName]];
    [[IMDataManager qimDB_SharedInstance] setDbOwnerDomain:[self getDomain]];
}

- (void)initDB {
    NSString *dbPath = [UserCachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"QIMDB/%@%@/", [[self getLastJid] lowercaseString], UserPath]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dbPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //UrlWithString 会报CFURLSetResourcePropertyForKey failed because it was passed an URL which has no scheme 错误，使用fileURLWithPath正常
    [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:[dbPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    dbPath = [dbPath stringByAppendingPathComponent:@"data.dat"];
    [IMDataManager qimDB_sharedInstanceWithDBPath:dbPath];
    [[IMDataManager qimDB_SharedInstance] setDbOwnerId:[QIMManager getLastUserName]];
    [[IMDataManager qimDB_SharedInstance] setDbOwnerDomain:[self getDomain]];
}

- (void)removeDataBase {
    //关闭数据库
    [[IMDataManager qimDB_SharedInstance] qimDB_closeDataBase];
    NSString *workingPath = nil;
    {
        NSString *dbPath = [UserCachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"QIMDB/%@%@/", [[self getLastJid] lowercaseString], UserPath]];
        //UrlWithString 会报CFURLSetResourcePropertyForKey failed because it was passed an URL which has no scheme 错误，使用fileURLWithPath正常
        [self addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:[dbPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        dbPath = [dbPath stringByAppendingPathComponent:@"data.dat"];
        workingPath = dbPath;
    }
    {
        //清理用户缓存信息
        [[QIMUserCacheManager sharedInstance] clearUserCache];
    }
    {
        NSError *error = nil;
        if (workingPath && [[NSFileManager defaultManager] fileExistsAtPath:workingPath]) {
            BOOL removeSuccess = [[NSFileManager defaultManager] removeItemAtPath:workingPath error:&error];
            if (removeSuccess) {
                QIMWarnLog(@"清楚用户数据库缓存成功");
            } else {
                QIMErrorLog(@"清楚用户数据库缓存失败");
            }
        } else {
            QIMErrorLog(@"workingPath不存在或为空 : %@", workingPath);
        }
    }
}

- (void)closeDataBase {
    QIMErrorLog(@"关闭数据库");
    [[IMDataManager qimDB_SharedInstance] qimDB_closeDataBase];
}

- (void)clearDataBase {
    //清理数据库
    QIMErrorLog(@"清除数据库");
    [self removeDataBase];
    {
        //清理用户缓存信息
        QIMErrorLog(@"清理用户缓存信息");
        [[QIMUserCacheManager sharedInstance] clearUserCache];
        [[QIMNavConfigManager sharedInstance] qimNav_updateNavigationConfigWithCheck:YES];
    }
}

@end
