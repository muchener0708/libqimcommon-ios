
//
//  IMDataManager+QIMFoundList.m
//  QIMCommon
//
//  Created by lilu on 2019/4/17.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "IMDataManager+QIMFoundList.h"
#import "Database.h"
//#import "WCDB.h"

@implementation IMDataManager (QIMFoundList)

- (void)qimDB_insertFoundListWithAppVersion:(NSString *)version withFoundList:(NSString *)foundListStr {
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"insert or replace into IM_Found_List(version, foundList) Values(:version, :foundList)";
        NSMutableArray *parames = [[NSMutableArray alloc] init];
        [parames addObject:version];
        [parames addObject:foundListStr?foundListStr:@":NULL"];
        [database executeNonQuery:sql withParameters:parames];
        parames = nil;
    }];
}

- (NSString *)qimDB_getFoundListWithAppVersion:(NSString *)version {
    __block NSString *result = nil;
    [[self dbInstance] syncUsingTransaction:^(Database *database) {
        NSString *sql = @"SELECT foundList FROM IM_Found_List WHERE version = :version";
        DataReader *reader = [database executeReader:sql withParameters:@[version]];
        if ([reader read]) {
            result = [reader objectForColumnIndex:0];
        }
    }];
    return result;
}

@end
