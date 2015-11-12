//
//  ViewController.m
//  ImageCropDemo
//
//  Created by yinyu on 15/11/10.
//  Copyright © 2015年 yinyu. All rights reserved.
//

#import "ViewController.h"
#import "CropImageViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *toCropImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationHandler:) name: @"CropOK" object: nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)clickStartBtn:(id)sender {
    CropImageViewController *cropImageViewController = [[CropImageViewController alloc]initWithNibName:@"CropImageViewController" bundle:nil];
    [self presentViewController:cropImageViewController animated:YES completion:NULL];
}
- (void)notificationHandler: (NSNotification *)notification {
    self.toCropImageView.image = notification.object;
}
@end
