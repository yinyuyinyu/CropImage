//
//  CropImageViewController.m
//  ImageTailor
//
//  Created by yinyu on 15/10/10.
//  Copyright © 2015年 yinyu. All rights reserved.
//

#import "CropImageViewController.h"
#import "UIImage+Handler.h"

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define CROPPROPORTIONIMAGEWIDTH 30.0f
#define CROPPROPORTIONIMAGESPACE 48.0f
#define CROPPROPORTIONIMAGEPADDING 20.0f
//箭头的宽度
#define ARROWWIDTH 25
//箭头的高度
#define ARROWHEIGHT 22
//两个相邻箭头之间的最短距离
#define ARROWMINIMUMSPACE 20
//箭头单边的宽度
#define ARROWBORDERWIDTH 2
//imageview的左右缩进
#define PADDING 10
//裁剪区域的边框宽度
#define CROPVIEWBORDERWIDTH 2.0f
@interface CropImageViewController () {
    //记录左上角箭头移动的起始位置
    CGPoint startPoint1;
    //记录右上角箭头移动的起始位置
    CGPoint startPoint2;
    //记录左下角箭头移动的起始位置
    CGPoint startPoint3;
    //记录右下角箭头移动的起始位置
    CGPoint startPoint4;
    //记录透明区域移动的起始位置
    CGPoint startPointCropView;
    CGFloat imageScale;
    
    //存储不同缩放比例示意图的图片名
    NSArray *proportionImageNameArr;
    //存储不同缩放比例示意图的高亮图片名
    NSArray *proportionImageNameHLArr;
    //存储不同缩放比例
    NSArray *proportionArr;
    //存储不同缩放比例的按钮
    NSMutableArray *proportionBtnArr;
    //当前选择的缩放比例
    CGFloat currentProportion;
    //当前待裁剪图片的高宽比
    CGFloat imageHWFactor;
}
//待裁剪图片的ImageView
@property (weak, nonatomic) IBOutlet UIImageView *imageHolderView;
//左上角箭头
@property (weak, nonatomic) IBOutlet UIImageView *arrow1;
//右上角箭头
@property (weak, nonatomic) IBOutlet UIImageView *arrow2;
//左下角箭头
@property (weak, nonatomic) IBOutlet UIImageView *arrow3;
//右下角箭头
@property (weak, nonatomic) IBOutlet UIImageView *arrow4;
//透明区域的视图
@property (weak, nonatomic) IBOutlet UIView *cropView;
//黑色蒙板
@property (weak, nonatomic) IBOutlet UIView *cropMaskView;
//缩放比例示意图所在的滚动视图
@property (weak, nonatomic) IBOutlet UIScrollView *cropProportionScrollView;

@end

@implementation CropImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    currentProportion = 0;
    self.cropMaskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [self loadImage];
    [self setUpCropProportionView];
    [self clickProportionBtn: proportionBtnArr[0]];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
/**
 *加载image并根据image的尺寸重新设置imageview的尺寸，取到image的缩放比
 */
- (void)loadImage {
    self.image = [UIImage imageNamed:@"test.jpg"];
    CGRect frame = self.imageHolderView.frame;
    frame.size.width = MIN(frame.size.width, MIN(SCREENWIDTH - 2 * PADDING, SCREENHEIGHT  - 144 - 44));
    frame.size.height = frame.size.width;
    
    CGPoint center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), frame.size.height / 2.0 + (SCREENHEIGHT  - 144 - 44 - frame.size.height) / 2.0 + 44);
    imageHWFactor = self.image.size.height / self.image.size.width;
    if(imageHWFactor <= 1) {
        frame.size.height = imageHWFactor * frame.size.width;
    }
    else {
        frame.size.width = frame.size.height / imageHWFactor;
    }
    imageScale = self.image.size.width / CGRectGetWidth(self.imageHolderView.frame);
    self.imageHolderView.frame = frame;
    self.imageHolderView.center = center;
    self.imageHolderView.image = self.image;
    self.imageHolderView.contentMode = UIViewContentModeScaleToFill;
    [self.imageHolderView setNeedsUpdateConstraints];
}
/**
 *根据当前裁剪区域的位置和尺寸将黑色蒙板的相应区域抠成透明
 */
- (void)resetCropMask {
    UIBezierPath *path = [UIBezierPath bezierPathWithRect: self.cropMaskView.bounds];
    UIBezierPath *clearPath = [[UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(self.cropView.frame) + CROPVIEWBORDERWIDTH, CGRectGetMinY(self.cropView.frame) + CROPVIEWBORDERWIDTH, CGRectGetWidth(self.cropView.frame) - 2 * CROPVIEWBORDERWIDTH, CGRectGetHeight(self.cropView.frame) - 2 * CROPVIEWBORDERWIDTH)] bezierPathByReversingPath];
    [path appendPath: clearPath];
    
    CAShapeLayer *shapeLayer = (CAShapeLayer *)self.cropMaskView.layer.mask;
    if(!shapeLayer) {
        shapeLayer = [CAShapeLayer layer];
        [self.cropMaskView.layer setMask: shapeLayer];
    }
    shapeLayer.path = path.CGPath;
}
/**
 *移动裁剪区域的手势处理
 */
- (IBAction)moveCropView:(UIPanGestureRecognizer *)panGesture {
    CGFloat minX = CGRectGetMinX(self.imageHolderView.frame);
    CGFloat maxX = CGRectGetMaxX(self.imageHolderView.frame) - CGRectGetWidth(self.cropView.frame);
    CGFloat minY = CGRectGetMinY(self.imageHolderView.frame);
    CGFloat maxY = CGRectGetMaxY(self.imageHolderView.frame) - CGRectGetHeight(self.cropView.frame);
    
    if(panGesture.state == UIGestureRecognizerStateBegan) {
        startPointCropView = [panGesture locationInView:self.cropMaskView];
        self.arrow1.userInteractionEnabled = NO;
        self.arrow2.userInteractionEnabled = NO;
        self.arrow3.userInteractionEnabled = NO;
        self.arrow4.userInteractionEnabled = NO;
    }
    else if(panGesture.state == UIGestureRecognizerStateEnded) {
        self.arrow1.userInteractionEnabled = YES;
        self.arrow2.userInteractionEnabled = YES;
        self.arrow3.userInteractionEnabled = YES;
        self.arrow4.userInteractionEnabled = YES;
    }
    else if(panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint endPoint = [panGesture locationInView:self.cropMaskView];
        CGRect frame = panGesture.view.frame;
        frame.origin.x += endPoint.x - startPointCropView.x;
        frame.origin.y += endPoint.y - startPointCropView.y;
        frame.origin.x = MIN(maxX, MAX(frame.origin.x, minX));
        frame.origin.y = MIN(maxY, MAX(frame.origin.y, minY));
        panGesture.view.frame = frame;
        startPointCropView = endPoint;
    }
    [self resetCropMask];
    [self resetAllArrows];
}
/**
 *移动四个箭头的手势处理
 */
- (IBAction)moveCorner:(UIPanGestureRecognizer *)panGesture {
    CGPoint *startPoint = NULL;
    CGFloat minX = CGRectGetMinX(self.imageHolderView.frame) - ARROWBORDERWIDTH;
    CGFloat maxX = CGRectGetMaxX(self.imageHolderView.frame) - ARROWWIDTH + ARROWBORDERWIDTH;
    CGFloat minY = CGRectGetMinY(self.imageHolderView.frame) - ARROWBORDERWIDTH;
    CGFloat maxY = CGRectGetMaxY(self.imageHolderView.frame) - ARROWHEIGHT + ARROWBORDERWIDTH;
    
    if(panGesture.view == self.arrow1) {
        startPoint = &startPoint1;
        maxY = CGRectGetMinY(self.arrow3.frame) - ARROWHEIGHT - ARROWMINIMUMSPACE;
        maxX = CGRectGetMinX(self.arrow2.frame) - ARROWWIDTH - ARROWMINIMUMSPACE;
    }
    else if(panGesture.view == self.arrow2) {
        startPoint = &startPoint2;
        maxY = CGRectGetMinY(self.arrow4.frame) - ARROWHEIGHT - ARROWMINIMUMSPACE;
        minX = CGRectGetMaxX(self.arrow1.frame) + ARROWMINIMUMSPACE;
    }
    else if(panGesture.view == self.arrow3) {
        startPoint = &startPoint3;
        minY = CGRectGetMaxY(self.arrow1.frame) + ARROWMINIMUMSPACE;
        maxX = CGRectGetMinX(self.arrow4.frame) - ARROWWIDTH - ARROWMINIMUMSPACE;
    }
    else if(panGesture.view == self.arrow4) {
        startPoint = &startPoint4;
        minY = CGRectGetMaxY(self.arrow2.frame) + ARROWMINIMUMSPACE;
        minX = CGRectGetMaxX(self.arrow3.frame) + ARROWMINIMUMSPACE;
    }
    
    if(panGesture.state == UIGestureRecognizerStateBegan) {
        *startPoint = [panGesture locationInView:self.cropMaskView];
        self.cropView.userInteractionEnabled = NO;
    }
    else if(panGesture.state == UIGestureRecognizerStateEnded) {
        self.cropView.userInteractionEnabled = YES;
    }
    else if(panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint endPoint = [panGesture locationInView:self.cropMaskView];
        CGRect frame = panGesture.view.frame;
        frame.origin.x += endPoint.x - startPoint->x;
        frame.origin.y += endPoint.y - startPoint->y;
        frame.origin.x = MIN(maxX, MAX(frame.origin.x, minX));
        frame.origin.y = MIN(maxY, MAX(frame.origin.y, minY));
        panGesture.view.frame = frame;
        *startPoint = endPoint;
    }
    [self resetArrowsFollow: panGesture.view];
    [self resetCropView];
    [self resetCropMask];
}
/**
 *根据当前移动的箭头的位置重新设置与之一起变化位置的箭头的位置
 */
- (void)resetArrowsFollow: (UIView *)arrow {
    CGFloat borderMinX = CGRectGetMinX(self.imageHolderView.frame);
    CGFloat borderMaxX = CGRectGetMaxX(self.imageHolderView.frame);
    CGFloat borderMinY = CGRectGetMinY(self.imageHolderView.frame);
    CGFloat borderMaxY = CGRectGetMaxY(self.imageHolderView.frame);
    if(arrow == self.arrow1) {
        
        if(currentProportion == 0) {
            self.arrow2.center = CGPointMake(self.arrow2.center.x, self.arrow1.center.y);
            self.arrow3.center = CGPointMake(self.arrow1.center.x, self.arrow3.center.y);
            return;
        }
        
        CGPoint leftTopPoint = CGPointMake(CGRectGetMinX(self.arrow1.frame) + ARROWBORDERWIDTH, CGRectGetMinY(self.arrow1.frame) + ARROWBORDERWIDTH);
        CGRect frame = self.cropView.frame;
        CGFloat maxX = CGRectGetMaxX(frame);
        CGFloat maxY = CGRectGetMaxY(frame);
        
        if(currentProportion >= 1) {
            frame.size.height = MIN(MAX(maxX - leftTopPoint.x, 2 * ARROWWIDTH + ARROWMINIMUMSPACE) * currentProportion, maxY - borderMinY);
            frame.size.width = frame.size.height / currentProportion;
        }
        else {
            frame.size.width = MIN(MAX(maxY - leftTopPoint.y, 2 * ARROWHEIGHT + ARROWMINIMUMSPACE) / currentProportion, maxX - borderMinX);
            frame.size.height = frame.size.width * currentProportion;
        }
        frame.origin.x = maxX - frame.size.width;
        frame.origin.y = maxY - frame.size.height;
        self.cropView.frame = frame;
        
        [self resetAllArrows];
    }
    else if(arrow == self.arrow2) {
        
        if(currentProportion == 0) {
            self.arrow1.center = CGPointMake(self.arrow1.center.x, self.arrow2.center.y);
            self.arrow4.center = CGPointMake(self.arrow2.center.x, self.arrow4.center.y);
            return;
        }
        
        CGPoint rightTopPoint = CGPointMake(CGRectGetMaxX(self.arrow2.frame) - ARROWBORDERWIDTH, CGRectGetMinY(self.arrow2.frame) + ARROWBORDERWIDTH);
        CGRect frame = self.cropView.frame;
        CGFloat minX = CGRectGetMinX(frame);
        CGFloat maxY = CGRectGetMaxY(frame);
        
        if(currentProportion >= 1) {
            frame.size.height = MIN(MAX(rightTopPoint.x - minX, 2 * ARROWWIDTH + ARROWMINIMUMSPACE) * currentProportion, maxY - borderMinY);
            frame.size.width = frame.size.height / currentProportion;
        }
        else {
            frame.size.width = MIN(MAX(maxY - rightTopPoint.y, 2 * ARROWHEIGHT + ARROWMINIMUMSPACE) / currentProportion,  borderMaxX - minX);
            frame.size.height = frame.size.width * currentProportion;
        }

        frame.origin.y = maxY - frame.size.height;
        self.cropView.frame = frame;
        
        [self resetAllArrows];
    }
    else if(arrow == self.arrow3) {
        
        if(currentProportion == 0) {
            self.arrow1.center = CGPointMake(self.arrow3.center.x, self.arrow1.center.y);
            self.arrow4.center = CGPointMake(self.arrow4.center.x, self.arrow3.center.y);
            return;
        }
        
        CGPoint leftBottomPoint = CGPointMake(CGRectGetMinX(self.arrow3.frame) + ARROWBORDERWIDTH, CGRectGetMaxY(self.arrow3.frame) - ARROWBORDERWIDTH);
        CGRect frame = self.cropView.frame;
        CGFloat maxX = CGRectGetMaxX(frame);
        CGFloat minY = CGRectGetMinY(frame);
        
        if(currentProportion >= 1) {
            frame.size.height = MIN(MAX(maxX - leftBottomPoint.x, 2 * ARROWWIDTH + ARROWMINIMUMSPACE) * currentProportion, borderMaxY - minY);
            frame.size.width = frame.size.height / currentProportion;
        }
        else {
            frame.size.width = MIN(MAX(leftBottomPoint.y - minY, 2 * ARROWHEIGHT + ARROWMINIMUMSPACE) / currentProportion, maxX - borderMinX);
            frame.size.height = frame.size.width * currentProportion;
        }
        
        frame.origin.x = maxX - frame.size.width;
        self.cropView.frame = frame;
        
        [self resetAllArrows];
    }
    else if(arrow == self.arrow4) {
        
        if(currentProportion == 0) {
            self.arrow2.center = CGPointMake(self.arrow4.center.x, self.arrow2.center.y);
            self.arrow3.center = CGPointMake(self.arrow3.center.x, self.arrow4.center.y);
            return;
        }
        
        CGPoint rightBottomPoint = CGPointMake(CGRectGetMaxX(self.arrow4.frame) - ARROWBORDERWIDTH, CGRectGetMaxY(self.arrow4.frame) - ARROWBORDERWIDTH);
        CGRect frame = self.cropView.frame;
        CGFloat minX = CGRectGetMinX(frame);
        CGFloat minY = CGRectGetMinY(frame);
        
        if(currentProportion >= 1) {
            frame.size.height = MIN(MAX(rightBottomPoint.x - minX, 2 * ARROWWIDTH + ARROWMINIMUMSPACE) * currentProportion, borderMaxY - minY);
            frame.size.width = frame.size.height / currentProportion;

        }
        else {
            frame.size.width = MIN(MAX(rightBottomPoint.y - minY, 2 * ARROWHEIGHT + ARROWMINIMUMSPACE) / currentProportion, borderMaxX - minX);
            frame.size.height = frame.size.width * currentProportion;
        }
        self.cropView.frame = frame;
        
        [self resetAllArrows];
    }
}
/**
 *根据当前裁剪区域的位置重新设置所有角的位置
 */
- (void)resetAllArrows {
    self.arrow1.center = CGPointMake(CGRectGetMinX(self.cropView.frame) - ARROWBORDERWIDTH + ARROWWIDTH/2.0, CGRectGetMinY(self.cropView.frame) - ARROWBORDERWIDTH + ARROWHEIGHT/2.0);
    self.arrow2.center = CGPointMake(CGRectGetMaxX(self.cropView.frame) + ARROWBORDERWIDTH - ARROWWIDTH/2.0, CGRectGetMinY(self.cropView.frame) - ARROWBORDERWIDTH + ARROWHEIGHT/2.0);
    self.arrow3.center = CGPointMake(CGRectGetMinX(self.cropView.frame) - ARROWBORDERWIDTH + ARROWWIDTH/2.0, CGRectGetMaxY(self.cropView.frame) + ARROWBORDERWIDTH - ARROWHEIGHT/2.0);
    self.arrow4.center = CGPointMake(CGRectGetMaxX(self.cropView.frame) + ARROWBORDERWIDTH - ARROWWIDTH/2.0, CGRectGetMaxY(self.cropView.frame) + ARROWBORDERWIDTH - ARROWHEIGHT/2.0);
    [self.view layoutIfNeeded];
}
/**
 *根据当前所有角的位置重新设置裁剪区域的位置
 */
- (void)resetCropView {
    self.cropView.frame = CGRectMake(CGRectGetMinX(self.arrow1.frame) + ARROWBORDERWIDTH, CGRectGetMinY(self.arrow1.frame) + ARROWBORDERWIDTH, CGRectGetMaxX(self.arrow2.frame) - CGRectGetMinX(self.arrow1.frame) - ARROWBORDERWIDTH * 2, CGRectGetMaxY(self.arrow3.frame) - CGRectGetMinY(self.arrow1.frame) - ARROWBORDERWIDTH * 2);
}
/**
 *由于image在imageview中是缩放过的，这里要根据裁剪区域在imageview的尺寸换算
 *出对应的裁剪区域在实际image的尺寸
 */
- (CGRect)cropAreaInImage {
    CGRect cropAreaInImageView = [self.cropMaskView convertRect:self.cropView.frame toView:self.imageHolderView];
    CGRect cropAreaInImage;
    cropAreaInImage.origin.x = cropAreaInImageView.origin.x * imageScale;
    cropAreaInImage.origin.y = cropAreaInImageView.origin.y * imageScale;
    cropAreaInImage.size.width = cropAreaInImageView.size.width * imageScale;
    cropAreaInImage.size.height = cropAreaInImageView.size.height * imageScale;
    return cropAreaInImage;
}
/**
 *设置裁剪尺寸的视图
 */
- (void)setUpCropProportionView {
    proportionBtnArr = [NSMutableArray array];
    proportionImageNameArr = @[@"crop_free", @"crop_1_1", @"crop_4_3", @"crop_3_4", @"crop_16_9", @"crop_9_16"];
    proportionImageNameHLArr = @[@"cropHL_free", @"cropHL_1_1", @"cropHL_4_3", @"cropHL_3_4", @"cropHL_16_9", @"cropHL_9_16"];
    proportionArr = @[@0, @1, @(3.0/4.0), @(4.0/3.0), @(9.0/16.0), @(16.0/9.0)];
    self.cropProportionScrollView.contentSize = CGSizeMake( CROPPROPORTIONIMAGEPADDING * 2 + CROPPROPORTIONIMAGEWIDTH * proportionArr.count + CROPPROPORTIONIMAGESPACE * (proportionArr.count - 1), CROPPROPORTIONIMAGEWIDTH);
    for(int i = 0; i < proportionArr.count; i++) {
        UIButton *proportionBtn = [[UIButton alloc]initWithFrame: CGRectMake(CROPPROPORTIONIMAGEPADDING + (CROPPROPORTIONIMAGESPACE + CROPPROPORTIONIMAGEWIDTH) * i, 0, CROPPROPORTIONIMAGEWIDTH, CROPPROPORTIONIMAGEWIDTH)];
        [proportionBtn setBackgroundImage:
         [UIImage imageNamed: proportionImageNameArr[i]]
                                 forState: UIControlStateNormal];
        [proportionBtn setBackgroundImage:
         [UIImage imageNamed: proportionImageNameHLArr[i]]
                                 forState: UIControlStateSelected];
        [proportionBtn addTarget:self action:@selector(clickProportionBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.cropProportionScrollView addSubview:proportionBtn];
        [proportionBtnArr addObject:proportionBtn];
    }
}
- (void)clickProportionBtn: (UIButton *)proportionBtn {
    for(UIButton *btn in proportionBtnArr) {
        btn.selected = NO;
    }
    proportionBtn.selected = YES;
    NSInteger index = [proportionBtnArr indexOfObject:proportionBtn];
    currentProportion = [proportionArr[index] floatValue];
    CGFloat cropViewWidth;
    CGFloat cropViewHeight;
    if(currentProportion == 0) {
        self.cropView.frame = self.imageHolderView.frame;
    }
    else if(currentProportion < 1) {
        cropViewWidth = CGRectGetWidth(self.imageHolderView.frame);
        cropViewHeight = MIN(cropViewWidth * currentProportion, CGRectGetHeight(self.imageHolderView.frame));
        cropViewWidth = cropViewHeight / currentProportion;
        self.cropView.frame = CGRectMake(0, 0, cropViewWidth, cropViewHeight);
    }
    else if(currentProportion == 1) {
        cropViewWidth = MIN(CGRectGetWidth(self.imageHolderView.frame), CGRectGetHeight(self.imageHolderView.frame));
        self.cropView.frame = CGRectMake(0, 0, cropViewWidth, cropViewWidth);
    }
    else {
        cropViewHeight = CGRectGetHeight(self.imageHolderView.frame);
        cropViewWidth = MIN(cropViewHeight / currentProportion, CGRectGetWidth(self.imageHolderView.frame));
        cropViewHeight = cropViewWidth * currentProportion;
        self.cropView.frame = CGRectMake(0, 0, cropViewWidth, cropViewHeight);
    }
    self.cropView.center = self.imageHolderView.center;
    self.cropView.layer.borderWidth = CROPVIEWBORDERWIDTH;
    self.cropView.layer.borderColor = [UIColor whiteColor].CGColor;
    [self resetAllArrows];
    [self resetCropMask];
}

#pragma mark - IBActions
- (IBAction)clickCancelBtn:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (IBAction)clickOkBtn:(id)sender {
    UIImage *cropImage = [self.image imageAtRect:[self cropAreaInImage]];
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CropOK" object: cropImage];
    }];
}
@end
