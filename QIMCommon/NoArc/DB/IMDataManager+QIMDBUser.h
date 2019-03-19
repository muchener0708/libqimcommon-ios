//
//  IMDataManager+QIMDBUser.h
//  QIMCommon
//
//  Created by 李露 on 11/24/18.
//  Copyright © 2018 QIM. All rights reserved.
//

#import "IMDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMDataManager (QIMDBUser)

- (void)qimDB_bulkInsertOrgansUserInfos:(NSArray *)userInfos;

- (NSString *)qimDB_getTimeSmtapMsgIdForDate:(NSDate *)date WithUserId:(NSString *)userId;

- (void)qimDB_bulkUpdateUserSearchIndexs:(NSArray *)searchIndexs;

- (void)qimDB_bulkInsertUserInfosNotSaveDescInfo:(NSArray *)userInfos;

- (void)qimDB_bulkUpdateUserBackInfo:(NSDictionary *)userBackInfo WithXmppId:(NSString *)xmppId;

- (void)qimDB_InsertOrUpdateUserInfos:(NSArray *)userInfos;

- (NSDictionary *)qimDB_selectUserByJID:(NSString *)jid;

- (void)qimDB_clearUserList;

- (void)qimDB_clearUserListForList:(NSArray *)userInfos;

- (void)qimDB_bulkInsertUserInfos:(NSArray *)userInfos;

- (void)qimDB_updateUser:(NSString *)userId WithHeaderSrc:(NSString *)headerSrc WithVersion:(NSString *)version;

- (void)qimDB_bulkUpdateUserCards:(NSArray *)cards;

- (NSString *)qimDB_getUserHeaderSrcByUserId:(NSString *)userId;

- (NSDictionary *)qimDB_selectUserByID:(NSString *)userId;

- (NSDictionary *)qimDB_selectUserBackInfoByXmppId:(NSString *)xmppId;

- (NSDictionary *)qimDB_selectUserByIndex:(NSString *)index;

- (NSArray *)qimDB_selectXmppIdFromSessionList;

- (NSArray *)qimDB_selectXmppIdList;

- (NSArray *)qimDB_selectUserIdList;

- (NSArray *)qimDB_getOrganUserList;

//Select a.UserId, a.XmppId, a.Name, a.DescInfo, a.HeaderSrc, a.UserInfo, a.LastUpdateTime from IM_Group_Member as b left join IM_User as a on a.Name = b.Name where GroupId = 'qtalk客户端开发群@conference.ejabhost1'

- (NSArray *)qimDB_selectUserListBySearchStr:(NSString *)searchStr inGroup:(NSString *) groupId;

- (NSArray *)qimDB_searchUserBySearchStr:(NSString *)searchStr notInGroup:(NSString *)groupId;

- (NSArray *)qimDB_selectUserListBySearchStr:(NSString *)searchStr;

- (NSInteger)qimDB_selectUserListTotalCountBySearchStr:(NSString *)searchStr;

- (NSArray *)qimDB_selectUserListBySearchStr:(NSString *)searchStr WithLimit:(NSInteger)limit WithOffset:(NSInteger)offset;

- (NSDictionary *)qimDB_selectUsersDicByXmppIds:(NSArray *)xmppIds;

- (NSArray *)qimDB_selectUserListByUserIds:(NSArray *)userIds;

- (BOOL)qimDB_checkExitsUser;

@end

NS_ASSUME_NONNULL_END
