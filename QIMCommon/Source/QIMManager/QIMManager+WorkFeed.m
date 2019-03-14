//
//  QIMManager+WorkFeed.m
//  QIMCommon
//
//  Created by lilu on 2019/1/7.
//  Copyright © 2019 QIM. All rights reserved.
//

#import "QIMManager+WorkFeed.h"
#import <objc/runtime.h>

@implementation QIMManager (WorkFeed)

- (NSArray *)getHotCommentUUIdsForMomentId:(NSString *)momentId {
    return [self.hotCommentUUIdsDic objectForKey:momentId];
}

- (void)setHotCommentUUIds:(NSArray *)hotCommentUUIds ForMomentId:(NSString *)momentId {
    [self.hotCommentUUIdsDic setQIMSafeObject:hotCommentUUIds forKey:momentId];
}

- (void)removeHotCommentUUIdsForMomentId:(NSString *)momentId {
    if (momentId.length > 0) {
        [self.hotCommentUUIdsDic removeObjectForKey:momentId];
    }
}

- (void)removeAllHotCommentUUIds {
    [self.hotCommentUUIdsDic removeAllObjects];
}

- (void)updateLastWorkFeedMsgTime {
    QIMVerboseLog(@"更新本地未读的驼圈消息时间戳");
    long long defaultTime = ([[NSDate date] timeIntervalSince1970] - self.serverTimeDiff - 3600 * 24 * 2) * 1000;
    long long errorTime = [[[QIMUserCacheManager sharedInstance] userObjectForKey:kGetWorkFeedHistoryMessageListError] longLongValue];
    if (errorTime > 0) {
        self.lastWorkFeedMsgMsgTime = errorTime;
        QIMVerboseLog(@"本地驼圈错误时间戳 : %lld", errorTime);
    } else {
        self.lastWorkFeedMsgMsgTime = [[IMDataManager qimDB_SharedInstance] qimDB_getWorkNoticeMessagesMaxTime];
    }
    if (self.lastWorkFeedMsgMsgTime == 0) {
        self.lastWorkFeedMsgMsgTime = defaultTime;
    }
    QIMVerboseLog(@"强制塞本地驼圈消息时间戳到为 kGetSingleHistoryMsgError : %f", self.lastWorkFeedMsgMsgTime);
    [[QIMUserCacheManager sharedInstance] setUserObject:@(self.lastWorkFeedMsgMsgTime) forKey:kGetWorkFeedHistoryMessageListError];
    QIMVerboseLog(@"强制塞本地驼圈消息时间戳到为 kGetSingleHistoryMsgError : %f完成", self.lastWorkFeedMsgMsgTime);
    
    QIMVerboseLog(@"强制塞本地驼圈消息消息时间戳完成之后再取一下本地错误时间戳 : %lld", [[[QIMUserCacheManager sharedInstance] userObjectForKey:kGetWorkFeedHistoryMessageListError] longLongValue]);
    
    QIMVerboseLog(@"最终获取到的本地驼圈已读未读最后消息时间戳为 : %lf", self.lastWorkFeedMsgMsgTime);
}

- (void)getRemoteMomentDetailWithMomentUUId:(NSString *)momentId withCallback:(QIMKitgetMomentDetailSuccessedBlock)callback {
    if (momentId.length <= 0) {
        return;
    }
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/getPostDetail", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSDictionary *anonyDic = @{@"uuid" : momentId};
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:anonyDic error:nil];
    
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            
            NSDictionary *momentDic = [result objectForKey:@"data"];
            if ([momentDic isKindOfClass:[NSDictionary class]]) {
                [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertMoments:@[momentDic]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(momentDic);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedDetail object:momentDic];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)getAnonyMouseDicWithMomentId:(NSString *)momentId WithCallBack:(QIMKitgetAnonymouseSuccessedBlock)callback {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/anonymouse/getAnonymouse", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSDictionary *anonyDic = @{@"user" : [[QIMManager sharedInstance] getLastJid], @"postId": momentId ? momentId : [QIMUUIDTools UUID]};
    QIMVerboseLog(@"获取匿名Body : %@", [[QIMJSONSerializer sharedInstance] serializeObject:anonyDic]);
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:anonyDic error:nil];
    
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *anonymousDic = [result objectForKey:@"data"];
            if ([anonymousDic isKindOfClass:[NSDictionary class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(anonymousDic);
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)pushNewMomentWithMomentDic:(NSDictionary *)momentDic {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/post", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:momentDic error:nil];
    NSString *momentBodyStr = [[QIMJSONSerializer sharedInstance] serializeObject:momentDic];
    QIMVerboseLog(@"pushNewMomentWithMomentDic Body : %@", momentBodyStr);
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *moments = [result objectForKey:@"data"];
            if ([moments isKindOfClass:[NSDictionary class]]) {
                NSArray *deletePosts = [moments objectForKey:@"deletePost"];
                NSArray *newPosts = [moments objectForKey:@"newPost"];
                if ([deletePosts isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkdeleteMoments:deletePosts];
                }
                if ([newPosts isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertMoments:newPosts];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeed object:newPosts];
                    });
                }
            }
        }
    } withFailedCallBack:^(NSError *error) {
        
    }];
}

- (void)getMomentHistoryWithLastUpdateTime:(long long)updateTime withOwnerXmppId:(NSString *)xmppId withCallBack:(QIMKitGetMomentHistorySuccessedBlock)callback {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/post/getPostList/v2", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [NSMutableDictionary dictionaryWithCapacity:1];
    [bodyDic setQIMSafeObject:@(updateTime) forKey:@"postCreateTime"];
    [bodyDic setQIMSafeObject:[[xmppId componentsSeparatedByString:@"@"] firstObject] forKey:@"owner"];
    [bodyDic setQIMSafeObject:[[xmppId componentsSeparatedByString:@"@"] lastObject] forKey:@"ownerHost"];
    [bodyDic setQIMSafeObject:@(20) forKey:@"pageSize"];
    [bodyDic setQIMSafeObject:@(1) forKey:@"getTop"];
    [bodyDic setQIMSafeObject:@(7) forKey:@"postType"];

    QIMVerboseLog(@"post/getPostList : %@", bodyDic);
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *moments = [result objectForKey:@"data"];
            if ([moments isKindOfClass:[NSDictionary class]]) {
                NSArray *deletePosts = [moments objectForKey:@"deletePost"];
                NSArray *newPosts = [moments objectForKey:@"newPost"];
                if ([deletePosts isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkdeleteMoments:deletePosts];
                }
                if ([newPosts isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertMoments:newPosts];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(newPosts);
                        }
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(nil);
                        }
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)deleteRemoteMomentWithMomentId:(NSString *)momentId {
    if (momentId.length <= 0) {
        return;
    }
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/deletePost", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSDictionary *bodyDic = @{@"uuid":momentId};
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                BOOL isDeleteFlag = [[data objectForKey:@"isDelete"] boolValue];
                if (isDeleteFlag == YES) {
                    NSInteger rId = [[data objectForKey:@"id"] integerValue];
                    [[IMDataManager qimDB_SharedInstance] qimDB_deleteMomentWithRId:rId];
                }
            }
        }
    } withFailedCallBack:^(NSError *error) {
        
    }];
}

- (void)likeRemoteMomentWithMomentId:(NSString *)momentId withLikeFlag:(BOOL)likeFlag withCallBack:(QIMKitLikeMomentSuccessedBlock)callback {
    if (momentId.length <= 0) {
        return;
    }
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/like", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    [bodyDic setQIMSafeObject:nil forKey:@"commentId"];
    [bodyDic setQIMSafeObject:@(likeFlag) forKey:@"likeType"];
    [bodyDic setQIMSafeObject:@(QIMWorkFeedTypeMoment) forKey:@"opType"];
    [bodyDic setQIMSafeObject:momentId forKey:@"postId"];
    [bodyDic setQIMSafeObject:[QIMManager getLastUserName] forKey:@"userId"];
    [bodyDic setQIMSafeObject:[[QIMManager sharedInstance] getDomain] forKey:@"userHost"];
    [bodyDic setQIMSafeObject:[NSString stringWithFormat:@"2-%@", [QIMUUIDTools UUID]] forKey:@"likeId"];
    
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([data isKindOfClass:[NSDictionary class]]) {
                [[IMDataManager qimDB_SharedInstance] qimDB_updateMomentLike:@[data]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(data);
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedLike object:data];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}


#pragma mark - Remote Comment

- (void)likeRemoteCommentWithCommentId:(NSString *)commentId withSuperParentUUID:(NSString *)superParentUUID withMomentId:(NSString *)momentId withLikeFlag:(BOOL)likeFlag withCallBack:(QIMKitLikeContentSuccessedBlock)callback {
    if (momentId.length <= 0 || commentId.length <= 0) {
        return;
    }
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/like", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    [bodyDic setQIMSafeObject:commentId forKey:@"commentId"];
    [bodyDic setQIMSafeObject:@(likeFlag) forKey:@"likeType"];
    [bodyDic setQIMSafeObject:@(QIMWorkFeedTypeComment) forKey:@"opType"];
    [bodyDic setQIMSafeObject:momentId forKey:@"postId"];
    [bodyDic setQIMSafeObject:[QIMManager getLastUserName] forKey:@"userId"];
    [bodyDic setQIMSafeObject:[[QIMManager sharedInstance] getDomain] forKey:@"userHost"];
    [bodyDic setQIMSafeObject:[NSString stringWithFormat:@"2-%@",[QIMUUIDTools UUID]] forKey:@"likeId"];
    [bodyDic setQIMSafeObject:(superParentUUID.length > 0) ? superParentUUID : nil forKey:@"superParentUUID"];
    
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([data isKindOfClass:[NSDictionary class]]) {
                [[IMDataManager qimDB_SharedInstance] qimDB_updateMomentLike:@[data]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(data);
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)uploadCommentWithCommentDic:(NSDictionary *)commentDic {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/uploadComment/V2", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];

    NSString *commentStr = [[QIMJSONSerializer sharedInstance] serializeObject:commentDic];
    QIMVerboseLog(@"uploadCommentWithCommentDic Body : %@", commentStr);
    NSData *commentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:commentDic error:nil];
    
    __weak __typeof(self) weakSelf = self;
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:commentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([data isKindOfClass:[NSDictionary class]]) {
                
                NSInteger likeNum = [[data objectForKey:@"postLikeNum"] integerValue];
                NSInteger postCommentNum = [[data objectForKey:@"postCommentNum"] integerValue];
                NSDictionary *postCommentData = @{@"postId":[commentDic objectForKey:@"postUUID"], @"postCommentNum":@(postCommentNum)};
                dispatch_async(dispatch_get_main_queue(), ^{
                   [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedCommentNum object:postCommentData];
                });
                [[IMDataManager qimDB_SharedInstance] qimDB_updateMomentWithLikeNum:likeNum WithCommentNum:postCommentNum withPostId:[commentDic objectForKey:@"postUUID"]];
                
                NSArray *deleteComments = [data objectForKey:@"deleteComments"];
                if ([deleteComments isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteComments:deleteComments];
                }
                NSArray *newComment = [data objectForKey:@"newComment"];
                if ([newComment isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertComments:newComment];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkComment object:[newComment firstObject]];
                        NSInteger likeNum = [[data objectForKey:@"postLikeNum"] integerValue];
                        BOOL isPostLike = [[data objectForKey:@"isPostLike"] boolValue];
                        NSDictionary *likeData = @{@"postId":[commentDic objectForKey:@"postUUID"], @"likeNum":@(likeNum), @"isLike":@(isPostLike)};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedLike object:likeData];
                        NSInteger postCommentNum = [[data objectForKey:@"postCommentNum"] integerValue];
                        NSDictionary *postCommentData = @{@"postId":[commentDic objectForKey:@"postUUID"], @"postCommentNum":@(postCommentNum)};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedCommentNum object:postCommentData];
                        [[IMDataManager qimDB_SharedInstance] qimDB_updateMomentWithLikeNum:likeNum WithCommentNum:postCommentNum withPostId:[commentDic objectForKey:@"postUUID"]];
                    });
                }
            } else {

            }
        }
    } withFailedCallBack:^(NSError *error) {

    }];
}

- (void)getRemoteRecentHotCommentsWithMomentId:(NSString *)momentId withHotCommentCallBack:(QIMKitWorkCommentBlock)callback {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/getHotComment/V2", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    [bodyDic setObject:momentId forKey:@"uuid"];
    
    QIMVerboseLog(@"HotComment : %@", bodyDic);
    NSData *hotCommentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;

    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:hotCommentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSArray *newComment = [data objectForKey:@"newComment"];
                if ([newComment isKindOfClass:[NSArray class]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(newComment);
                        }
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)getRemoteRecentNewCommentsWithMomentId:(NSString *)momentId withNewCommentCallBack:(QIMKitWorkCommentBlock)callback {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/getNewComment/V2", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    [bodyDic setQIMSafeObject:momentId forKey:@"postUUID"];
    [bodyDic setQIMSafeObject:@(20) forKey:@"pgSize"];
    [bodyDic setQIMSafeObject:[self getHotCommentUUIdsForMomentId:momentId] forKey:@"hotCommentUUID"];

    QIMVerboseLog(@"cricle_camel/getNewComment/V2 : %@", bodyDic);
    NSData *hotCommentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;
    
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:hotCommentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSArray *deteleComments = [data objectForKey:@"deleteComments"];
                if ([deteleComments isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteComments:deteleComments];
                }
                NSArray *newComment = [data objectForKey:@"newComment"];
                if ([newComment isKindOfClass:[NSArray class]] && newComment.count > 0) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertComments:newComment];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSInteger likeNum = [[data objectForKey:@"postLikeNum"] integerValue];
                        BOOL isPostLike = [[data objectForKey:@"isPostLike"] boolValue];
                        NSDictionary *likeData = @{@"postId":momentId, @"likeNum":@(likeNum), @"isLike":@(isPostLike)};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedLike object:likeData];
                        NSInteger postCommentNum = [[data objectForKey:@"postCommentNum"] integerValue];
                        NSDictionary *postCommentData = @{@"postId":momentId, @"postCommentNum":@(postCommentNum)};
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedCommentNum object:postCommentData];
                        [[IMDataManager qimDB_SharedInstance] qimDB_updateMomentWithLikeNum:likeNum WithCommentNum:postCommentNum withPostId:momentId];
                        if (callback) {
                            callback(newComment);
                        }
                    });
                } else {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteCommentsWithPostId:momentId];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(@[]);
                        }
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)getRemoteCommentsHistoryWithLastCommentId:(NSInteger)commentRId withMomentId:(NSString *)momentId withCommentCallBack:(QIMKitWorkCommentBlock)callback {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/getHistoryComment/V2", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    [bodyDic setObject:@(commentRId) forKey:@"curCommentId"];
    [bodyDic setObject:momentId forKey:@"postUUID"];
    [bodyDic setObject:@(20) forKey:@"pgSize"];
    [bodyDic setQIMSafeObject:[self getHotCommentUUIdsForMomentId:momentId] forKey:@"hotCommentUUID"];
    
    QIMVerboseLog(@"cricle_camel/getHistoryComment : %@", bodyDic);
    NSData *hotCommentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;
    
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:hotCommentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            
            NSDictionary *data = [result objectForKey:@"data"];
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSArray *deteleComments = [data objectForKey:@"deleteComments"];
                if ([deteleComments isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteComments:deteleComments];
                }
                NSArray *newComment = [data objectForKey:@"newComment"];
                if ([newComment isKindOfClass:[NSArray class]] && newComment.count > 0) {
                    //插入历史20条
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertComments:newComment];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(newComment);
                        }
                    });
                } else {
                    //返回空，删除之前的历史
                    long long commentCreateTime = [[IMDataManager qimDB_SharedInstance] qimDB_getCommentCreateTimeWithCurCommentId:commentRId];
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteCommentsWithPostId:momentId withcurCommentCreateTime:commentCreateTime];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (callback) {
                            callback(@[]);
                        }
                    });
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(nil);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(nil);
            }
        });
    }];
}

- (void)deleteRemoteCommentWithComment:(NSString *)commentId withPostUUId:(NSString *)postUUId withSuperParentUUId:(NSString *)superParentUUID withCallback:(QIMKitWorkCommentDeleteSuccessBlock)callback {
    if (commentId.length <= 0 || postUUId <= 0) {
        return;
    }
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/deleteComment/V2", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSDictionary *bodyDic = @{@"commentUUID":commentId, @"postUUID":postUUId, @"superParentUUID":superParentUUID};
    NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
            
                NSInteger postCommentNum = [[data objectForKey:@"postCommentNum"] integerValue];
                NSInteger likeNum = [[data objectForKey:@"postLikeNum"] integerValue];
                [[IMDataManager qimDB_SharedInstance] qimDB_updateMomentWithLikeNum:likeNum WithCommentNum:postCommentNum withPostId:postUUId];
                NSDictionary *postCommentData = @{@"postId":postUUId, @"postCommentNum":@(postCommentNum)};
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifyReloadWorkFeedCommentNum object:postCommentData];
                });
                
                NSDictionary *deleteCommentData = [data objectForKey:@"deleteCommentData"];
                if ([deleteCommentData isKindOfClass:[NSDictionary class]]) {
                    NSString *commentUUID = [deleteCommentData objectForKey:@"commentUUID"];
                    BOOL isDeleteFlag = [[deleteCommentData objectForKey:@"isDelete"] boolValue];
                    NSString *superParentCommentUUID = [deleteCommentData objectForKey:@"superParentCommentUUID"];
                    NSInteger superParentStatus = [[deleteCommentData objectForKey:@"superParentStatus"] integerValue];
                    if (isDeleteFlag == YES) {
                        
                        if (superParentStatus == 0) {
                            //0主评论没有被删除,正常只删这一条评论
                            NSDictionary *deleteCommentDic = @{@"uuid":commentUUID, @"isDelete":@(YES)};
                            [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteComments:@[deleteCommentDic]];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (callback) {
                                    callback(YES);
                                }
                            });
                        } else if (superParentStatus == 1) {
                            //1标识主评论已被删除但是还有子评论在客户端需标识该评论已被删除
                            NSDictionary *deleteCommentDic = @{@"uuid":commentUUID, @"isDelete":@(YES)};
                            [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteComments:@[deleteCommentDic]];
                            
                            //更新主评论为“该评论已被删除”
                            [[IMDataManager qimDB_SharedInstance] qimDB_bulkUpdateComments:nil];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (callback) {
                                    callback(YES);
                                }
                            });
                        } else if (superParentStatus == 2) {
                            //2标识主评论已删除且没有了子评论在客户端可直接删除掉
                            [[IMDataManager qimDB_SharedInstance] qimDB_bulkDeleteCommentsAndAllChildComments:nil];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (callback) {
                                    callback(YES);
                                }
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (callback) {
                                    callback(NO);
                                }
                            });
                        }
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (callback) {
                                callback(NO);
                            }
                        });
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (callback) {
                        callback(NO);
                    }
                });
            }
        }
    } withFailedCallBack:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(NO);
            }
        });
    }];
}

#pragma mark - 用户入口

- (void)getCricleCamelEntrance {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/entrance", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];

    [self sendTPGetRequestWithUrl:destUrl withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        if ([result isKindOfClass:[NSDictionary class]]) {
            BOOL ret = [[result objectForKey:@"ret"] boolValue];
            NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
            if (ret && errcode == 0) {
                [[QIMUserCacheManager sharedInstance] setUserObject:@(YES) forKey:@"kUserWorkFeedEntrance"];
            } else {
                [[QIMUserCacheManager sharedInstance] setUserObject:@(NO) forKey:@"kUserWorkFeedEntrance"];
            }
        }
    } withFailedCallBack:^(NSError *error) {
        [[QIMUserCacheManager sharedInstance] setUserObject:@(NO) forKey:@"kUserWorkFeedEntrance"];
    }];
}

#pragma mark - Remote Notice

- (void)getupdateRemoteWorkNoticeMsgs {
//    {@"messageTime":0, "user":"lilulucas.li", "userHost":"ejabhost1", "messageId":"123"}
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/message/getMessageList", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    long long maxTime = [[IMDataManager qimDB_SharedInstance] qimDB_getWorkNoticeMessagesMaxTime];
    [bodyDic setObject:@(self.lastWorkFeedMsgMsgTime) forKey:@"messageTime"];
    [bodyDic setObject:[QIMManager getLastUserName] forKey:@"user"];
    [bodyDic setObject:[[QIMManager sharedInstance] getDomain] forKey:@"userHost"];
    
    QIMVerboseLog(@"message/getMessageList Body : %@", bodyDic);
    NSData *noticeReadStateData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;
    
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:noticeReadStateData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            NSDictionary *data = [result objectForKey:@"data"];
            if ([data isKindOfClass:[NSDictionary class]]) {
                NSArray *msgList = [data objectForKey:@"msgList"];
                if ([msgList isKindOfClass:[NSArray class]]) {
                    [[IMDataManager qimDB_SharedInstance] qimDB_bulkinsertNoticeMessage:msgList];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //发送驼圈离线消息通知
                        [[NSNotificationCenter defaultCenter] postNotificationName:kPBPresenceCategoryNotifyWorkNoticeMessage object:nil];
                        //发送驼圈离线消息小红点通知
                        NSInteger notReadMessageCount = [[QIMManager sharedInstance] getWorkNoticeMessagesCount];
                        QIMVerboseLog(@"发送驼圈离线消息小红点通知数: %ld", notReadMessageCount);
                        [[NSNotificationCenter defaultCenter] postNotificationName:kExploreNotReadCountChange object:@(notReadMessageCount)];
                    });
                }
            }
            QIMVerboseLog(@"拉取离work线消息成功");
            QIMVerboseLog(@"清除本地work线消息时间戳");
            [[QIMUserCacheManager sharedInstance] removeUserObjectForKey:kGetWorkFeedHistoryMessageListError];
            QIMVerboseLog(@"强制塞本地驼圈消息消息时间戳完成之后再取一下本地错误时间戳 : %lld", [[[QIMUserCacheManager sharedInstance] userObjectForKey:kGetWorkFeedHistoryMessageListError] longLongValue]);
        } else {
            QIMVerboseLog(@"拉取离work线消息失败");
            QIMVerboseLog(@"重新set本地work线消息时间戳");
            [[QIMUserCacheManager sharedInstance] setUserObject:@(self.lastWorkFeedMsgMsgTime) forKey:kGetWorkFeedHistoryMessageListError];
            QIMVerboseLog(@"强制塞本地驼圈消息消息时间戳完成之后再取一下本地错误时间戳 : %lld", [[[QIMUserCacheManager sharedInstance] userObjectForKey:kGetWorkFeedHistoryMessageListError] longLongValue]);
        }
    } withFailedCallBack:^(NSError *error) {
        QIMVerboseLog(@"拉取离work线消息失败");
        QIMVerboseLog(@"重新set本地work线消息时间戳");
        [[QIMUserCacheManager sharedInstance] setUserObject:@(self.lastWorkFeedMsgMsgTime) forKey:kGetWorkFeedHistoryMessageListError];
        QIMVerboseLog(@"强制塞本地驼圈消息消息时间戳完成之后再取一下本地错误时间戳 : %lld", [[[QIMUserCacheManager sharedInstance] userObjectForKey:kGetWorkFeedHistoryMessageListError] longLongValue]);
    }];
}

- (void)updateRemoteWorkNoticeMsgReadStateWithTime:(long long)time {
    NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/message/readMark", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
    NSMutableDictionary *bodyDic = [[NSMutableDictionary alloc] init];
    [bodyDic setObject:@(time) forKey:@"time"];
    
    QIMVerboseLog(@"/message/readMark : %@", bodyDic);
    NSData *noticeReadStateData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
    __weak __typeof(self) weakSelf = self;
    
    [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:noticeReadStateData withSuccessCallBack:^(NSData *responseData) {
        NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
        BOOL ret = [[result objectForKey:@"ret"] boolValue];
        NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
        if (ret && errcode == 0) {
            QIMVerboseLog(@"设置已读成功");
        } else {
            QIMVerboseLog(@"设置已读失败");
        }
    } withFailedCallBack:^(NSError *error) {

    }];
}

#pragma mark - Local Moments

- (void)getRemoteLastWorkMoment {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *destUrl = [NSString stringWithFormat:@"%@/cricle_camel/post/getPostList", [[QIMNavConfigManager sharedInstance] newerHttpUrl]];
        NSMutableDictionary *bodyDic = [NSMutableDictionary dictionaryWithCapacity:1];
        [bodyDic setQIMSafeObject:@(0) forKey:@"postCreateTime"];
        [bodyDic setQIMSafeObject:nil forKey:@"owner"];
        [bodyDic setQIMSafeObject:nil forKey:@"ownerHost"];
        [bodyDic setQIMSafeObject:@(1) forKey:@"pageSize"];
        [bodyDic setQIMSafeObject:@(0) forKey:@"getTop"];
        [bodyDic setQIMSafeObject:@(0) forKey:@"postType"];
        
        QIMVerboseLog(@"post/getPostList : %@", bodyDic);
        NSData *momentBodyData = [[QIMJSONSerializer sharedInstance] serializeObject:bodyDic error:nil];
        [self sendTPPOSTRequestWithUrl:destUrl withRequestBodyData:momentBodyData withSuccessCallBack:^(NSData *responseData) {
            NSDictionary *result = [[QIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
            BOOL ret = [[result objectForKey:@"ret"] boolValue];
            NSInteger errcode = [[result objectForKey:@"errcode"] integerValue];
            if (ret && errcode == 0) {
                NSDictionary *moments = [result objectForKey:@"data"];
                if ([moments isKindOfClass:[NSDictionary class]]) {
                    NSArray *deletePosts = [moments objectForKey:@"deletePost"];
                    NSArray *newPosts = [moments objectForKey:@"newPost"];
                    if ([deletePosts isKindOfClass:[NSArray class]]) {
                        [[IMDataManager qimDB_SharedInstance] qimDB_bulkdeleteMoments:deletePosts];
                    }
                    if ([newPosts isKindOfClass:[NSArray class]]) {
                        if (newPosts.count > 0) {
                            NSDictionary *lastMomentDic = [newPosts firstObject];
                            NSDictionary *momoentDic = [self getLastWorkMomentWithDic:lastMomentDic];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotify_RN_QTALK_SUGGEST_WorkFeed_UPDATE object:momoentDic];
                            });
                        } else {
                            NSDictionary *localLastMomentDic = [self getLastWorkMoment];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotify_RN_QTALK_SUGGEST_WorkFeed_UPDATE object:localLastMomentDic];
                            });
                        }
                    } else {
                        
                    }
                } else {
                }
            }
        } withFailedCallBack:^(NSError *error) {
            
        }];
    });
}

- (NSDictionary *)getLastWorkOnlineMomentWithDic:(NSDictionary *)dic {
    NSLog(@"getLastWorkOnlineMomentWithDic : %@", dic);
    NSMutableDictionary *momentDic = [[NSMutableDictionary alloc] init];
    NSString *userId = [NSString stringWithFormat:@"%@@%@", [dic objectForKey:@"owner"], [dic objectForKey:@"ownerHost"]];
    NSString *userName = [[QIMManager sharedInstance] getUserMarkupNameWithUserId:userId];
    NSString *photoUrl = nil;
    
    BOOL fromIsAnonymous = [[dic objectForKey:@"isAnyonous"] boolValue];
    if (fromIsAnonymous == YES) {
        userName = [dic objectForKey:@"anyonousName"];
        photoUrl = [dic objectForKey:@"anyonousPhoto"];
        if (![photoUrl qim_hasPrefixHttpHeader] && photoUrl.length > 0) {
            photoUrl = [NSString stringWithFormat:@"%@/%@", [[QIMNavConfigManager sharedInstance] innerFileHttpHost], photoUrl];
        }
    } else {
        NSDictionary *userInfo = [[QIMManager sharedInstance] getUserInfoByUserId:userId];
        NSString *department = [userInfo objectForKey:@"DescInfo"]?[userInfo objectForKey:@"DescInfo"]:@"";
        NSString *lastDp = [[department componentsSeparatedByString:@"/"] objectAtIndex:2];
        photoUrl = [userInfo objectForKey:@"HeaderSrc"];
        if (![photoUrl qim_hasPrefixHttpHeader] && photoUrl.length > 0) {
            photoUrl = [NSString stringWithFormat:@"%@/%@", [[QIMNavConfigManager sharedInstance] innerFileHttpHost], photoUrl];
        }
        [momentDic setQIMSafeObject:lastDp?lastDp:@"未知" forKey:@"architecture"];
    }
    
    NSString *content = [dic objectForKey:@"content"];
    
    [momentDic setQIMSafeObject:(content.length > 0) ? content : @"分享图片" forKey:@"content"];
    [momentDic setQIMSafeObject:userName forKey:@"name"];
    [momentDic setQIMSafeObject:(photoUrl.length > 0) ? photoUrl : [QIMManager defaultUserHeaderImagePath] forKey:@"photo"];
    QIMVerboseLog(@"RN getLastWorkOnlineMomentWithDic : %@", momentDic);
    return momentDic;
}

- (NSDictionary *)getLastWorkMomentWithDic:(NSDictionary *)dic {
    NSLog(@"getLastWorkMomentWithDic : %@", dic);
    NSMutableDictionary *momentDic = [[NSMutableDictionary alloc] init];
    NSString *userId = [NSString stringWithFormat:@"%@@%@", [dic objectForKey:@"owner"], [dic objectForKey:@"ownerHost"]];
    NSString *userName = [[QIMManager sharedInstance] getUserMarkupNameWithUserId:userId];
    NSString *photoUrl = nil;
    
    BOOL fromIsAnonymous = [[dic objectForKey:@"isAnonymous"] boolValue];
    if (fromIsAnonymous == YES) {
        userName = [dic objectForKey:@"anonymousName"];
        photoUrl = [dic objectForKey:@"anonymousPhoto"];
        if (![photoUrl qim_hasPrefixHttpHeader] && photoUrl.length > 0) {
            photoUrl = [NSString stringWithFormat:@"%@/%@", [[QIMNavConfigManager sharedInstance] innerFileHttpHost], photoUrl];
        }
    } else {
        NSDictionary *userInfo = [[QIMManager sharedInstance] getUserInfoByUserId:userId];
        NSString *department = [userInfo objectForKey:@"DescInfo"]?[userInfo objectForKey:@"DescInfo"]:@"";
        NSString *lastDp = [[department componentsSeparatedByString:@"/"] objectAtIndex:2];
        photoUrl = [userInfo objectForKey:@"HeaderSrc"];
        if (![photoUrl qim_hasPrefixHttpHeader] && photoUrl.length > 0) {
            photoUrl = [NSString stringWithFormat:@"%@/%@", [[QIMNavConfigManager sharedInstance] innerFileHttpHost], photoUrl];
        }
        [momentDic setQIMSafeObject:lastDp?lastDp:@"未知" forKey:@"architecture"];
    }
    
    NSString *content = [dic objectForKey:@"content"];
    NSDictionary *contentDic = [[QIMJSONSerializer sharedInstance] deserializeObject:content error:nil];
    NSString *showContent = [contentDic objectForKey:@"content"];
    
    [momentDic setQIMSafeObject:(showContent.length > 0) ? showContent : @"分享图片" forKey:@"content"];
    [momentDic setQIMSafeObject:userName forKey:@"name"];
    [momentDic setQIMSafeObject:(photoUrl.length > 0) ? photoUrl : [QIMManager defaultUserHeaderImagePath] forKey:@"photo"];
    QIMVerboseLog(@"RN getLastWorkMoment : %@", momentDic);
    return momentDic;
}

- (NSDictionary *)getLastWorkMoment {
    NSDictionary *result = [[IMDataManager qimDB_SharedInstance] qimDB_getLastWorkMoment];
    return [self getLastWorkMomentWithDic:result];
}

- (NSDictionary *)getWorkMomentWithMomentId:(NSString *)momentId {
    return [[IMDataManager qimDB_SharedInstance] qimDB_getWorkMomentWithMomentId:momentId];
}

- (void)getWorkMomentWithLastMomentTime:(long long)lastMomentTime withUserXmppId:(NSString *)xmppId WithLimit:(int)limit WithOffset:(int)offset withFirstLocalMoment:(BOOL)firstLocal WithComplete:(void (^)(NSArray *))complete{
    if (firstLocal) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSArray *array = [[IMDataManager qimDB_SharedInstance] qimDB_getWorkMomentWithXmppId:xmppId WithLimit:limit WithOffset:offset];
            if (array.count > 0) {
                __block NSMutableArray *list = [NSMutableArray arrayWithArray:array];
                if (list.count >= limit) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(list);
                    });
                } else {
                    
                    NSDictionary *momentDic = [array lastObject];
                    QIMVerboseLog(@"last momentDic : %@", momentDic);
                    long long time = [[momentDic objectForKey:@"createTime"] longLongValue];
                    if (self.load_history_msg == nil) {
                        self.load_history_msg = dispatch_queue_create("Load History", 0);
                    }
                    dispatch_async(self.load_history_msg, ^{
                        [[QIMManager sharedInstance] getMomentHistoryWithLastUpdateTime:time withOwnerXmppId:xmppId withCallBack:^(NSArray *moments) {
                            [list addObjectsFromArray:moments];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                complete(list);
                            });
                        }];
                    });
                }
            }
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[QIMManager sharedInstance] getMomentHistoryWithLastUpdateTime:lastMomentTime withOwnerXmppId:xmppId withCallBack:^(NSArray *moments) {
                if (moments.count > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(moments);
                    });
                } else {
                    NSArray *array = [[IMDataManager qimDB_SharedInstance] qimDB_getWorkMomentWithXmppId:xmppId WithLimit:limit WithOffset:offset];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(array);
                    });
                }
            }];
        });
    }
}

#pragma mark - Local Comments

- (void)getWorkCommentWithLastCommentRId:(NSInteger)lastCommentRId withMomentId:(NSString *)momentId WithLimit:(int)limit WithOffset:(int)offset withFirstLocalComment:(BOOL)firstLocal WithComplete:(void (^)(NSArray *))complete{
    if (firstLocal) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSArray *array = [[IMDataManager qimDB_SharedInstance] qimDB_getWorkCommentsWithMomentId:momentId WithLimit:limit WithOffset:offset];
            if (array.count > 0) {
                __block NSMutableArray *list = [NSMutableArray arrayWithArray:array];
                if (list.count >= limit) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(list);
                    });
                } else {
                    NSDictionary *commentDic = [array lastObject];
                    NSInteger commentRId = [[commentDic objectForKey:@"rid"] integerValue];
                    NSLog(@"commentDic : %@", commentDic);
                    if (self.load_history_msg == nil) {
                        self.load_history_msg = dispatch_queue_create("Load History", 0);
                    }
                     dispatch_async(self.load_history_msg, ^{
                        [[QIMManager sharedInstance] getRemoteCommentsHistoryWithLastCommentId:commentRId withMomentId:momentId withCommentCallBack:^(NSArray *comments) {
                            [list addObjectsFromArray:comments];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                complete(list);
                            });
                        }];
                    });
                }
            }
        });
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[QIMManager sharedInstance] getRemoteCommentsHistoryWithLastCommentId:lastCommentRId withMomentId:momentId withCommentCallBack:^(NSArray *comments) {
                if (comments) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(comments);
                    });
                } else {
                    NSArray *array = [[IMDataManager qimDB_SharedInstance] qimDB_getWorkCommentsWithMomentId:momentId WithLimit:limit WithOffset:offset];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(array);
                    });
                }
            }];
        });
    }
}

- (NSArray *)getWorkChildCommentsWithParentCommentUUID:(NSString *)parentCommentUUID {
    return [[IMDataManager qimDB_SharedInstance] qimDB_getWorkChildCommentsWithParentCommentUUID:parentCommentUUID];
}

- (NSInteger)getWorkNoticeMessagesCount {
    return [[IMDataManager qimDB_SharedInstance] qimDB_getWorkNoticeMessagesCount];
}

- (NSArray *)getWorkNoticeMessagesWithLimit:(int)limit WithOffset:(int)offset {
    return [[IMDataManager qimDB_SharedInstance] qimDB_getWorkNoticeMessagesWithLimit:limit WithOffset:offset];
}

- (void)updateLocalWorkNoticeMsgReadStateWithTime:(long long)time {
    [[IMDataManager qimDB_SharedInstance] qimDB_updateWorkNoticeMessageReadStateWithTime:time];
}

@end
