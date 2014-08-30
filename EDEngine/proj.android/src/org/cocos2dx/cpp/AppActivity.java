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

import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
//import org.cocos2dx.cpp.CrashHandler;

public class AppActivity extends Cocos2dxActivity {
	private static native void launchParam(final String launch,final String cookie);
	
	public void getParameterByIntent() {
		Intent mIntent = this.getIntent();  
		String launch = mIntent.getStringExtra("launch");
		String cookie = mIntent.getStringExtra("cookie");
		launchParam(launch,cookie);
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
    	getParameterByIntent(); //取启动参数
        Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);
        // TestCpp should create stencil buffer
        //glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);
        glSurfaceView.setEGLConfigChooser(8, 8, 8, 8, 16, 8);
//Android SDK Document        
//        setEGLConfigChooser(int redSize, int greenSize, int blueSize, int alphaSize, int depthSize, int stencilSize)
//        Install a config chooser which will choose a config with at least the specified depthSize and stencilSize, and exactly the specified redSize, greenSize, blueSize and alphaSize.
        return glSurfaceView;
    }
}