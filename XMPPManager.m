//
//  XMPPManager.m
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/4.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import "XMPPManager.h"

// 连接服务器时判断是登陆还是注册（枚举类型、枚举名称）
typedef NS_ENUM(NSInteger, ConnectToServerPurpose) {
    
    ConnectToServerPurposeLogin,      // 登陆
    ConnectToServerPurposeRegister    // 注册
};

/**
 *  遵守两个协议
 *  XMPPStreamDelegate 登陆注册的代理
 *  XMPPRosterDelegate 处理好友管理的代理
 */
@interface XMPPManager ()<XMPPStreamDelegate, XMPPRosterDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) NSString *password;  // 用来记录用户输入的密码 因为在连接成功的代理方法里需要使用
@property (nonatomic) ConnectToServerPurpose connectToServerPursose;  // 定义一个枚举属性

@property (nonatomic, strong) XMPPJID  *fromJid;   // 对方申请好友的Jid;

@end

@implementation XMPPManager

+ (XMPPManager *)defaultManager {
    
    static XMPPManager *manager = nil;
    
    // 快捷单例方法的写法
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[XMPPManager alloc] init];
    });
    return manager;
}

/**
 *  重写初始化方法、因为需要在manager在开始创建的时候就要使用一个功能
 */
- (instancetype)init {
    
    if ([super init]) {
        
        /*****************************登陆、注册*******************************/
        
        // 初始化XMPPStream（登陆和注册的时候都会使用到XMPPStream）
        self.xmppStream = [[XMPPStream alloc] init];
        // 设置服务器地址（127.0.0.1是本地主机服务器 公司的话换成公司的服务器地址即可）
        self.xmppStream.hostName = @"127.0.0.1";
        // 设置端口号
        self.xmppStream.hostPort = 5222;
        // 设置代理
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        
        /*****************************好友管理*******************************/
        
        // 获得一个存储好友的CoreData数据库 用来做数据持久化
        XMPPRosterCoreDataStorage *rosterCoreDataStorage = [XMPPRosterCoreDataStorage sharedInstance];
        // 初始化xmppRoster
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:rosterCoreDataStorage dispatchQueue:dispatch_get_main_queue()];
        // 激活
        [self.xmppRoster activate:self.xmppStream];
        // 设置代理
        [self.xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        
        /*****************************保存聊天记录*******************************/
        
        // 初始化一个仓库
        XMPPMessageArchivingCoreDataStorage *messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
        // 创建一个消息归档对象放到仓库里面
        self.xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:messageStorage dispatchQueue:dispatch_get_main_queue()];
        // 激活
        [self.xmppMessageArchiving activate:self.xmppStream];
        // 赋给上下文
        self.messageArchivingContext = messageStorage.mainThreadManagedObjectContext;
        
    }
    return self;
}

- (void)loginWithName:(NSString *)userName andPassword:(NSString *)password {
    /*
     1、初始化XMPPStream
     2、连接服务器（成功或者失败）
     3、发送密码向服务器验证（成功或者失败）
     4、发送上线消息
    */
    
    self.connectToServerPursose = ConnectToServerPurposeLogin;  // 标示当前的连接方式为登陆
    
    // 创建一个XMPPJID（属性：用户名、域名-服务器名称、客户端-可自定义机型）resource登陆服务器的方式
    XMPPJID *jid = [XMPPJID jidWithUser:userName domain:@"lin" resource:@"iphone6s"];
    self.xmppStream.myJID = jid;
    [self connectToServer];
    
    //连接服务器 有可能成功或者失败 所以这里需要实现相应的代理方法
    self.password = password;   // 把密码取出来
}

- (void)registerWithName:(NSString *)userName andPassword:(NSString *)password {
    
    self.connectToServerPursose = ConnectToServerPurposeRegister;
    
    // 创建一个XMPPJID
    XMPPJID *jid = [XMPPJID jidWithUser:userName domain:@"lin" resource:@"iphone6s"];
    // 将jid绑定到xmppStream里面
    self.xmppStream.myJID = jid;
    // 连接服务器
    [self connectToServer];
    
    self.password = password;  // 把注册都密码取出来
}

/**
 *  封装连接服务器的方法 因为这里登陆和注册里面都用到了 所以优化代码的时候可以把它单独拿出来
 */
- (void)connectToServer {
    
    // 如果已经存在一个连接 需要将当前连接断开 然后开始新的连接
    if ([self.xmppStream isConnected]) {
        
        [self logout];
    }
    
    NSError *error = nil;
    // 连接服务器
    [self.xmppStream connectWithTimeout:30.0f error:&error];
    if (error) {
        
        NSLog(@"error = %@", error);
    }
}

#pragma mark -- 注销的方法
- (void)logout {
    
    // unavailable表示离线不可用
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    // 向服务器发送离线消息
    [self.xmppStream sendElement:presence];
    // 断开链接
    [self.xmppStream disconnect];
}

#pragma mark -- XMPPStreamDelegate的代理方法
#pragma mark -- 连接服务器成功的方法
- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    
    NSLog(@"连接服务器成功的方法、验证密码");
    
    // 先判断当前是登陆连接还是注册的连接
    if (self.connectToServerPursose == ConnectToServerPurposeLogin) {
        
        NSError *error = nil;
        [sender authenticateWithPassword:self.password error:&error];
        if (error) {
            
            NSLog(@"error = %@", error);
        }
        // 这里需要验证有可能成功和失败
        
    } else if (self.connectToServerPursose == ConnectToServerPurposeRegister) {
        
        NSError *error = nil;
        [sender registerWithPassword:self.password error:&error];
        if (error) {
            
            NSLog(@"error = %@", error);
        }
        // 这里需要验证是否注册成功和失败
    }
}

#pragma mark -- 连接服务器失败的方法
- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender {
    
    NSLog(@"连接服务器失败的方法、一般弹出请查看网络连接是否正常");
}

#pragma mark -- 验证密码成功的方法
-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    
    NSLog(@"验证成功的方法");
    
    /** 状态
     *  unavailable:离线
     *  available  :上线
     *  away       :离开
     *  do not disturb :忙碌
     */
    
    // 发送上线消息
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"available"];
    [self.xmppStream sendElement:presence];
}

#pragma mark -- 验证密码失败的方法
- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    
    NSLog(@"验证失败的方法、一般弹出请检查你的密码和用户名是否正确");
}

#pragma mark -- 注册成功的方法
- (void)xmppStreamDidRegister:(XMPPStream *)sender {
    
    NSLog(@"注册成功的方法");
}

#pragma mark -- 注册失败的方法
- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error {
    
    NSLog(@"注册失败的方法、一般弹出请检查你注册的用户名和密码是否正确");
}
@end
