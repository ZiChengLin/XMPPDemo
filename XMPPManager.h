//
//  XMPPManager.h
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/4.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

/**
 *  该类主要封装XMPP的常用方法
 */
@interface XMPPManager : NSObject

@property (nonatomic, strong) XMPPStream *xmppStream;      // 通信管道、输入输出流

@property (nonatomic, strong) XMPPRoster *xmppRoster;      // 负责管理好友的

@property (nonatomic, strong) XMPPMessageArchiving   *xmppMessageArchiving;    // 聊天信息归档 CoreData 需结合上下文
@property (nonatomic, strong) NSManagedObjectContext *messageArchivingContext; // 上下文

+ (XMPPManager *)defaultManager;   // 单例

// 登陆注册的方法
- (void)loginWithName:(NSString *)userName andPassword:(NSString *)password;
- (void)registerWithName:(NSString *)userName andPassword:(NSString *)password;

// 注销的方法
- (void)logout;

@end



