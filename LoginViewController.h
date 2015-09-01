//
//  LoginViewController.h
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/4.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@end


/**
 *  XMPP 工程配置
 
    1、将XMPP框架文件夹导入工程中
    2、添加libxml2.dylib和libresolv.dylib静态库（配置other link flages - lxml2还有Header search path - /usr/include/libxml2）
    3、添加.pch文件 并添加#import<UIKit/UIKit.h>头文件 （1、Precompile prefix Header 改为YES 2、Prefix Header - 工程名/.pch文件名XMPPDemo/PrefixHeader.pch）
 
    4、封装XMPPManager
    （1）登陆
     初始化一个XMPPStream（服务器:lin 端口号:5222）
     连接服务器（JID-账号）。。。一大堆代理方法
    （2）注册
    （3）注销
 
    具体内容详见DEMO
 */