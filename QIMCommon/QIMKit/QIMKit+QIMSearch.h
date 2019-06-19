//
//  QIMKit+QIMSearch.h
//  QIMCommon
//
//  Created by lilu on 2019/6/19.
//

#import "QIMKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface QIMKit (QIMSearch)

- (void)searchWithUrl:(NSString *)url withParams:(NSDictionary *)params withSuccessCallBack:(QIMKitSearchSuccessBlock)successCallback withFaildCallBack:(QIMKitSearchFaildBlock)faildCallback;

@end

NS_ASSUME_NONNULL_END
