//
//  QIMManager+Search.m
//  QIMCommon
//
//  Created by lilu on 2019/6/19.
//

#import "QIMManager+Search.h"
#import "QIMPrivateHeader.h"

@implementation QIMManager (Search)

- (void)searchWithUrl:(NSString *)url withParams:(NSDictionary *)params withSuccessCallBack:(QIMKitSearchSuccessBlock)successCallback withFaildCallBack:(QIMKitSearchFaildBlock)faildCallback {
    
    NSData *bodyData = [[QIMJSONSerializer sharedInstance] serializeObject:params error:nil];
    [self sendTPPOSTRequestWithUrl:url withRequestBodyData:bodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *responseDic = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[responseDic objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[responseDic objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSArray *data = [responseDic objectForKey:@"data"];
            NSString *responseJson = [[QIMJSONSerializer sharedInstance] serializeObject:responseDic];
            if (successCallback) {
                successCallback(YES, responseJson);
            }
        } else {
            if (faildCallback) {
                faildCallback(NO, nil);
            }
        }
    } withFailedCallBack:^(NSError *error) {
        if (faildCallback) {
            faildCallback(YES, nil);
        }
    }];
}

@end
