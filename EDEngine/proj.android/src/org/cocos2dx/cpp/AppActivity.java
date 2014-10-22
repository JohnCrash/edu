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

//import org.cocos2dx.cpp.CrashHandler;

public class AppActivity extends Cocos2dxActivity {
	private static native void launchParam(final String launch,final String cookie,final String uid);
	private static native void setExternalStorageDirectory(final String sd);
	
	private static final int TAKE_PICTURE = 1;
	private static final int PICK_PICTURE = 2;
	private static AppActivity myActivity;
	
	public static String takeResource(int from)
	{
		if( from == 1 )
		{
			String storageState = Environment.getExternalStorageState();
			if(storageState.equals(Environment.MEDIA_MOUNTED) )
			{
				Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
				long ct = System.currentTimeMillis();
				String path = Environment.getExternalStorageDirectory().getPath() + File.separatorChar + "ljdata/EDEngine/" + ct + ".jpg";
				File file = new File(path);
				file.setWritable(true);
				Uri fileUri = Uri.fromFile(file);
				intent.putExtra( MediaStore.EXTRA_OUTPUT, fileUri);
				intent.putExtra("outputFormat", Bitmap.CompressFormat.JPEG.toString());
				myActivity.startActivityForResult(intent,TAKE_PICTURE);
				return path;
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
		return "";
	}
@Override
	public void onActivityResult(int requestCode,int resultCode,Intent data)
	{
		if(resultCode == TAKE_PICTURE && resultCode==Activity.RESULT_OK )
		{
	          try {  
	               // Bundle extra = data.getExtras(); 
	          }
	          catch(Exception e)
	          {
	        	  e.printStackTrace(); 
	          }
	          return;
		}
		super.onActivityResult(requestCode, resultCode, data);
	}

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
    	getParameterByIntent(); //取启动参数
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