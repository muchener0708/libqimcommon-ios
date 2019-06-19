//
//  QIMKit+QIMSearch.m
//  QIMCommon
//
//  Created by lilu on 2019/6/19.
//

#import "QIMKit+QIMSearch.h"
#import "QIMPrivateHeader.h"

@implementation QIMKit (QIMSearch)

- (void)searchWithUrl:(NSString *)url withParams:(NSDictionary *)params withSuccessCallBack:(QIMKitSearchSuccessBlock)successCallback withFaildCallBack:(QIMKitSearchFaildBlock)faildCallback {
    [[QIMManager sharedInstance] searchWithUrl:url withParams:params withSuccessCallBack:successCallback withFaildCallBack:faildCallback];
}

@end
