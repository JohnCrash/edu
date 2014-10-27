/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2011      Zynga Inc.
Copyright (c) 2013-2014 Chukong Technologies Inc.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package org.cocos2dx.cpp;

import java.security.Provider;

import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.provider.MediaStore;

import java.io.File;
import java.lang.System;

import android.net.Uri;
import android.app.Activity;
import android.app.AlertDialog;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.cocos2dx.lib.Cocos2dxHelper;
import android.graphics.Bitmap;
import android.os.Build;
import android.database.Cursor;

import android.media.MediaPlayer;
import android.media.MediaPlayer.OnCompletionListener;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;

//import org.cocos2dx.cpp.CrashHandler;

public class AppActivity extends Cocos2dxActivity {
	//======================
	// JNI
	//======================
	private static native void launchParam(final String launch,final String cookie,final String uid);
	private static native void setExternalStorageDirectory(final String sd);
	private static native void sendTakeResourceResult(int resultCode,int typeCode,final String res); 
	private static native void sendVoiceRecordData(final int nType,final int nID,final int nParam1,final int nParam2,final int len,final byte[] pBytes);
	//======================
	// ���պ�ȡͼ��
	//======================
	private static final int RETURN_TYPE_RECORDDATA = 10;
	private static final int TAKE_PICTURE = 1;
	private static final int PICK_PICTURE = 2;
	private static AppActivity myActivity;
	private static String _resourceName;
	public static void takeResource(int from)
	{
		if( from == 1 )
		{
			String storageState = Environment.getExternalStorageState();
			if(storageState.equals(Environment.MEDIA_MOUNTED) )
			{
				Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
				long ct = System.currentTimeMillis();
				_resourceName = Environment.getExternalStorageDirectory().getPath() + File.separatorChar + "ljdata/EDEngine/" + ct + ".jpg";
				File file = new File(_resourceName);
				Uri fileUri = Uri.fromFile(file);
				intent.putExtra( MediaStore.EXTRA_OUTPUT, fileUri);
				intent.putExtra("outputFormat", Bitmap.CompressFormat.JPEG.toString());
				myActivity.startActivityForResult(intent,TAKE_PICTURE);
			}
			else
			{
				new AlertDialog.Builder(myActivity)
	            .setMessage("External Storeage (SD Card) is required.\n\nCurrent state: " + storageState)
	            .setCancelable(true).create().show();			
			}
		}else if(from==2)
		{
			Intent intent=new Intent();
			if (Build.VERSION.SDK_INT<19)
			{
				intent.setAction(Intent.ACTION_GET_CONTENT);
				intent.setType("image/*");
			}
			else
			{
				intent.setAction(Intent.ACTION_PICK);
				intent.setData(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
			}
			myActivity.startActivityForResult(intent,PICK_PICTURE);			
		}else if(from==3)
		{
			//record audio
		}
	}
@Override
	public void onActivityResult(int requestCode,int resultCode,Intent data)
	{
		if(requestCode == TAKE_PICTURE || requestCode == PICK_PICTURE )
		{
			if( requestCode==PICK_PICTURE )
			{
				try
				{
					Uri uri = data.getData();
					Cursor cursor = getContentResolver().query(uri, new String[]{"_data"}, null, null, null);
					String strPathName;
					strPathName=uri.getPath();
					if (cursor==null)
					{
						resultCode = 0; //cancel
					}
					else
					{
						cursor.moveToFirst();
						strPathName=cursor.getString(0);
					}
					sendTakeResourceResult(requestCode,resultCode,strPathName);
					return;
				}
				catch(Exception e)
				{
				}
			}
			sendTakeResourceResult( requestCode,resultCode,_resourceName);
			return;
		}
		super.onActivityResult(requestCode, resultCode, data);
	}
	//======================
	//¼��
	//======================
	private static Thread s_thread;
	private static boolean s_bRecording=false;
	private static int s_nRecordState=0;
	
	private static int s_cnChannel;
	private static int s_nRate;
	private static int s_cnBitPerSample;
	
	private static int[] s_rateList={8000,11025,16000,22050,44100};
	private static int s_validRate=0;
	
	public static void RecordThreadFunc()
	{
		//ת��Ϊandroidʶ��ֵ
		int nChannel=s_cnChannel==1 ? AudioFormat.CHANNEL_CONFIGURATION_MONO : AudioFormat.CHANNEL_IN_STEREO;
		int audioEncoding=s_cnBitPerSample==8 ? AudioFormat.ENCODING_PCM_8BIT : AudioFormat.ENCODING_PCM_16BIT;
	
	    if (s_validRate==0)
	    {
	    	for (int i=0;i<5;i++)
	    	{
	    		int nRateThis=s_rateList[i];
	    		int minSize=AudioRecord.getMinBufferSize(nRateThis,nChannel,audioEncoding)*5;
	    		if (minSize<0) continue;
	    		
	    		AudioRecord audioRecord=new AudioRecord(MediaRecorder.AudioSource.MIC,nRateThis,nChannel,audioEncoding,minSize);
	    		if (audioRecord.getState() == AudioRecord.STATE_INITIALIZED)
	    		{
	    			Log.w("AudioRecord","valid rate test successed");
	    			audioRecord.stop();
	    			audioRecord.release();
	    			s_validRate=nRateThis;
	    			break;
	    		}
				audioRecord.stop();
				audioRecord.release();
	    	}
	        if (s_validRate==0)
	    	{
				//�������
				s_nRecordState=-1;
				s_bRecording=false;
				return;
	    	}
	        s_nRate=s_validRate;
	    }
	    int bufferSize=AudioRecord.getMinBufferSize(s_nRate,nChannel,audioEncoding)*2;
	    AudioRecord audioRecord=new AudioRecord(MediaRecorder.AudioSource.MIC,s_nRate,nChannel,audioEncoding,bufferSize);
	    if (audioRecord.getState() != AudioRecord.STATE_INITIALIZED)
	    {
			Log.w("AudioRecord","init fail");
			//�������
			audioRecord.stop();
			audioRecord.release();
			s_nRecordState=-1;
			s_bRecording=false;
			return;
	    }
	      
	    final byte[] buffer=new byte[bufferSize];
	    //��ʼ¼��
	    audioRecord.startRecording();
	
		while (s_bRecording)
		{
			//��������������𣿷������û�����ݻ����ѭ����������ܻ��������ֵ�������絥������8bit
			int bufferReadResult=audioRecord.read(buffer,0,bufferSize);
	
			if (bufferReadResult<0)
			{
				//ֹͣ¼��
				audioRecord.stop();
				audioRecord.release();
				s_nRecordState=-2;
				s_bRecording=false;
				return;
			}
			myActivity.sendVoiceRecordData(RETURN_TYPE_RECORDDATA,0,s_nRate,0,bufferReadResult,buffer);
			//Cocos2dxHelper.SendJavaReturnBufDirectly(RETURN_TYPE_RECORDDATA,0,s_nRate,0,bufferReadResult,buffer);
		}
		//ֹͣ¼��
		audioRecord.stop();
		audioRecord.release();
	
		//�Ѿ���¼���ˣ���������
		s_nRecordState=1;
		s_bRecording=false;
		return;
	}
	/*
	public static int CheckRecordPrivilege()
	{
		StringBuffer appNameAndPermissions=new StringBuffer();
		PackageManager pm=getContext().getPackageManager();
		List<ApplicationInfo> packages=pm.getInstalledApplications(PackageManager.GET_META_DATA);
	
		for (ApplicationInfo applicationInfo : packages)
		{
			try
			{
				PackageInfo packageInfo = pm.getPackageInfo("com.lj.ljshell", PackageManager.GET_PERMISSIONS);
				appNameAndPermissions.append(packageInfo.packageName+"*:\n");
	
				//Get Permissions
				String[] requestedPermissions = packageInfo.requestedPermissions;
				if (requestedPermissions != null)
				{
					for (int i = 0; i < requestedPermissions.length; i++)
					{
						Log.d("test", requestedPermissions[i]);
						appNameAndPermissions.append(requestedPermissions[i]+"\n");
					}
					appNameAndPermissions.append("\n");
				}
			}
			catch (NameNotFoundException e)
			{
				e.printStackTrace();
			}
		}
		return 1;
	}
	*/	
	public static int VoiceStartRecord(int cnChannel,int nRate,int cnBitPerSample)
	{
		//if (CheckRecordPrivilege()==0) return 0;
		Log.d("test"," j_VoiceStartRecord ");
		if (s_bRecording)
		{
			//�������¼������Ҫ��ֹͣ
			if (VoiceStopRecord()==0) return 0;
		}
	
		//1=��������2=������
		s_cnChannel=cnChannel;
		
		//����Ƶ�ʣ�8000...
		s_nRate=nRate;
		
		//ÿ�β���������λ����8��16
		s_cnBitPerSample=cnBitPerSample;
	
		Log.d("test"," j_VoiceStartRecord new thread");
		//�ɶ����߳�¼��
		s_thread=new Thread(new Runnable()
		{
	        public void run()
	        {
	        	//ʵ�ʵ��̺߳���
	        	RecordThreadFunc();
	        }    
		});
		//����״̬
		s_nRecordState=0;
		s_bRecording=true;
		s_thread.start();
		try
		{
			//�ȴ�50����
			Thread.sleep(50);
		}
		catch (Exception e)
		{
		}
		if (s_nRecordState<0) return 0;
		return 1;
	}
	
	public static int VoiceStopRecord()
	{
		//ֹͣ¼����־���߳�ѭ��ʱ������ֹͣ
		s_bRecording=false;
	
		//���ȴ�100���룬���߳��Լ���ֹ
		for (int i=0;i<50;i++)
		{
			//�߳��Ѿ�����¼����
			if (s_nRecordState!=0) break;
			
			try
			{
				//�ȴ�10����
				Thread.sleep(10);
			}
			catch (Exception e)
			{
				//����
				s_nRecordState=-1;
				break;
			}
		}
		//�д���Ҳ�п������߳����õ�
		if (s_nRecordState<=0)
		{
			Log.w("record","can not stop the thread");
			return 0;
		}
	
		return 1;
	}
	//========================
	// ���ݲ���
	//========================
	public void getParameterByIntent() {
		Intent mIntent = this.getIntent();  
		String launch = mIntent.getStringExtra("launch");
		String cookie = mIntent.getStringExtra("cookie");
		int userid =  mIntent.getIntExtra("userid",0);
		String uid;
		uid = Integer.toString(userid);
		String path = Environment.getExternalStorageDirectory().getPath();
		if( path.length()>0 && path.charAt(path.length()-1)!='/')
			path += '/';
		setExternalStorageDirectory( path );
		launchParam(launch,cookie,uid);
		//launchParam("errortitile","sc1=D3F1DC81D98457FE8E1085CB4262CAAD5C443773akl%2bNQbvBYOcjHsDK0Fu4kV%2fbgv3ZBi7sFKU19KP5ks0GkvPwGpmMWe%2b8Q6O%2fkT7EuHjkQ%3d%3d");
		}
	/*
	public void setParameterByIntent(String pkg,String cls,String param1,String param2) 
	{
		ComponentName componentName = new ComponentName(pkg,cls); 
		Intent intent = new Intent();  
		Bundle bundle = new Bundle();  
		bundle.putString("launch", param1);
		bundle.putString("cookie", param2); 
		intent.putExtras(bundle);  
		intent.setComponent(componentName);  
		startActivity(intent);
	}*/
	
    public Cocos2dxGLSurfaceView onCreateView() {
		//CrashHandler crashHandler = CrashHandler.getInstance();  
        //crashHandler.init(getApplicationContext());
    	myActivity = this;
    	getParameterByIntent(); //ȡ��������
        Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);
        // TestCpp should create stencil buffer
        glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);
        //glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 8);
//Android SDK Document        
//        setEGLConfigChooser(int redSize, int greenSize, int blueSize, int alphaSize, int depthSize, int stencilSize)
//        Install a config chooser which will choose a config with at least the specified depthSize and stencilSize, and exactly the specified redSize, greenSize, blueSize and alphaSize.
        return glSurfaceView;
    }
}