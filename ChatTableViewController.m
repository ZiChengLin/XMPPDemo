//
//  ChatTableViewController.m
//  XMPPDemo
//
//  Created by 林梓成 on 15/8/5.
//  Copyright (c) 2015年 lin. All rights reserved.
//

#import "ChatTableViewController.h"

@interface ChatTableViewController ()<XMPPStreamDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>   // 调用相册的方法遵守的两个协议

@property (nonatomic, strong) NSMutableArray *messages;  // 用来存储聊天记录的数组

@end

@implementation ChatTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化聊天数组
    self.messages = [NSMutableArray array];
    [[XMPPManager defaultManager].xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    // 创建一个发送消息的按钮
    UIBarButtonItem *ritem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStylePlain target:self action:@selector(doSend)];
    self.navigationItem.rightBarButtonItem = ritem;
    
    [self reloadMessage];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 100, 40);
    [btn setTitle:@"发送图片" forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor orangeColor];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.titleView = btn;
}

#pragma mark - 发送图片到方法
- (void)btnAction:(UIButton *)btn {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:^{
        
    }];
}

#pragma mark - 调用相册的代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // 获取相册的图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    // 先转化为NSData
    NSData *data = UIImagePNGRepresentation(image);

    [self sendImageWithData:data bodyName:@"image"];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 封装一个发送图片的方法
- (void)sendImageWithData:(NSData *)data bodyName:(NSString *)name {
    
    // 创建一个聊天的消息
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.chatToJID];
    // 设置图片的body
    [message addBody:name];
    // 将data转化为NSString
    NSString *base64Str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    // 再转化为消息的节点
    XMPPElement *attachment = [XMPPElement elementWithName:@"attachment" stringValue:base64Str];
    // 添加子节点
    [message addChild:attachment];
    // 发送消息
    [[XMPPManager defaultManager].xmppStream sendElement:message];
    
}

- (void)doSend {
    
    // 创建一个消息对象 并且指明接收者
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:self.chatToJID];
    // 设置发送消息到内容
    [message addBody:@"呵呵"];
    // 发送消息
    [[XMPPManager defaultManager].xmppStream sendElement:message];
    
    // 发送消息有成功和失败两种情况（对应着相应的代理方法）
}

#pragma mark - 聊天的代理方法
#pragma mark - 消息发送成功的方法
- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    
    NSLog(@"消息发送成功");
    [self reloadMessage];
}

#pragma mark - 消息发送失败的方法
- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
    
    
    NSLog(@"消息发送失败，请重新发送");
}

#pragma mark - 已经成功接收消息的方法
- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    
    NSLog(@"已经成功接收消息");
    [self reloadMessage];
}

#pragma mark - 封装刷新消息的方法
- (void)reloadMessage {
    
    // 得到上下文
    NSManagedObjectContext *context = [XMPPManager defaultManager].messageArchivingContext;
    // 创建一个查询对象
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    // 创建一个实体描述 entityForyName:在XMPPFramework.h文件里面的 XMPPMessageArchivingCoreDataStorage.m文件里面的54行
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPMessageArchiving_Message_CoreDataObject" inManagedObjectContext:context];
    [request setEntity:entity];
    
    // 查询条件
    NSPredicate *pre = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@ AND bareJidStr == %@", [XMPPManager defaultManager].xmppStream.myJID.bare, self.chatToJID.bare];
    
    request.predicate = pre;
    
    // 排序方式（timestamp时间戳 根据时间戳排序）
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
    request.sortDescriptors = @[sort];
    
    // 执行查询
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (error) {
        
       NSLog(@"error = %@", error);
    }
    if (self.messages.count!= 0) {
        
        [self.messages removeAllObjects];
        
    }
    [self.messages addObjectsFromArray:array];
    
    [self.tableView reloadData];
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
    return self.messages.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    // 将聊天信息放在cell上面
    XMPPMessageArchiving_Message_CoreDataObject *message = self.messages[indexPath.row];
    // 拿到一个聊天消息
    XMPPMessage *msg = message.message;
    // 发送的消息
    if (message.isOutgoing == YES) {
        
        cell.detailTextLabel.text = message.body;
        cell.textLabel.text = @"";
        
        for (XMPPElement *node in msg.children) {
            
            // 取出消息
            NSString *base64Str = node.stringValue;
            // 将base64的字符串转化为NSData
            NSData *data = [[NSData alloc] initWithBase64EncodedString:base64Str options:0];
            // 再转化为UIImage
            UIImage *image = [[UIImage alloc] initWithData:data];
            cell.imageView.image = image;
        }
        
        
    } else {
        
        cell.textLabel.text = message.body;
        cell.detailTextLabel.text = @"";
    }

    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
