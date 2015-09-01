//
//  ChatTableViewController.h
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/5.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPManager.h"

@interface ChatTableViewController : UITableViewController

@property (nonatomic, strong) XMPPJID *chatToJID;   // 用来记录传值的jid

@end
