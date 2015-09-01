//
//  RosterTableViewController.m
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/4.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import "RosterTableViewController.h"
#import "XMPPManager.h"
#import "ChatTableViewController.h"

@interface RosterTableViewController ()<XMPPRosterDelegate>

@property (nonatomic, strong) NSMutableArray *rosterArray;    // 存放好友的数组

@end

@implementation RosterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化好友数组
    self.rosterArray = [NSMutableArray array];
    
    [[XMPPManager defaultManager].xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 创建一个添加好友的按钮
    UIBarButtonItem *ritem = [[UIBarButtonItem alloc] initWithTitle:@"ADD" style:UIBarButtonItemStylePlain target:self action:@selector(doAdd)];
    self.navigationItem.rightBarButtonItem = ritem;
}

#pragma - mark点击Add执行添加好友的方法
-(void)doAdd {
    
    XMPPJID *jid = [XMPPJID jidWithUser:@"Chun" domain:@"lin" resource:@"iphone6s"];
    [[XMPPManager defaultManager].xmppRoster subscribePresenceToUser:jid];
}

#pragma mark - XMPPRosterDelegate的代理方法
// 开始检索好友列表的方法
- (void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender {
    
    NSLog(@"开始检索好友列表");
}

// 正在检索好友列表的方法
- (void)xmppRoster:(XMPPRoster *)sender didRecieveRosterItem:(DDXMLElement *)item {
    
    NSLog(@"每有一个好友就会走一次的方法");
    
    NSString *jidStr = [[item attributeForName:@"jid"] stringValue];
    XMPPJID *jid = [XMPPJID jidWithString:jidStr];
    
    if ([self.rosterArray containsObject:jid]) {
        
        return;
    }
    // 将好友添加到数组中去
    [self.rosterArray addObject:jid];
    // 添加完数据之后表视图也要相应刷新
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.rosterArray.count-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
}

// 检索好友列表完毕的方法
- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender {
    
    NSLog(@"好友列表检索完毕");
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    // Return the number of rows in the section.
    return self.rosterArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"cells";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    // 拿到该好友
    XMPPJID *jid = self.rosterArray[indexPath.row];
    // 将好友的名字放到好友列表中
    cell.textLabel.text = jid.user;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // 找到要删除的人
        XMPPJID *jid = self.rosterArray[indexPath.row];
        // 将该好友从数据源中删除
        [self.rosterArray removeObjectAtIndex:indexPath.row];
        // UI中的单元格删除
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        // 服务器上也要删除
        [[XMPPManager defaultManager].xmppRoster removeUser:jid];
    }
}

// 点击好友进入聊天界面
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatTableViewController *chatTableViewController = [[ChatTableViewController alloc] init];
    // 将好友的jid属性传值过去
    chatTableViewController.chatToJID = self.rosterArray[indexPath.row];
    
    [self.navigationController pushViewController:chatTableViewController animated:YES];
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
