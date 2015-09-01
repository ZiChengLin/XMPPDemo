//
//  LoginViewController.m
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/4.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import "LoginViewController.h"
#import "RosterTableViewController.h"
#import "XMPPManager.h"

@interface LoginViewController ()<XMPPStreamDelegate>

@property (weak, nonatomic) IBOutlet UITextField *userNameTf;
@property (weak, nonatomic) IBOutlet UITextField *passWordTf;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 设置代理
    [[XMPPManager defaultManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

// 验证成功的方法 判断一下 LoginViewController才能推到好友页面
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    
    RosterTableViewController *rosterTableViewController = [[RosterTableViewController alloc] init];
    
    [self.navigationController pushViewController:rosterTableViewController animated:YES];
}

- (IBAction)loginAction:(id)sender {
    
    if (self.userNameTf.text.length == 0 || self.passWordTf.text.length == 0) {
        
        NSLog(@"用户名和密码不能为空");
    }
    [[XMPPManager defaultManager] loginWithName:self.userNameTf.text andPassword:self.passWordTf.text];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
