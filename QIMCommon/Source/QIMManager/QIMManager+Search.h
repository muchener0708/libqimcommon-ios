//
//  QIMManager+Search.h
//  QIMCommon
//
//  Created by lilu on 2019/6/19.
//

#import "QIMManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface QIMManager (Search)

- (void)searchWithUrl:(NSString *)url withParams:(NSDictionary *)params withSuccessCallBack:(QIMKitSearchSuccessBlock)successCallback withFaildCallBack:(QIMKitSearchFaildBlock)faildCallback;

@end

NS_ASSUME_NONNULL_END
