常用类型关系,见LuaBasicConversions.cpp

C++									lua
--------------------------------------------------------------
cocos2d::Size()				{width,height}
cocos2d::Rect()				{x,y,width,height}
cocos2d::Color4b()		{r,g,b,a}
cocos2d::Vec2()			{x,y}
cocos2d::Vec3()			{x,y,z}
cocos2d::Vec4()			{x,y,z,w}
FontDefinition *				{fontName,fontSize,fontAlignmentH,fontAlignmentV,fontFillColor,fontDimensions,
										shadowEnabled,shadowEnabled,shadowOffset,shadowBlur,shadowOpacity,strokeEnabled,
										strokeColor,strokeSize}
TTFConfig *					{fontFilePath,fontSize,glyphs,customGlyphs,distanceFieldEnabled,outlineSize}

==================================
同时lua封装了一层函数 ,见Cocos2d.lua
C++						lua
--------------------------------------------------------------
Vec2()					cc.p()
Size()					cc.size()
Rect()					cc.rect()
Color3B				cc.c3b()
Color4B				cc.c4b()
Color4F				cc.c4f()
Vertex3F			cc.Vertex3F()

==================================
常用类型
Node
	create
	addChild
	removeChild
	removeAllChildren
	setParent
	setRotation
	getAnchorPoint
	getChildren
	setPosition
	setScaleX
	setScaleY
	setScaleZ
	getTag
	setTag
	getChildByTag
	removeChildByTag
	getScene
	getEventDispatcher
	getOpacity
	setPositionZ
	setPositionY
	setPositionX
	isVisible
	getChildrenCount
	addComponent
	visit
	setScheduler
	getScheduler
	setColor
	getParent
	setVisible
	setGlobalZOrder
	setScale
	getScaleX
	getScaleY
	getScaleZ
	setLocalZOrder
	setOpacity
	cleanup
	getComponent
	getContentSize
	getColor
	getBoundingBox
	setEventDispatcher
	getGlobalZOrder
	draw
	setUserObject
	removeFromParent
	update
	sortAllChildren
	getScale
	pause
	resume
	setRotationSkewX
	removeComponent
	removeAllComponents
	convertToWorldSpace
	convertToWorldSpaceAR
	setSkewX
	convertTouchToNodeSpace
	getNodeToParentAffineTransform
	stopActionByTag
	reorderChild
	convertToNodeSpaceAR
	getWorldToNodeAffineTransform
	setCascadeColorEnabled
	getWorldToNodeTransform
	isCascadeColorEnabled
	stopAction
	getActionManager
	getRotationSkewX
	getRotationSkewY
	setGLProgram
	setPosition3D
	setOrderOfArrival
	getParentToNodeTransform
	updateDisplayedColor
	getNodeToWorldAffineTransform
	getPositionX
	getPositionY
	getPositionZ
	isRunning
	setActionManager
	getOrderOfArrival
	getParentToNodeAffineTransform
	getLocalZOrder
	getDisplayedOpacity
	setAdditionalTransform
	getActionByTag
	getDisplayedColor
	getSkewX
	getSkewY
	stopAllActions
	getGLProgramState
	runAction
	getAnchorPointInPoints
	getRotation
	isOpacityModifyRGB
	updateTransform
	getNumberOfRunningActions
	setNodeToParentTransform
	setRotation3D
	setSkewY
	getNodeToWorldTransform
	getPosition3D
	setPhysicsBody
	getPhysicsBody
	getDescription
	setRotationSkewY
	setOpacityModifyRGB
	setCascadeOpacityEnabled
	isIgnoreAnchorPointForPosition
	updateDisplayedOpacity
	_setLocalZOrder
	getGLProgram
	setGLProgramState
	isCascadeOpacityEnabled
	getRotation3D
	getNodeToParentTransform
	convertTouchToNodeSpaceAR
	convertToNodeSpace
	ignoreAnchorPointForPosition
	
Widget
	setSize
	getSize