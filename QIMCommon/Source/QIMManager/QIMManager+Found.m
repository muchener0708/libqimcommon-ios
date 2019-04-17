//
//  QIMManager+Found.m
//  QIMCommon
//
//  Created by lilu on 2019/4/16.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "QIMManager+Found.h"

@implementation QIMManager (Found)

- (void)getRemoteFoundNavigation {
    NSString *destUrl = [NSString stringWithFormat:@"%@/"];
    [[QIMManager sharedInstance] sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:nil withSuccessCallBack:^(NSData *responseData) {
        
    } withFailedCallBack:^(NSError *error) {
        
    }];
}

@end
