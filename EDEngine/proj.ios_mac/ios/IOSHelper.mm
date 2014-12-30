#import "IOSHelper.h"
//#import "EAGLView.h"
#import "cocos2d.h"
#import "Platform.h"
#import "Files.h"
#import "CCEAGLView.h"
#import "CCGLView.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioQueue.h>
#import <AudioToolbox/AudioFile.h>
#import <AudioToolbox/AudioToolbox.h>

#define	RETURN_TYPE_TAKEPICTURE		1
#define	RETURN_TYPE_PICKPICTURE		2

#define	RETURN_TYPE_TAKEPICTUREDIB	3
#define	RETURN_TYPE_PICKPICTUREDIB	4

#define RETURN_TYPE_RECORDDATA      10

@interface IOSHelperView : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
}
@end

static IOSHelperView *s_pHelperView=NULL;
static UIPopoverController *popoverController=NULL;

@implementation IOSHelperView

-(void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

void OnIOSReturnBuf(int nType,int nID,int nParam1,int nParam2,int lenBuf,char *pBuf);
void OnIOSReturn(int nType,int nID,int nParam1,int nParam2);
char *AdjustRawBufOrientation(char *pSrcBuf,int *pWidth,int *pHeight,int nAngle,bool bMirror);

static int s_nCurID=1;
static int s_nBufType;
static int s_nBufID;
static int s_ResourceType = TAKE_PICTURE;

static void SendToLua(std::string resource,int typeCode,int resultCode)
{
    takeResource_callback(resource,typeCode,resultCode);
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* pImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

    CGImageRef ref=pImage.CGImage;
    int w=CGImageGetWidth(ref);
    int h=CGImageGetHeight(ref);

    CGDataProviderRef dataProvider=CGImageGetDataProvider(ref);
    CFDataRef data=CGDataProviderCopyData(dataProvider);
    UInt8 *pBuf=(UInt8 *)CFDataGetBytePtr(data);
 
    int len=w*h*4;
    int nOrientation=pImage.imageOrientation;
    int nAngle;
    bool bMirror;
    switch (nOrientation)
    {
        case UIImageOrientationUp:
            nAngle=0;
            bMirror=false;
            break;
        case UIImageOrientationRight:
            nAngle=90;
            bMirror=false;
            break;
        case UIImageOrientationDown:
            nAngle=180;
            bMirror=false;
            break;
        case UIImageOrientationLeft:
            nAngle=270;
            bMirror=false;
            break;
        case UIImageOrientationUpMirrored:
            nAngle=0;
            bMirror=true;
            break;
        case UIImageOrientationRightMirrored:
            nAngle=0;
            bMirror=true;
            break;
        case UIImageOrientationDownMirrored:
            nAngle=0;
            bMirror=true;
            break;
        case UIImageOrientationLeftMirrored:
            nAngle=0;
            bMirror=true;
            break;
    }
    char *pNewBuf=AdjustRawBufOrientation((char *)pBuf,&w,&h,nAngle,bMirror);
    if (pNewBuf!=NULL)
    {
        pBuf=(UInt8 *)pNewBuf;
    }
    /*
        将数据保存为jpg
     */
    {
        std::string tmp = allocTmpFile(".jpg");
        cocos2d::Image *pimg = new cocos2d::Image();
        if (pimg && pBuf )
        {
            /*
             //调整rgba mode
            for (int y = 0; y < h; ++y)
            {
                unsigned char * pline = (unsigned char*)pNewBuf + y*w * 4;
                for (int x = 0; x < w; ++x)
                {
                    unsigned char *pc = pline + x * 4;
                    unsigned char tmp;
                    tmp = pc[0];
                    pc[0] = pc[1];
                    pc[1] = tmp;
                }
            }
             */
            pimg->initWithRawData((unsigned char*)pBuf, w * 4 * h, w, h, 8);
            pimg->saveToFile(tmp);
            pimg->release();
            SendToLua(tmp,s_ResourceType,RESULT_OK);
        }
        else
        {
            CCLOG("imagePickerController new cocos2d::Image return null!");
            SendToLua("imagePickerController pBuf == nullptr or pimg == nullptr",s_ResourceType,RESULT_ERROR);
        }
        
    }
    //OnIOSReturnBuf(s_nBufType,s_nBufID,w,h,len,(char *)pBuf);
    if (pNewBuf!=NULL) free(pNewBuf);

    [picker.view removeFromSuperview];
    [picker release];
    
    if (popoverController!=NULL)
    {
        [popoverController dismissPopoverAnimated:YES];
    }

 //   [self dismissModalViewControllerAnimated:YES];

    [s_pHelperView.view removeFromSuperview];
 //   [s_pHelperView.view.superview removeFromSuperview];
    [s_pHelperView release];
    s_pHelperView=NULL;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.view removeFromSuperview];
    [picker release];
    
    if (popoverController!=NULL)
    {
        [popoverController dismissPopoverAnimated:YES];
    }
    
    [s_pHelperView.view removeFromSuperview];
    [s_pHelperView release];
    s_pHelperView=NULL;

    /*
    [self dismissModalViewControllerAnimated:YES];
    
    [s_pHelperView.view removeFromSuperview];
    [s_pHelperView.view.superview removeFromSuperview];
     */
    
    SendToLua("",s_ResourceType,RESULT_CANCEL);
//    OnIOSReturn(RETURN_TYPE_TAKEPICTUREDIB,s_nBufID,0,0);
}

-(int)PickPicture
{
    float fVersion=[[UIDevice currentDevice].systemVersion floatValue];
    
    UIImagePickerController *picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.allowsEditing=NO;
    
    if (popoverController!=NULL)
    {
        [popoverController release];
        popoverController=NULL;
    }

    if (fVersion>=7.0f || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        picker.view.frame=self.view.frame;
        [self.view addSubview:picker.view];
    }
    else
    {
        popoverController = [[UIPopoverController alloc] initWithContentViewController:picker];
        [popoverController presentPopoverFromRect:CGRectMake(0, 0, 300, 300) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
//    [self presentModalViewController: picker animated: YES];
//    [picker release];
    s_nBufType=RETURN_TYPE_PICKPICTUREDIB;
    s_nBufID=s_nCurID++;
    s_ResourceType = PICK_PICTURE;
    return s_nBufID;
}

-(int)TakePicture
{
	UIImagePickerController* picker = [[UIImagePickerController alloc]init];
    picker.delegate = self;
    picker.view.frame=self.view.frame;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing=NO;
    [self.view addSubview:picker.view];
   // [self presentModalViewController: picker animated: YES];
   // [picker release];
    s_nBufType=RETURN_TYPE_PICKPICTUREDIB;
    s_nBufID=s_nCurID++;
    s_ResourceType = TAKE_PICTURE;
    return s_nBufID;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end

bool InitIOSHelper()
{
    if (s_pHelperView!=NULL) return true;
    cocos2d::Director *pDirector = cocos2d::Director::getInstance();

    CCEAGLView *pOpenGLView = (CCEAGLView *)pDirector->getOpenGLView()->getEAGLView();
    
   //for cocos2d-x 2.2
   // static EAGLView *pOpenGLView=[EAGLView sharedEGLView];
    
    if (pOpenGLView==nil) return false;
    
    s_pHelperView=[[IOSHelperView alloc] initWithNibName:nil bundle:nil];
    s_pHelperView.wantsFullScreenLayout=NO;
    //s_pHelperView=[[[IOSHelperView alloc] initWithFrame:[[UIScreen mainScreen]bounds]];
    s_pHelperView.view.frame=pOpenGLView.frame;

    [pOpenGLView addSubview:s_pHelperView.view];
    
    return true;
}

void setMutiTouchEnabled( bool b )
{
    cocos2d::Director *pDirector = cocos2d::Director::getInstance();
    CCEAGLView *pOpenGLView = (CCEAGLView *)pDirector->getOpenGLView()->getEAGLView();
    if( pOpenGLView )
    {
        [pOpenGLView setMultipleTouchEnabled:YES];
        UIWindow* window = [UIApplication sharedApplication].windows[0];
        if( window )
        {
            [window setMultipleTouchEnabled:YES];
        }
    }
}
//	return:
//	<0		error
//	0		abort
//	>0		ok, wait buf id
int PickPicture()
{
    if (!InitIOSHelper()) return 0;
    
    return [s_pHelperView PickPicture];
}

//	return:
//	<0		error
//	0		abort
//	>0		ok, wait buf id
int TakePhoto()
{
    if (!InitIOSHelper()) return 0;
    
    return [s_pHelperView TakePicture];
}

int SavePictureToSystemFolder(const char *pszPathName,char *pszPrompt)
{
    NSString *str=[NSString stringWithUTF8String:pszPathName];
    UIImage *image=[[UIImage alloc]initWithContentsOfFile:str];
    if (image==NULL)
    {
        strcpy(pszPrompt,"@savepicturetophotoalbumfailed");
        return 0;
    }
    
    UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
    [image release];
    strcpy(pszPrompt,"@savepicturetophotoalbumsuccessed");
    return 1;
}

#define RECORD_BUF_COUNT    3

typedef struct
{
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         buffers[RECORD_BUF_COUNT];
    UInt32                      bufferByteSize;
    bool                        runing;
    bool                        stopped;
}AudioState;

static AudioState *s_pRecordState=NULL;

static bool IOS_IsLittleEndian()
{
	int nTest=0x12345678;
	return (*(char *)&nTest)==0x78;
}

static void DeriveBufferSize (AudioQueueRef audioQueue, AudioStreamBasicDescription ASBDescription, Float64 seconds, UInt32 *outBufferSize)
{
    static const int maxBufferSize = 0x50000; // punting with 50k
    Float64 numBytesForTime = ASBDescription.mSampleRate * ASBDescription.mBytesPerPacket * seconds;
    *outBufferSize =  (UInt32)((numBytesForTime < maxBufferSize) ? numBytesForTime : maxBufferSize);
}

static void HandleInputBuffer (void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime,
							   UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc)
{
    AudioState *pRecordState = (AudioState *)aqData;
    OnIOSReturnBuf(RETURN_TYPE_RECORDDATA,0,(int)pRecordState->dataFormat.mSampleRate,0,inBuffer->mAudioDataByteSize,(char *)inBuffer->mAudioData);

    if (!pRecordState->runing) return;
    
    AudioQueueEnqueueBuffer(pRecordState->queue, inBuffer, 0, NULL);
}

bool IOS_VoiceStartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
    if (s_pRecordState==NULL)
    {
        s_pRecordState=new AudioState;
        if (s_pRecordState==NULL) return false;
        
        s_pRecordState->runing = false;
        s_pRecordState->stopped=true;
    }
    else
    {
        if (!IOS_VoiceStopRecord()) return false;
    }
    s_pRecordState->dataFormat.mSampleRate=nRate;
    s_pRecordState->dataFormat.mFormatID = kAudioFormatLinearPCM;
    s_pRecordState->dataFormat.mFormatFlags = (IOS_IsLittleEndian() ? 0 : kLinearPCMFormatFlagIsBigEndian) |  kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    s_pRecordState->dataFormat.mChannelsPerFrame = cnChannel;
    s_pRecordState->dataFormat.mBitsPerChannel = cnBitPerSample;
    s_pRecordState->dataFormat.mFramesPerPacket = 1;
    s_pRecordState->dataFormat.mBytesPerPacket = cnBitPerSample/8*cnChannel;
    s_pRecordState->dataFormat.mBytesPerFrame = cnBitPerSample/8*cnChannel;
    s_pRecordState->dataFormat.mReserved = 0;
    
    OSStatus status;
    status = AudioQueueNewInput(&s_pRecordState->dataFormat, HandleInputBuffer, s_pRecordState, CFRunLoopGetCurrent(),kCFRunLoopCommonModes, 0, &s_pRecordState->queue);
    if (status) return false;

    DeriveBufferSize(s_pRecordState->queue, s_pRecordState->dataFormat, 0.1f, &s_pRecordState->bufferByteSize);

    for (int i = 0; i < RECORD_BUF_COUNT; i++)
    {
        status = AudioQueueAllocateBuffer(s_pRecordState->queue, s_pRecordState->bufferByteSize, &s_pRecordState->buffers[i]);
        if (status) return false;
        status = AudioQueueEnqueueBuffer(s_pRecordState->queue, s_pRecordState->buffers[i], 0, NULL);
        if (status) return false;
    }

//    AudioSessionInitialize(NULL,
//                           NULL,
//                           nil,
//                           NULL
//                           );
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(sessionCategory),
                            &sessionCategory
                            );
    AudioSessionSetActive(true);
    
    status = AudioQueueStart(s_pRecordState->queue, NULL);
    if (status) return false;
    s_pRecordState->runing = true;
    s_pRecordState->stopped=false;
    return true;
}

bool IOS_VoiceStopRecord()
{
    if (s_pRecordState==NULL || s_pRecordState->stopped) return true;
    
    AudioQueueFlush(s_pRecordState->queue);
    AudioQueueStop(s_pRecordState->queue, NO);
    s_pRecordState->runing = false;
    
    for (int i = 0; i < RECORD_BUF_COUNT; i++) AudioQueueFreeBuffer(s_pRecordState->queue, s_pRecordState->buffers[i]);
    
    AudioQueueDispose(s_pRecordState->queue, YES);
    s_pRecordState->stopped=true;
    return true;
}

static AudioState *s_pPlayState=NULL;

static void HandleOutputBuffer(void *aqData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer)
{
    IOS_VoiceStopPlay();
}

bool IOS_VoiceStartPlay(char *pBuf,int lenBuf)
{
    if (s_pPlayState==NULL)
    {
        s_pPlayState=new AudioState;
        if (s_pPlayState==NULL) return false;
        
        s_pPlayState->runing = false;
        s_pPlayState->stopped=true;
    }
    else
    {
        if (!IOS_VoiceStopPlay()) return false;
    }
    s_pPlayState->dataFormat.mSampleRate=8000;
    s_pPlayState->dataFormat.mFormatID = kAudioFormatLinearPCM;
    s_pPlayState->dataFormat.mFormatFlags = (IOS_IsLittleEndian() ? 0 : kLinearPCMFormatFlagIsBigEndian) |  kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    s_pPlayState->dataFormat.mChannelsPerFrame = 1;
    s_pPlayState->dataFormat.mBitsPerChannel = 16;
    s_pPlayState->dataFormat.mFramesPerPacket = 1;
    s_pPlayState->dataFormat.mBytesPerPacket = 16/8*1;
    s_pPlayState->dataFormat.mBytesPerFrame = 16/8*1;
    s_pPlayState->dataFormat.mReserved = 0;
    
    OSStatus status;
    status=AudioQueueNewOutput(&s_pPlayState->dataFormat, HandleOutputBuffer, s_pPlayState, CFRunLoopGetCurrent(),kCFRunLoopCommonModes, 0, &s_pPlayState->queue);
    if (status) return false;
    
    s_pPlayState->bufferByteSize=lenBuf;
    status = AudioQueueAllocateBuffer(s_pPlayState->queue, lenBuf, &s_pPlayState->buffers[0]);
    if (status) return false;
    memmove(s_pPlayState->buffers[0]->mAudioData,pBuf,lenBuf);
    s_pPlayState->buffers[0]->mAudioDataByteSize=lenBuf;
    
    status = AudioQueueEnqueueBuffer(s_pPlayState->queue, s_pPlayState->buffers[0], 0, NULL);
    if (status) return false;

    status = AudioQueueStart(s_pPlayState->queue, NULL);
    if (status) return false;

    s_pPlayState->runing = true;
    s_pPlayState->stopped=false;
    return true;
}

bool IOS_VoiceIsPlaying()
{
    if (s_pPlayState==NULL) return false;
    return s_pPlayState->runing;
}

bool IOS_VoiceStopPlay()
{
    if (s_pPlayState==NULL || s_pPlayState->stopped) return true;

    AudioQueueDispose(s_pPlayState->queue,true);
    s_pPlayState->runing=false;
    s_pPlayState->stopped=true;
    return true;
}

bool IOS_DoVibrator()
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    return true;
}

bool IOS_CheckDevice(NSString *name)
{
    NSString *deviceType=[UIDevice currentDevice].model;
    NSRange range=[deviceType rangeOfString:name];
    return range.location!=NSNotFound;
}

bool IOS_IsIPhone()
{
    return IOS_CheckDevice(@"iPhone");
}

bool IOS_IsIPad()
{
    return IOS_CheckDevice(@"iPad");
}

bool IOS_CopyToClipboard(const char *pszText)
{
    NSString *str=[NSString stringWithUTF8String:pszText];
    
    UIPasteboard *pClipBoard=[UIPasteboard generalPasteboard];
    [pClipBoard setString:str];
    return true;
}

std::string IOS_CopyFromClipboard()
{
    std::string strRet = [[[UIPasteboard generalPasteboard] string] UTF8String];
    return strRet;
}

bool IOS_IsPackageExist(const char *pszURL)
{
    NSString *str=[NSString stringWithUTF8String:pszURL];
    NSURL *url=[NSURL URLWithString:str];
    return [[UIApplication sharedApplication] canOpenURL:url];
}

bool IOS_StartApp(const char *pszURL)
{
    NSString *str=[NSString stringWithUTF8String:pszURL];
    NSURL *url=[NSURL URLWithString:str];
    return [[UIApplication sharedApplication] openURL:url];
}

bool OpenURL(const char *pszURL)
{
    NSString *str=[NSString stringWithUTF8String:pszURL];
    NSURL *url=[NSURL URLWithString:str];
    return [[UIApplication sharedApplication] openURL:url];
}
