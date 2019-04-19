//
//  IMDataManager+QIMFoundList.h
//  QIMCommon
//
//  Created by lilu on 2019/4/17.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "IMDataManager.h"
#import "QIMPublicRedefineHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMDataManager (QIMFoundList)

- (void)qimDB_insertFoundListWithAppVersion:(NSString *)version withFoundList:(NSString *)foundListStr;

- (NSString *)qimDB_getFoundListWithAppVersion:(NSString *)version;

@end

NS_ASSUME_NONNULL_END
