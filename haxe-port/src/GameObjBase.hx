import haxe.Constraints.Function;
import audioPackage.Audio;
import editorPackage.EdLine;
import editorPackage.GameLayers;
import editorPackage.PolyMaterial;
import editorPackage.PolyMaterials;
import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.GraphicsPath;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.*;
import flash.geom.*;
import flash.display.Bitmap;
import flash.display.BitmapData;
import nape.callbacks.InteractionCallback;
import nape.constraint.Constraint;
import nape.constraint.DistanceJoint;
import nape.constraint.WeldJoint;
import nape.dynamics.Contact;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Shape;

class GameObjBase
{
    public var listIndex : Int = 0;
    public var activeListIndex : Int = 0;
    public var inactiveListIndex : Int = 0;
    
    public var miniMapRenderFunction : Function;
    public var preRenderFunction : Function;
    public var preRenderFunction1 : Function;
    public var renderFunction : Function;
    public var updateFunction : Function;
    public var keepAwakeFunction : Function;
    public var updateFromPhysicsFunction : Function;
    public var onClickedFunction : Function;
    public var canClickFunction : Function;
    public var onMouseOverFunction : Function;
    public var onMouseOutFunction : Function;
    public var updateFunction1 : Function;
    public var switchFunction : Function;
    public var renderShadowFunction : Function;
    public var doSwitchFunction : Function;
    
    
    public var isJointObj : Bool;
    public var switchFlag : Bool;
    
    public var gmat : Matrix;
    public var grect : Rectangle;
    
    public var id : String;
    public var xpos : Float;
    public var ypos : Float;
    public var xpos1 : Float;
    public var ypos1 : Float;
    public var oldxpos : Float;
    public var oldypos : Float;
    public var oldrot : Float;
    public var xpos2 : Float;
    public var xpos3 : Float;
    public var ypos2 : Float;
    public var zpos : Float;
    public var zvel : Float;
    public var active : Bool;
    public var killed : Bool;
    public var visible : Bool;
    public var renderShadowFlag : Bool;
    public var starty : Float;
    public var startx : Float;
    public var startz : Float;
    public var type : Int = 0;
    public var subtype : Int = 0;
    public var state : Int = 0;
    public var state1 : Int = 0;
    public var nextState : Int = 0;
    public var controlIndex : Int = 0;
    public var xoffset : Float;
    public var yoffset : Float;
    public var origxvel : Float;
    public var xvel : Float;
    public var yvel : Float;
    public var xacc : Float;
    public var yacc : Float;
    public var timer : Float;
    public var timer1 : Float;
    public var timer2 : Float;
    public var timer3 : Float;
    public var timerMax : Float;
    public var timer1Max : Float;
    public var timer2Max : Float;
    
    public var animHierarchy : AnimHierarchy;
    public var dobj : DisplayObj;
    public var dobj1 : DisplayObj;
    public var dobj2 : DisplayObj;
    public var dobj3 : DisplayObj;
    
    public var frame : Float;
    public var frame1 : Float;
    public var frame2 : Float;
    public var frameVel : Float;
    public var frameVel1 : Float;
    public var frameVel2 : Float;
    public var animBouncing : Bool;
    
    public var isPolyObject : Bool;
    public var polyMaterial : PolyMaterial;
    public var clickTestType : Int = 0;
    
    public var radius : Float;
    public var colOffsetX : Float;
    public var colOffsetY : Float;
    
    public var movementVec : Vec;
    public var driveVec : Vec;
    public var initParams : String;
    public var initFunctionVarString : String;
    public var linkedPhysLine : EdLine;
    
    public var useMultiplePhysicsUpdates : Bool;
    
    public var dir : Float;
    public var dir1 : Float;
    public var todir : Float;
    public var toPosX : Float;
    public var toPosY : Float;
    public var speed : Float;
    public var origspeed : Float;
    public var count : Int = 0;
    public var hitTimer : Float;
    public var minFrame : Int = 0;
    public var maxFrame : Int = 0;
    public var rotVel : Float;
    public var dist : Float;
    public var flashTimer : Int = 0;
    public var flashTimerMax : Int = 0;
    public var flashFlag : Bool;
    public var xflip : Bool;
    public var healthBarTimer : Int = 0;
    public var health : Float;
    public var maxHealth : Float;
    
    public var logicLink0 : GameObj;
    public var logicLink1 : GameObj;
    
    public var path : Poly;
    public var maxSpeed : Float;
    public var currentMaxSpeed : Float;
    public var parentObj : GameObj;
    
    public var updateInWalkthrough : Bool;
    public var respawnArea : Bool;
    public var inFrontZone : Poly;
    public var name : String;
    public var collisionType : String;
    public var collisionExtra : String;
    public var scale : Float;
    public var scale1 : Float;
    public var uniqueID : Int = 0;
    public var isPhysObj : Bool;
    public var alpha : Float;
    public var alphaVel : Float;
    public var renderSmooth : Bool;
    
    public var currentPoly : Poly;
    
    public var sortByY : Bool;
    public var isVehicle : Bool;
    public var soundTimer : Int = 0;
    
    public var onHitSceneryFunction : Function;
    public var onHitExplosionFunction : Function;
    public var onHitFunction : Function;
    public var onHitPersistFunction : Function;
    public var onHitRemoveFunction : Function;
    public var removeFunction : Function;
    public var nape_bodies : Array<Body>;
    public var nape_joints : Array<Constraint>;
    public var joints : Array<Dynamic>;
    public var physobj : PhysObj;
    public var scoreType : String;
    public var hit_sfx_name : String;
    public var break_sfx_name : String;
    public var singleHitResponse : Bool;
    
    public var jointList : Array<Dynamic>;
    public var hitShapeName : String;
    
    public var isIndependant : Bool;
    
    public var s3dTriListIndex : Int = 0;
    public var m3d : Matrix3D;
    public var ct : ColorTransform;
    
    public function new()
    {
        gmat = new Matrix();
        grect = new Rectangle();
        xpos = 0;
        ypos = 0;
        zpos = 1;
        starty = 0;
        startx = 0;
        active = false;
        killed = false;
        zpos = 0;
        frame = 0;
        frameVel = 1;
        controlIndex = 0;
        timer = 0;
        timer1 = 0;
        radius = 14;
        minFrame = 0;
        maxFrame = 0;
        movementVec = new Vec();
        dobj = null;
        dobj1 = null;
        dobj2 = null;
        isIndependant = false;
        m3d = new Matrix3D();
        ct = new ColorTransform();
    }
    
    
    public function Init(_type : Int) : Void
    {
        id = "";
        var i0 : Int = 0;
        var f0 : Float = 0;
        
        s3dTriListIndex = -1;
        
        isIndependant = false;
        type = _type;
        state = i0;
        xvel = f0;
        yvel = f0;
        frame = f0;
        frameVel = f0;
        animBouncing = false;
        timer = f0;
        hitTimer = f0;
        flashTimer = i0;
        flashFlag = false;
        dir = 0;
        todir = 0;
        healthBarTimer = 0;
        health = 1.0;
        zvel = 0.0;
        name = "";
        collisionType = "";
        collisionExtra = "";
        scale = 1.0;
        xflip = false;
        doSwitchFunction = null;
        renderShadowFunction = null;
        updateFunction = null;
        updateFromPhysicsFunction = null;
        updateFunction1 = null;
        preRenderFunction = null;
        preRenderFunction1 = null;
        renderFunction = null;
        miniMapRenderFunction = null;
        switchFunction = null;
        visible = true;
        renderShadowFlag = false;
        ClearColFlags();
        isPhysObj = false;
        alpha = 1.0;
        xpos1 = 0;
        ypos1 = 0;
        renderSmooth = true;
        frameVel = 1;
        isVehicle = false;
        sortByY = false;
        killed = false;
        initParams = "";
        dobj = null;
        dobj1 = null;
        dobj2 = null;
        
        logicLink0 = null;
        logicLink1 = null;
        
        clickTestType = 0;
        
        jointList = [];
        
        physobj = null;
        onHitSceneryFunction = null;
        onHitFunction = null;
        onHitExplosionFunction = null;
        onHitRemoveFunction = null;
        onHitPersistFunction = null;
        removeFunction = null;
        
        linkedPhysLine = null;
        
        joints = [];
        polyMaterial = null;
        isPolyObject = false;
        respawnArea = false;
        scoreType = "";
        hit_sfx_name = "";
        break_sfx_name = "";
        singleHitResponse = false;
        keepAwakeFunction = null;
        useMultiplePhysicsUpdates = false;
        
        onClickedFunction = null;
        canClickFunction = null;
        onMouseOverFunction = null;
        onMouseOutFunction = null;
        isJointObj = false;
        
        updateInWalkthrough = false;
    }
    
    
    public var colFlag_jumpon : Bool;
    public var colFlag_playercanbekilled : Bool;
    public var colFlag_killPlayer : Bool;
    public var colFlag_canBePickedUp : Bool;
    public var colFlag_dontDamagePlayer : Bool;
    public var colFlag_canBeShot : Bool;
    public var colFlag_isBullet : Bool;
    public var colFlag_isEnemy : Bool;
    public var colFlag_isEnemyBullet : Bool;
    public var colFlag_isPlatform : Bool;
    public var colFlag_isPowerup : Bool;
    public var colFlag_isSwitch : Bool;
    public var colFlag_isBouncyPad : Bool;
    public var colFlag_isCheckpoint : Bool;
    public var colFlag_isShop : Bool;
    public var colFlag_isBall : Bool;
    public var colFlag_isHose : Bool;
    public var colFlag_isPlayer : Bool;
    public var colFlag_isPhysObj : Bool;
    public var colFlag_isGoPhysObj : Bool;
    public var colFlag_isRemovable : Bool;
    
    public function ClearColFlags()
    {
        colFlag_jumpon = false;
        colFlag_killPlayer = false;
        colFlag_playercanbekilled = false;
        colFlag_dontDamagePlayer = false;
        colFlag_canBePickedUp = false;
        colFlag_canBeShot = false;
        colFlag_isBullet = false;
        colFlag_isPlatform = false;
        colFlag_isPowerup = false;
        colFlag_isBouncyPad = false;
        colFlag_isCheckpoint = false;
        colFlag_isShop = false;
        colFlag_isEnemyBullet = false;
        colFlag_isEnemy = false;
        colFlag_isBall = false;
        colFlag_isHose = false;
        colFlag_isPlayer = false;
        colFlag_isPhysObj = false;
        colFlag_isGoPhysObj = false;
        colFlag_isSwitch = false;
        colFlag_isRemovable = false;
    }
    
    
    
    
    public var bd : BitmapData;
    public function Render(_bd : BitmapData) : Void
    {
        bd = _bd;
        if (visible == false)
        {
            return;
        }
        
        if (renderFunction != null)
        {
            renderFunction();
        }
        else
        {
            RenderDispObjNormally();
        }
    }
    
    public function RenderShadow(_bd : BitmapData) : Void
    {
        bd = _bd;
        if (visible == false)
        {
            return;
        }
        if (renderShadowFlag == false)
        {
            return;
        }
        if (dobj == null)
        {
            return;
        }
        
        if (renderShadowFunction != null)
        {
            renderShadowFunction();
        }
        else
        {
            RenderDispObjShadow();
        }
    }
    
    public var shadowCT : ColorTransform = new ColorTransform(1, 1, 1, 1, -255, -255, -255, -128);
    
    public function RenderDispObjShadow(_useScroll : Bool = true)
    {
        var xp : Float = Math.round(xpos);
        var yp : Float = Math.round(ypos);
        if (_useScroll)
        {
            xp = Math.round(xpos - Game.camera.x);
            yp = Math.round(ypos - Game.camera.y);
        }
        
        
        
        
        dobj.RenderAtRotScaled(Std.int(frame), bd, xp, yp, scale, dir, shadowCT, true);
    }
    
    
    
    public function RenderDispObjNormally(_useScroll : Bool = true)
    {
        var sc : Float = scale;
        
        var xp : Float = Math.round(xpos);
        var yp : Float = Math.round(ypos);
        if (_useScroll)
        {
            xp = Math.round(xpos) - Math.round(Game.camera.x);
            yp = Math.round(ypos) - Math.round(Game.camera.y);
        }
        
        if (xp < -200)
        {
            return;
        }
        if (xp > Defs.displayarea_w + 200)
        {
            return;
        }
        if (yp < -200)
        {
            return;
        }
        if (yp > Defs.displayarea_h + 200)
        {
            return;
        }
        
        
        if (sc != 1.0 || dir != 0.0)
        {
            if (xflip)
            {
                dobj.RenderAtRotScaled_Xflip(Std.int(frame), bd, xp, yp, sc, dir, null, renderSmooth);
            }
            else
            {
                dobj.RenderAtRotScaled(Std.int(frame), bd, xp, yp, sc, dir, null, renderSmooth);
            }
        }
        else if (xflip)
        {
            dobj.RenderAtXFlip(Std.int(frame), bd, xp, yp);
        }
        else
        {
            dobj.RenderAt(Std.int(frame), bd, xp, yp);
        }
    }
    
    
    public function RenderDispObjNormally_Vector(_useScroll : Bool = true)
    {
        var sc : Float = scale;
        
        var xp : Float = Math.round(xpos);
        var yp : Float = Math.round(ypos);
        if (_useScroll)
        {
            xp = Math.round(xpos) - Math.round(Game.camera.x);
            yp = Math.round(ypos) - Math.round(Game.camera.y);
        }
        if (xp < -200)
        {
            return;
        }
        if (xp > Defs.displayarea_w + 200)
        {
            return;
        }
        dobj.RenderAtRotScaled_Vector(Std.int(frame), bd, xp, yp, sc, dir);
    }
    
    
    public function RenderDO_Vector(_dispObj : DisplayObj, x : Float, y : Float, _frame : Float, _rot : Float, _scale : Float, _useScroll : Bool = true)
    {
        var xp : Float = Math.round(x);
        var yp : Float = Math.round(y);
        if (_useScroll)
        {
            xp = Math.round(x) - Math.round(Game.camera.x);
            yp = Math.round(y) - Math.round(Game.camera.y);
        }
        if (xp < -200)
        {
            return;
        }
        if (xp > Defs.displayarea_w + 200)
        {
            return;
        }
        _dispObj.RenderAtRotScaled_Vector(Std.int(_frame), bd, xp, yp, _scale, _rot);
    }
    
    public function RenderDO_VectorSprite(x : Float, y : Float, _dispObj : DisplayObj, _frame : Float, _ct : ColorTransform, _rot : Float, _scale : Float, _useScroll : Bool = true)
    {
        var xp : Float = Math.round(x);
        var yp : Float = Math.round(y);
        if (_useScroll)
        {
            xp = Math.round(x) - Math.round(Game.camera.x);
            yp = Math.round(y) - Math.round(Game.camera.y);
        }
        _dispObj.RenderAtRotScaled_VectorSprite(Std.int(_frame), bd, xp, yp, _scale, _rot);
    }
    
    public function RenderDispObjNormallyAlpha()
    {
        if (alpha == 1)
        {
            RenderDispObjNormally();
            return;
        }
        
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        if (xp < -200)
        {
            return;
        }
        if (xp > Defs.displayarea_w + 200)
        {
            return;
        }
        
        
        ct.alphaMultiplier = alpha;
        
        dobj.RenderAtRotScaled(Std.int(frame), bd, xp, yp, scale, dir, ct, renderSmooth);
    }
    
    
    public function RenderDispObjAt(_xpos : Float, _ypos : Float, _dobj : DisplayObj, _frame : Int, _ct : ColorTransform = null, _dir : Float = 0, _scale : Float = 1, _useScroll : Bool = true, _doClip : Bool = true)
    {
        var sc : Float = _scale;
        
        var xp : Float = Math.round(_xpos);
        var yp : Float = Math.round(_ypos);
        if (_useScroll)
        {
            xp = Math.round(_xpos) - Math.round(Game.camera.x);
            yp = Math.round(_ypos) - Math.round(Game.camera.y);
        }
        
        if (_doClip)
        {
            if (xp < -200)
            {
                return;
            }
            if (xp > Defs.displayarea_w + 200)
            {
                return;
            }
        }
        
        if (_scale != 1.0 || _dir != 0.0)
        {
            if (xflip)
            {
                _dobj.RenderAtRotScaled_Xflip(_frame, bd, xp, yp, _scale, _dir, null, renderSmooth);
            }
            else
            {
                _dobj.RenderAtRotScaled(_frame, bd, xp, yp, _scale, _dir, null, renderSmooth);
            }
        }
        else if (xflip)
        {
            _dobj.RenderAtXFlip(_frame, bd, xp, yp);
        }
        else
        {
            _dobj.RenderAt(_frame, bd, xp, yp);
        }
    }
    
    public function RenderCollision() : Void
    {
        if (EngineDebug.IsSet(1) == false)
        {
            return;
        }
        if (colFlag_isGoPhysObj == false)
        {
            return;
        }
        
        
        
        var x : Float = 0;
        var y : Float = 0;
        x += xpos;
        x -= Game.camera.x;
        x += colOffsetX;
        y += ypos;
        y -= Game.camera.y;
        y += colOffsetY;
        Utils.RenderCircle(bd, x, y, radius, 0xffffffff);
    }
    
    
    
    
    
    
    
    
    public function IsInWorld(radius : Float) : Bool
    {
        if (xpos < 0 - radius)
        {
            return false;
        }
        if (ypos < 0 - radius)
        {
            return false;
        }
        if (xpos > Defs.displayarea_w + radius)
        {
            return false;
        }
        if (ypos > Defs.displayarea_h + radius)
        {
            return false;
        }
        return true;
    }
    
    
    
    
    public function GetDirBetween(x0 : Float, y0 : Float, x1 : Float, y1 : Float) : Float
    {
        var d = Math.atan2(y1 - y0, x1 - x0);
        return d;
    }
    
    
    
    
    public function GetVelFromDir(vel : Float)
    {
        xvel = Math.cos(dir) * vel;
        yvel = Math.sin(dir) * vel;
    }
    
    
    
    
    
    public function CycleAnimationEx() : Bool
    {
        var looped : Bool = false;
        
        if (animBouncing == false)
        {
            frame += frameVel;
            var numFrames = maxFrame - minFrame;
            if (frame > maxFrame)
            {
                frame = frame - numFrames;
                looped = true;
            }
            if (frame < minFrame)
            {
                frame += numFrames;
                looped = true;
            }
        }
        else
        {
            frame += frameVel;
            var numFrames = maxFrame - minFrame;
            if (frame > maxFrame)
            {
                frameVel *= -1;
                frame = maxFrame;
                looped = true;
            }
            if (frame < minFrame)
            {
                frameVel *= -1;
                frame = minFrame;
                looped = true;
            }
        }
        return looped;
    }
    public function PlayAnimationEx() : Bool
    {
        var looped : Bool = false;
        frame += frameVel;
        if (frame > maxFrame)
        {
            frame = maxFrame;
            looped = true;
        }
        if (frame < minFrame)
        {
            frame = minFrame;
            looped = true;
        }
        return looped;
    }
    
    public function CycleAnimation() : Void
    {
        var fv : Float = frameVel;
        var maxframe : Int = dobj.GetNumFrames();
        
        frame += fv;
        if (frame >= maxframe)
        {
            frame -= (maxframe);
        }
        if (frame < 0)
        {
            frame += (maxframe);
        }
    }
    public function CycleAnimation1() : Void
    {
        var fv : Float = frameVel1;
        var maxframe : Int = dobj1.GetNumFrames();
        
        frame1 += fv;
        if (frame1 >= maxframe)
        {
            frame1 -= (maxframe);
        }
        if (frame1 < 0)
        {
            frame += (maxframe);
        }
    }
    
    public function PlayAnimation() : Bool
    {
        var maxframe : Int = as3hx.Compat.parseInt(dobj.GetNumFrames() - 1);
        frame += frameVel;
        if (frame > maxframe)
        {
            frame = maxframe;
            return true;
        }
        if (frame < 0)
        {
            frame = 0;
            return true;
        }
        return false;
    }
    public function PlayAnimation1() : Bool
    {
        var maxframe : Int = as3hx.Compat.parseInt(dobj1.GetNumFrames() - 1);
        frame1 += frameVel1;
        if (frame1 >= maxframe)
        {
            frame1 = maxframe;
            return true;
        }
        return false;
    }
    public function PlayAnimation2() : Bool
    {
        var maxframe : Int = as3hx.Compat.parseInt(dobj2.GetNumFrames() - 1);
        frame2 += frameVel2;
        if (frame2 >= maxframe)
        {
            frame2 = maxframe;
            return true;
        }
        return false;
    }
    
    
    
    
    
    public function Update() : Void
    {
        if (keepAwakeFunction != null)
        {
            keepAwakeFunction();
        }
        WakeUp_Nape();
        
        if (updateFunction != null)
        {
            updateFunction();
        }
        
        if (sortByY)
        {
        }
    }
    
    
    
    
    
    
    
    public function InitKeepAwakeFunction()
    {
        if (physobj != null)
        {
            if (physobj.wakeFunctionName != "")
            {
                keepAwakeFunction = Reflect.field(this, physobj.wakeFunctionName);
            }
        }
    }
    
    
    
    public function KeepAwake_Constant()
    {
        WakeUp_Nape();
    }
    public function KeepAwake_ConstantAndNearby()
    {
        WakeUp_Nape();
        WakeUpNearbyObjects(20);
    }
    
    
    public function WakeUpNearbyObjects(radius : Int = 50)
    {
        var r2 : Float = radius * radius;
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active)
            {
                if ((untyped go).listIndex != (untyped this).listIndex)
                {
                    if (Utils.Dist2BetweenPoints(xpos, ypos, go.xpos, go.ypos) < r2)
                    {
                        go.WakeUp_Nape();
                    }
                }
            }
        }
    }
    
    public function WakeUp_Nape()
    {
        if (nape_bodies != null)
        {
            if (nape_bodies.length != 0)
            {
            }
        }
    }
    
    
    public function WakeUp_B2D()
    {  /*
			if (bodies != null)
			{
				if (bodies.length != 0)
				{
					bodies[0].WakeUp();
				}
			}
			*/  
        
    }
    
    public function Sleep_B2D()
    {  /*
			if (bodies != null)
			{
				if (bodies.length != 0)
				{
					bodies[0].PutToSleep();
				}
			}
			*/  
        
    }
    
    public function Sleep_Nape()
    {
        if (nape_bodies != null)
        {
            if (nape_bodies.length != 0)
            {
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    public var switch_timer : Int = 0;
    public var switchType : String;
    public function InitGameObj_Switch()
    {
        colFlag_isSwitch = true;
        name = "switch";
        
        Utils.GetParams(initParams);
        
        switchType = Utils.GetParam("type");
        
        if (switchType == "")
        {
            switchType = "once";
        }
        
        if (switchType == "once")
        {
            doSwitchFunction = SwitchedGameObj_Switch;
            updateFunction = null;
            state = 0;
            frame = dobj.GetFrameIndexLabel("on");
        }
        if (switchType == "timed")
        {
            switch_timer = as3hx.Compat.parseInt(Utils.GetParamNumber("switch_time") * Defs.fps);
            doSwitchFunction = SwitchedGameObj_TimedSwitch;
            updateFunction = UpdateGameObj_TimedSwitch;
            frame = dobj.GetFrameIndexLabel("on");
        }
        if (switchType == "2way")
        {
            doSwitchFunction = SwitchedGameObj_TwoWaySwitch;
            updateFunction = UpdateGameObj_TwoWaySwitch;
            frame = dobj.GetFrameIndexLabel("on");
            state = 0;
        }
        switchContactList = [];
    }
    
    public var switchContactList : Array<Dynamic>;
    
    public function Switch_IsInContactList(go : GameObj) : Bool
    {
        if (Lambda.indexOf(switchContactList, go) == -1)
        {
            return false;
        }
        return true;
    }
    public function Switch_AddToContactList(go : GameObj)
    {
        switchContactList.push(go);
    }
    public function Switch_RemoveFromContactList(go : GameObj)
    {
        var index : Int = Lambda.indexOf(switchContactList, go);
        switchContactList.splice(index, 1);
    }
    public function Switch_IsDown() : Bool
    {
        if (switchType == "once")
        {
            if (state == 0)
            {
                return false;
            }
            return true;
        }
        if (switchType == "timed")
        {
            if (state == 0)
            {
                return false;
            }
            return true;
        }
        if (switchType == "2way")
        {
            if (state == 0)
            {
                return false;
            }
            return true;
        }
        return false;
    }
    
    
    
    
    public function SwitchedGameObj_TwoWaySwitch() : Bool
    {
        if (state == 0)
        {
            state = 1;
            frame = dobj.GetFrameIndexLabel("off");
            return true;
        }
        else
        {
            state = 0;
            frame = dobj.GetFrameIndexLabel("on");
            return true;
        }
        return false;
    }
    
    
    
    public function UpdateGameObj_TwoWaySwitch()
    {  /*
			if (controlMode == 0)
			{
				controlMode = 2;
			}
			else
			{
				controlMode = 1;
			}
			*/  
        
    }
    
    
    
    
    public function SwitchedGameObj_Switch() : Bool
    {
        if (state == 1)
        {
            return false;
        }
        
        if (state == 0)
        {
            state = 1;
            state = 1;
            frame = dobj.GetFrameIndexLabel("off");
            return true;
        }
        return false;
    }
    
    
    public function UpdateGameObj_TimedSwitch()
    {
        if (state == 1)
        {
            timer--;
            if (timer <= 0)
            {
                Game.DoGameObjSwitch(this);
                state = 0;
            }
        }
    }
    
    
    
    public function SwitchedGameObj_TimedSwitch() : Bool
    {
        var retval : Bool = true;
        
        if (state == 0)
        {
            state = 1;
            timer = switch_timer;
            retval = true;
        }
        else
        {
            retval = false;
        }
        return retval;
    }
    
    
    
    public function Update_SimpleRotator()
    {
        dir += rotVel;
        dir = Utils.NormalizeRot(dir);
    }
    
    
    public function Init_SimpleRotator()
    {
        Utils.print("Init_SimpleRotator");
        Utils.GetParams(initParams);
        
        rotVel = Utils.DegToRad(Utils.GetParamNumber("rotation_speed", 0));
        
        updateFunction = Update_SimpleRotator;
    }
    
    
    
    public function Update_PlayAnimList()
    {
        if (PlayAnimationEx())
        {
            Utils.GetParams(initFunctionVarString);
            currentAnim++;
            if (currentAnim >= numAnims)
            {
                currentAnim = 0;
            }
            var s : String = Utils.paramNames[currentAnim];
            frameVel = as3hx.Compat.parseFloat(Utils.paramValues[currentAnim]);
            SetAnimRange(s + "_start", s + "_end", true);
        }
    }
    
    
    public var numAnims : Int = 0;
    public var currentAnim : Int = 0;
    public function Init_PlayAnimList()
    {
        Utils.print("Init_PlayAnimList");
        Utils.GetParams(initFunctionVarString);
        
        numAnims = Utils.paramNames.length;
        currentAnim = 0;
        
        updateFunction = Update_PlayAnimList;
        
        var s : String = Utils.paramNames[currentAnim];
        frameVel = as3hx.Compat.parseFloat(Utils.paramValues[currentAnim]);
        SetAnimRange(s + "_start", s + "_end", true);
    }
    
    
    
    
    public function Set_SwitchedAnim(_mode : Int)
    {
        state = _mode;
        if (state == 0)
        {
            SetAnimRange("idle_off_start", "idle_off_end", true);
        }
        if (state == 1)
        {
            SetAnimRange("off_on_start", "off_on_end", true);
        }
        if (state == 2)
        {
            SetAnimRange("idle_on_start", "idle_on_end", true);
        }
        if (state == 3)
        {
            SetAnimRange("on_off_start", "on_off_end", true);
        }
    }
    public function Update_SwitchedAnim()
    {
        if (state == 0)
        {
            CycleAnimationEx();
        }
        else if (state == 1)
        {
            if (PlayAnimationEx())
            {
                Set_SwitchedAnim(2);
            }
        }
        else if (state == 2)
        {
            CycleAnimationEx();
        }
        else if (state == 3)
        {
            if (PlayAnimationEx())
            {
                Set_SwitchedAnim(0);
            }
        }
    }
    
    public function SwitchFunction_SwitchedAnim()
    {
        if (state == 0)
        {
            if (dobj.DoesFrameIndexLabelExist("off_on_start"))
            {
                Set_SwitchedAnim(1);
            }
            else
            {
                Set_SwitchedAnim(2);
            }
        }
        else if (state == 2)
        {
            if (dobj.DoesFrameIndexLabelExist("on_off_start"))
            {
                Set_SwitchedAnim(3);
            }
            else
            {
                Set_SwitchedAnim(0);
            }
        }
    }
    
    public function Init_SwitchedAnim()
    {
        Utils.print("Init SwitchedAnim");
        Utils.GetParams(initParams);
        
        updateFunction = Update_SwitchedAnim;
        switchName = Utils.GetParamString("switch", "");
        var startPos : Int = Utils.GetParamInt("startpos", 0);
        
        Set_SwitchedAnim(startPos);
        
        
        switchFunction = null;
        if (switchName != "")
        {
            switchFunction = SwitchFunction_SwitchedAnim;
        }
    }
    
    
    
    
    public var lineLinearPos : Float;
    public var lineSpeed : Float;
    public var lineIndex : Int = 0;
    public var lineLoop : Bool;
    public var lineResetAtEnd : Bool;
    public var lineSpline : Bool;
    public var lineRotateToPath : Bool;
    
    public var switchName : String;
    public var switchName1 : String;
    
    
    
    
    public function InitGameObj_Path()
    {
        Utils.print("Init path object");
        
        Utils.GetParams(initParams);
        
        for (i in 0...Utils.paramNames.length)
        {
            Utils.print("InitGameObj_Path: Param " + i + ":  " + Utils.paramNames[i] + "   =   " + Utils.paramValues[i]);
        }
        
        
        var lineName : String = Utils.GetParam("path_line", "");
        if (lineName == "")
        {
            lineIndex = -1;
        }
        else
        {
            lineIndex = Game.GetLineIndexByName(lineName);
        }
        
        if (lineIndex == -1)
        {
            updateFunction = null;
        }
        
        
        lineSpeed = 1 / (Utils.GetParamNumber("path_speed") * Defs.fps);
        lineLoop = Utils.GetParamBool("path_loop");
        switchName = Utils.GetParam("path_switch", "");
        lineResetAtEnd = Utils.GetParamBool("path_endreset");
        lineSpline = Utils.GetParamBool("path_spline");
        lineRotateToPath = Utils.GetParamBool("path_rotatetopath", false);
        lineLinearPos = 0;
        var startPos : Float = Utils.GetParamNumber("path_startpos", 0);
        
        lineLinearPos = startPos;
        
        var twoway : Bool = Utils.GetParamBool("path_2way");
        
        
        state = 1;
        switchFunction = null;
        updateFunction = null;
        if (lineIndex != -1)
        {
            if (switchName != "")
            {
                state = 0;
                switchFunction = SwitchFunction_Path;
            }
            else
            {
                state = 1;
            }
            updateFunction = UpdateObj_Path;
        }
        
        if (twoway)
        {
            updateFunction = UpdateObj_Path_2way;
            if (switchName != "")
            {
                switchFunction = SwitchFunction_Path_2way;
                updateFunction = UpdateObj_Path_2way_switched;
            }
        }
    }
    
    public function SwitchFunction_Path_2way()
    {
        if (state == 0)
        {
            state = 1;
        }
        else if (state == 1)
        {
            Utils.print("path 2way 2");
            state = 2;
        }
        else
        {
            Utils.print("path 2way 1");
            state = 1;
        }
    }
    
    public function UpdateObj_Path_2way()
    {
        if (lineRotateToPath)
        {
            dir = GetLineAngle();
        }
        
        if (state == 0)
        {
            state = 1;
        }
        
        if (state == 1)
        {
            var pos : Point = UpdateLine(lineSpeed);
            xpos = pos.x;
            ypos = pos.y;
            if (lineLinearPos >= 1)
            {
                state = 2;
            }
        }
        else if (state == 2)
        {
            var pos : Point = UpdateLine(-lineSpeed);
            xpos = pos.x;
            ypos = pos.y;
            if (lineLinearPos <= 0)
            {
                state = 1;
            }
        }
    }
    
    public function UpdateObj_Path_2way_switched()
    {
        if (lineRotateToPath)
        {
            dir = GetLineAngle();
        }
        
        if (state == 0)
        {
            var pos : Point = UpdateLine(0);
            xpos = pos.x;
            ypos = pos.y;
        }
        else if (state == 1)
        {
            var pos : Point = UpdateLine(lineSpeed);
            xpos = pos.x;
            ypos = pos.y;
        }
        else if (state == 2)
        {
            var pos : Point = UpdateLine(-lineSpeed);
            xpos = pos.x;
            ypos = pos.y;
        }
    }
    
    
    public function SwitchFunction_Path()
    {
        if (state == 0)
        {
            state = 1;
        }
    }
    public function UpdateObj_Path()
    {
        if (lineRotateToPath)
        {
            dir = GetLineAngle();
        }
        
        if (state == 0)
        {
            var pos : Point = UpdateLine(0);
            xpos = pos.x;
            ypos = pos.y;
        }
        else
        {
            var pos : Point = UpdateLine(lineSpeed);
            xpos = pos.x;
            ypos = pos.y;
            
            if (lineLoop == false)
            {
                if (lineLinearPos >= 1)
                {
                    lineLinearPos = 1;
                    if (lineResetAtEnd)
                    {
                        lineLinearPos = 0;
                    }
                    state = 0;
                }
            }
        }
    }
    public function GetLineAngle() : Float
    {
        var line : EdLine = Levels.GetCurrent().lines[lineIndex];
        if (line == null)
        {
            return 0;
        }
        
        var p0 : Point = null;        var p1 : Point = null;        if (lineLinearPos < 0.5)
        {
            p0 = line.GetInterpolatedPoint_SegmentRatio(lineLinearPos, lineLoop, lineSpline);
            p1 = line.GetInterpolatedPoint_SegmentRatio(lineLinearPos + 0.01, lineLoop, lineSpline);
        }
        else
        {
            p0 = line.GetInterpolatedPoint_SegmentRatio(lineLinearPos - 0.01, lineLoop, lineSpline);
            p1 = line.GetInterpolatedPoint_SegmentRatio(lineLinearPos, lineLoop, lineSpline);
        }
        
        var ang : Float = Math.atan2(p1.y - p0.y, p1.x - p0.x);
        return ang;
    }
    public function UpdateLine(_spd : Float) : Point
    {
        lineLinearPos += _spd;
        if (lineLinearPos > 1)
        {
            if (lineLoop == true)
            {
                lineLinearPos -= 1;
            }
            else
            {
                lineLinearPos = 1;
            }
        }
        if (lineLinearPos < 0)
        {
            if (lineLoop == true)
            {
                lineLinearPos += 1;
            }
            else
            {
                lineLinearPos = 0;
            }
        }
        
        var line : EdLine = Levels.GetCurrent().lines[lineIndex];
        if (line == null)
        {
            return null;
        }
        
        var p : Point = null;        
        
        
        
        var lp : Float = lineLinearPos;
        
        if (pathEaseName != null && pathEaseName != "" && pathEaseName != "linear")
        {
            lp = Ease.EaseByName(pathEaseName, lp, pathEaseValue);
        }
        
        if (lineLoop == true && lineSpline == false)
        {
            p = line.GetInterpolatedPoint_SegmentRatio(lp, lineLoop, lineSpline);
        }
        else
        {
            p = line.GetInterpolatedPoint_EqualSpacing(lp, lineLoop, lineSpline);
        }
        return p;
    }
    
    
    
    
    
    public function GameObj_InitInvisible() : Void
    {
        visible = false;
    }
    
    
    public function GameObj_InitCycleAnim() : Void
    {
        updateFunction = GameObj_UpdateCycleAnim;
        frameVel = 1;
    }
    public function GameObj_UpdateCycleAnim() : Void
    {
        CycleAnimation();
    }
    
    public function GameObj_UpdateCycleAnimEx() : Void
    {
        CycleAnimationEx();
    }
    public function GameObj_UpdatePlayAnimEx() : Void
    {
        CycleAnimationEx();
    }
    
    public function InitSortByY() : Void
    {
        sortByY = true;
    }
    
    
    
    
    
    public function SetAnimRangeSingle(name : Dynamic, reset : Bool = true, _bounce : Bool = false)
    {
        animBouncing = _bounce;
        
        SetAnimRange(name, name + "_end", reset, _bounce);
    }
    public function SetAnimRange(fr0Name : String, fr1Name : String, reset : Bool = true, _bounce : Bool = false)
    {
        animBouncing = _bounce;
        minFrame = dobj.GetFrameIndexLabel(fr0Name);
        maxFrame = dobj.GetFrameIndexLabel(fr1Name);
        if (frame < minFrame)
        {
            frame = minFrame;
        }
        if (frame > maxFrame)
        {
            frame = maxFrame;
        }
        if (reset)
        {
            frame = minFrame;
        }
    }
    
    
    public var anims : Array<Dynamic>;
    public function SetAnim(name : String, reset : Bool = true, _bounce : Bool = false)
    {
        dobj = GraphicObjects.GetDisplayObjByName(name);
        minFrame = 0;
        maxFrame = as3hx.Compat.parseInt(dobj.GetNumFrames() - 1);
        
        
        
        
        
        
        
        
        
        
        
        
        
        if (frame < minFrame)
        {
            frame = minFrame;
        }
        if (frame > maxFrame)
        {
            frame = maxFrame;
        }
        if (reset)
        {
            frame = minFrame;
        }
    }
    
    
    
    
    
    
    
    
    
    public function SetBodyShapeRadius(bodyIndex : Int, shapeIndex : Int, radius : Float)
    {
        var b : Body = nape_bodies[bodyIndex];
        var c : Circle = try cast(b.shapes.at(shapeIndex), Circle) catch(e:Dynamic) null;
        c.radius = radius;
    }
    
    public function SetBodyShapeMaterial(bodyIndex : Int, shapeIndex : Int, materialName : String)
    {
        var physMaterial : PhysObjMaterial = Game.GetPhysMaterialByName(materialName);
        var b : Body = nape_bodies[bodyIndex];
        var s : Shape = b.shapes.at(shapeIndex);
        s.material = physMaterial.MakeNapeMaterial();
    }
    
    
    public function GetBodyLinearVelocity(index : Int) : Vec2
    {
        return nape_bodies[index].velocity;
    }
    
    
    public function RemovePhysObj()
    {
        for (j in nape_joints)
        {
            if (PhysicsBase.GetNapeSpace().constraints.has(j))
            {
                PhysicsBase.GetNapeSpace().constraints.remove(j);
                
                for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
                {
                    if (go.active && go.isJointObj)
                    {
                        go.JointObject_JointRemoved(j);
                    }
                }
            }
        }
        nape_joints = [];
        for (b in nape_bodies)
        {
            PhysicsBase.GetNapeSpace().bodies.remove(b);
        }
        nape_bodies = [];
    }
    
    public function RemoveObject(_func : Function = null)
    {
        if (_func != null)
        {
            removeFunction = _func;
        }
        killed = true;
    }
    
    
    public function GetBody(index : Int) : Body
    {
        var body : Body = nape_bodies[index];
        return body;
    }
    public function GetBodyMass(index : Int) : Float
    {
        var body : Body = nape_bodies[index];
        return body.mass;
    }
    
    public function ApplyImpulse(_x : Float, _y : Float) : Void
    {
        if (nape_bodies == null) return; // AS3 `for each(b in null)` is a silent no-op; Haxe iterating an
        // unset Vector crashes on `.length`. DoExplosion impulses EVERY object in radius, including
        // non-physics GOs (scenery/switch graphic/helptext) whose nape_bodies was never initialised.
        for (b in nape_bodies)
        {
            b.applyImpulse(new Vec2(_x, _y));
        }
    }

    public function ApplyForce(_x : Float, _y : Float) : Void
    {
        if (nape_bodies == null) return; // same AS3 null-iteration-is-noop guard as ApplyImpulse
        for (b in nape_bodies)
        {
            b.velocity.addeq(new Vec2(_x, _y));
        }
    }
    
    
    public function SetBodyLinearVelocity(index : Int, x : Float, y : Float)
    {
        var b : Body = nape_bodies[index];
        b.velocity.x = x;
        b.velocity.y = y;
    }
    public function SetBodyAngularVelocity(index : Int, r : Float)
    {
        var b : Body = nape_bodies[index];
        b.angularVel = r;
    }
    
    public function GetBodyAngle(index : Int) : Float
    {
        var body : Body = nape_bodies[index];
        return body.rotation;
    }
    
    public function SetBodyAngle(index : Int, ang : Float)
    {
        var body : Body = nape_bodies[index];
        body.rotation = ang;
    }
    
    public function SetBodyXForm_Immediate(_index : Int, _x : Float, _y : Float, rot : Float) : Void
    {
        var body : Body = nape_bodies[0];
        if (body.type == BodyType.STATIC)
        {
            body.type = BodyType.KINEMATIC;
        }
        body.position.setxy(_x, _y);
        body.rotation = rot;
    }
    public function SetBodyXForm(_index : Int, _x : Float, _y : Float, rot : Float) : Void
    {
        var body : Body = nape_bodies[0];
        body.type = BodyType.KINEMATIC;

        FrameStep.XFormCheck(name, _x, _y, rot, body.position.x, body.position.y);
        var dx : Float = _x - body.position.x;
        var dy : Float = _y - body.position.y;
        var da : Float = rot - body.rotation;

        // GENERIC FIX (all movers, all levels): when this kinematic body actually moves, wake the
        // DYNAMIC bodies welded to it. nape-haxe4 otherwise leaves a welded dynamic body asleep, so a
        // moving platform / lift / switch-wall can't drag it through the weld and the attached object
        // is left behind (original AS3 nape kept it following). The move guard means stationary movers
        // still let their welded bodies sleep normally (no perf cost).
        if (Math.abs(dx) > 0.001 || Math.abs(dy) > 0.001 || Math.abs(da) > 0.0001)
        {
            WakeWeldedBodies(body);
        }

        var ts : Float = PhysicsBase.nape_oneOverTimeStep;
        dx *= ts;
        dy *= ts;
        da *= ts;

        body.velocity.setxy(dx, dy);
        body.angularVel = da;
    }

    static var __wakeImpulse : Vec2 = null;
    // Wake every DYNAMIC body welded to `body` so the weld constraint can drag it. Welded dynamic
    // chains (post<->post) then wake each other through nape's normal propagation.
    function WakeWeldedBodies(body : Body) : Void
    {
        if (body == null || body.constraints == null) return;
        if (__wakeImpulse == null) __wakeImpulse = new Vec2(0, 0);
        for (c in body.constraints)
        {
            var w : WeldJoint = (Std.isOfType(c, WeldJoint)) ? cast(c, WeldJoint) : null;
            if (w == null) continue;
            if (w.body1 != null && w.body1 != body && w.body1.type == BodyType.DYNAMIC) w.body1.applyImpulse(__wakeImpulse);
            if (w.body2 != null && w.body2 != body && w.body2.type == BodyType.DYNAMIC) w.body2.applyImpulse(__wakeImpulse);
        }
    }
    
    
    public function GetBodyCollisionMask() : Int
    {
        var body : Body = null;        var shape : Shape = null;        body = nape_bodies[0];
        for (s in 0...body.shapes.length)
        {
            shape = body.shapes.at(s);
            return shape.filter.collisionMask;
        }
        return 0;
    }
    
    
    public function GetBodySensorMask() : Int
    {
        var body : Body = null;        var shape : Shape = null;        body = nape_bodies[0];
        for (s in 0...body.shapes.length)
        {
            shape = body.shapes.at(s);
            return shape.filter.sensorMask;
        }
        return 0;
    }
    
    public function SetBodyCollisionMask(_bodyIndex : Int = -1, _mask : Int = 0) : Void
    {
        var body : Body = null;        var shape : Shape = null;        
        if (_bodyIndex == -1)
        {
            for (i in 0...nape_bodies.length)
            {
                SetBodyCollisionMask(i, _mask);
            }
        }
        else
        {
            body = nape_bodies[_bodyIndex];
            for (s in 0...body.shapes.length)
            {
                shape = body.shapes.at(s);
                shape.filter.collisionMask = _mask;
            }
        }
    }
    
    public function SetBodyShapeCollisionMask(_bodyIndex : Int = 0, _shapeIndex : Int = 0, _mask : Int = 0) : Void
    {
        var body : Body = null;        var shape : Shape = null;        
        body = nape_bodies[_bodyIndex];
        shape = body.shapes.at(_shapeIndex);
        shape.filter.collisionMask = _mask;
    }
    
    public function SetBodySensorMask(_bodyIndex : Int = -1, _mask : Int = 0) : Void
    {
        var body : Body = null;        var shape : Shape = null;        
        if (_bodyIndex == -1)
        {
            for (i in 0...nape_bodies.length)
            {
                SetBodySensorMask(i, _mask);
            }
        }
        else
        {
            body = nape_bodies[_bodyIndex];
            for (s in 0...body.shapes.length)
            {
                shape = body.shapes.at(s);
                shape.filter.sensorMask = _mask;
            }
        }
    }
    
    
    
    public var hitInteractionCallback_Nape : InteractionCallback;
    public var hitContactPoint_Nape : Contact;
    public var hitUserData_Nape : Contact;
    
    
    
    
    
    
    public function HitPhysObj_HitSwitch(goHitter : GameObj)
    {
        if (goHitter.name != "missile")
        {
            return;
        }
        if (doSwitchFunction != null)
        {
            Utils.print("doing switch ");
            if (doSwitchFunction())
            {
                Utils.print("switch hit");
                Game.DoSwitch(try cast(this, GameObj) catch(e:Dynamic) null);
            }
        }
    }
    public function InitPhysObj_HitSwitch()
    {
        InitPhysObj_Switch();
        onHitFunction = HitPhysObj_HitSwitch;
    }
    
    public function InitPhysObj_Switch()
    {
        Utils.GetParams(initParams);
        
        var switchType : String = Utils.GetParam("type");
        
        if (switchType == "")
        {
            switchType = "once";
        }
        
        if (switchType == "once")
        {
            doSwitchFunction = SwitchedPhysObj_Switch;
            updateFunction = UpdatePhysObj_SwitchOnce;
            state = 0;
        }
        if (switchType == "timed")
        {
            switch_timer = as3hx.Compat.parseInt(Utils.GetParamNumber("switch_time") * Defs.fps);
            doSwitchFunction = SwitchedPhysObj_TimedSwitch;
            updateFunction = UpdatePhysObj_TimedSwitch;
        }
        if (switchType == "2way")
        {
            doSwitchFunction = SwitchedPhysObj_TwoWaySwitch;
            updateFunction = UpdatePhysObj_TwoWaySwitch;
            state = 0;
        }
        frame = 0;
    }
    
    public function SwitchedPhysObj_TwoWaySwitch() : Bool
    {
        if (state == 0)
        {
            state = 1;
            timer = 10;
            return true;
        }
        return false;
    }
    
    
    public function SwitchedPhysObj_TwoWaySwitch_Anim() : Bool
    {
        if (state == 0)
        {
            Utils.print("2way 0");
            if (frame == minFrame)
            {
                state = 1;
                return true;
            }
        }
        else
        {
            Utils.print("2way 0");
            if (frame == maxFrame)
            {
                state = 0;
                return true;
            }
        }
        return false;
    }
    
    
    
    public function UpdatePhysObj_TwoWaySwitch()
    {
        if (state == 0)
        {
            frame = 0;
        }
        else
        {
            frame = 1;
            timer--;
            if (timer <= 0)
            {
                state = 0;
            }
        }
    }
    
    
    
    
    public function SwitchedPhysObj_Switch() : Bool
    {
        Utils.print("SwitchedPhysObj_Switch");
        
        if (state == 1)
        {
            return false;
        }
        
        state = 1;
        Game.DoSwitch(try cast(this, GameObj) catch(e:Dynamic) null);
        
        
        frame = 1;
        return true;
    }
    
    
    public function UpdatePhysObj_SwitchOnce()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            frame = 1;
        }
    }
    public function UpdatePhysObj_TimedSwitch()
    {
        if (state == 1)
        {
            timer--;
            if (timer <= 0)
            {
                Game.DoSwitch(try cast(this, GameObj) catch(e:Dynamic) null);
                state = 0;
            }
        }
    }
    
    
    
    public function SwitchedPhysObj_TimedSwitch() : Bool
    {
        var retval : Bool = true;
        
        if (state == 0)
        {
            state = 1;
            timer = switch_timer;
            retval = true;
        }
        else
        {
            retval = false;
        }
        return retval;
    }
    
    
    
    public var pathSwitchTimer : Int = 0;
    public var pathSwitchControlMode : Int = 0;
    public var pathSwitchDoneOnce : Bool;
    public function InitPhysObj_PathSwitch()
    {
        InitPhysObj_Path();
        onHitFunction = HitPhysObj_HitSwitch;
        
        pathSwitchTimer = 0;
        pathSwitchControlMode = 0;
        updateFunction1 = updateFunction;
        
        
        var switchType : String = Utils.GetParam("type");
        
        if (switchType == "")
        {
            switchType = "once";
        }
        
        if (switchType == "once")
        {
            pathSwitchDoneOnce = false;
            doSwitchFunction = SwitchedPhysObj_PathSwitch_Once;
            updateFunction = UpdatePhysObj_PathSwitch_Once;
        }
        if (switchType == "timed")
        {
            switch_timer = as3hx.Compat.parseInt(Utils.GetParamNumber("switch_time") * Defs.fps);
            
            updateFunction = UpdatePhysObj_PathSwitch_Once;
        }
        if (switchType == "2way")
        {
            doSwitchFunction = SwitchedPhysObj_PathSwitch_TwoWay;
            updateFunction = UpdatePhysObj_PathSwitch_TwoWay;
        }
    }
    public function SwitchedPhysObj_PathSwitch_TwoWay() : Bool
    {
        if (pathSwitchControlMode != 0)
        {
            return false;
        }
        pathSwitchTimer = 20;
        pathSwitchControlMode = 1;
        
        return true;
    }
    public function SwitchedPhysObj_PathSwitch_Once() : Bool
    {
        if (pathSwitchDoneOnce)
        {
            return false;
        }
        if (pathSwitchControlMode == 0)
        {
            pathSwitchControlMode = 1;
        }
        else
        {
            pathSwitchControlMode = 0;
        }
        pathSwitchDoneOnce = true;
        return true;
    }
    public function UpdatePhysObj_PathSwitch_TwoWay()
    {
        updateFunction1();
        if (pathSwitchControlMode == 0)
        {
            frame = 1;
        }
        else if (pathSwitchControlMode == 1)
        {
            frame = 0;
            pathSwitchTimer--;
            if (pathSwitchTimer <= 0)
            {
                pathSwitchControlMode = 0;
            }
        }
    }
    public function UpdatePhysObj_PathSwitch_Once()
    {
        updateFunction1();
        if (pathSwitchControlMode == 0)
        {
        }
        else if (pathSwitchControlMode == 1)
        {
            pathSwitchTimer--;
            if (pathSwitchTimer <= 0)
            {
                pathSwitchControlMode = 0;
            }
        }
        frame = 1;
        if (pathSwitchDoneOnce)
        {
            frame = 2;
        }
    }
    
    
    public var pathEaseName : String;
    public var pathEaseValue : Float;
    public var pathControlMode : Int = 0;
    public function InitPhysObj_Path_Old()
    {
        useMultiplePhysicsUpdates = true;
        
        Utils.print("Init path object");
        
        Utils.GetParams(initParams);
        
        pathEaseName = Utils.GetParamString("path_ease", "linear");
        pathEaseValue = Utils.GetParamNumber("path_easevalue", 1);
        
        for (i in 0...Utils.paramNames.length)
        {
            Utils.print("Param " + i + ":  " + Utils.paramNames[i] + "   =   " + Utils.paramValues[i]);
        }
        
        initParams = "editor_layer=1,path_line=path01,path_speed=8,path_loop=true,path_spline=false,path_endreset=false,path_startpos=0,path_2way=false,path_rotatetopath=false,path_startmoving=true";
        
        var lineName : String = Utils.GetParam("path_line", "");
        if (lineName == "")
        {
            lineIndex = -1;
        }
        else
        {
            lineIndex = GetLineIndexByName(lineName);
        }
        
        if (lineIndex == -1)
        {
            updateFunction = null;
        }
        
        dir = GetBodyAngle(0);
        
        lineSpeed = 1 / (Utils.GetParamNumber("path_speed") * Defs.fps);
        lineLoop = Utils.GetParamBool("path_loop");
        
        switchName = Game.GetSwitchJointName(id);
        
        lineResetAtEnd = Utils.GetParamBool("path_endreset");
        lineSpline = Utils.GetParamBool("path_spline");
        lineRotateToPath = Utils.GetParamBool("path_rotatetopath", false);
        var lineStartMoving : Bool = Utils.GetParamBool("path_startmoving", true);
        lineLinearPos = 0;
        var startPos : Float = Utils.GetParamNumber("path_startpos", 0);
        
        lineLinearPos = startPos;
        
        var twoway : Bool = Utils.GetParamBool("path_2way");
        
        pathPos = new Point();
        
        pathControlMode = 0;
        switchFunction = null;
        updateFunction = null;
        
        var pos : Point = UpdateLine(0);
        pathPos.x = pos.x;
        pathPos.y = pos.y;
        xpos = oldxpos = pos.x;
        ypos = oldypos = pos.y;
        oldrot = dir;
        
        
        SetBodyXForm_Immediate(0, xpos, ypos, dir);
        
        if (lineIndex != -1)
        {
            switchFunction = SwitchFunction_PhysObj_Path;
            updateFunction = UpdatePhysObj_Path;
        }
        
        if (twoway)
        {
            updateFunction = UpdatePhysObj_Path_2way;
            if (switchName != "")
            {
                switchFunction = SwitchFunction_PhysObj_Path_2way;
                updateFunction = UpdatePhysObj_Path_2way_switched;
            }
        }
        if (lineStartMoving)
        {
            pathControlMode = 1;
        }
    }
    
    public var pathPos : Point;
    
    public function RenderPathDebug()
    {
        Utils.RenderCircle(bd, pathPos.x, pathPos.y, 10, 0xffffffff);
    }
    
    public function SwitchFunction_PhysObj_Path_2way()
    {
        if (pathControlMode == 0)
        {
            pathControlMode = 1;
        }
        else if (pathControlMode == 1)
        {
            pathControlMode = 2;
        }
        else
        {
            pathControlMode = 1;
        }
    }
    
    public function UpdatePhysObj_Path_2way()
    {
        if (lineRotateToPath)
        {
            dir = GetLineAngle();
        }
        
        if (pathControlMode == 0)
        {
            pathControlMode = 1;
        }
        
        if (pathControlMode == 1)
        {
            var pos : Point = UpdateLine(lineSpeed);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
            if (lineLinearPos >= 1)
            {
                pathControlMode = 2;
            }
        }
        else if (pathControlMode == 2)
        {
            var pos : Point = UpdateLine(-lineSpeed);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
            if (lineLinearPos <= 0)
            {
                pathControlMode = 1;
            }
        }
    }
    
    public function UpdatePhysObj_Path_2way_switched()
    {
        if (lineRotateToPath)
        {
            dir = GetLineAngle();
        }
        
        if (pathControlMode == 0)
        {
            var pos : Point = UpdateLine(0);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
        }
        else if (pathControlMode == 1)
        {
            var pos : Point = UpdateLine(lineSpeed);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
        }
        else if (pathControlMode == 2)
        {
            var pos : Point = UpdateLine(-lineSpeed);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
        }
    }
    
    
    public function SwitchFunction_PhysObj_Path()
    {
        if (pathControlMode == 0)
        {
            pathControlMode = 1;
        }
        else
        {
            pathControlMode = 0;
        }
    }
    
    public function UpdatePhysObj_Path()
    {
        if (lineRotateToPath)
        {
            dir = GetLineAngle();
        }
        
        if (pathControlMode == 0)
        {
            var pos : Point = UpdateLine(0);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
        }
        else
        {
            var pos : Point = UpdateLine(lineSpeed);
            pathPos.x = pos.x;
            pathPos.y = pos.y;
            SetBodyXForm(0, pos.x, pos.y, dir);
            
            if (lineLoop == false)
            {
                if (lineLinearPos >= 1)
                {
                    lineLinearPos = 1;
                    if (lineResetAtEnd)
                    {
                        lineLinearPos = 0;
                    }
                    pathControlMode = 0;
                }
            }
        }
    }
    
    
    
    
    public function GetLineIndexByName(name : String) : Int
    {
        var l : Level = Levels.GetCurrent();
        var index : Int = 0;
        for (line/* AS3HX WARNING could not determine type for var: line exp: EField(EIdent(l),lines) type: null */ in l.lines)
        {
            if (line.id == name)
            {
                return index;
            }
            index++;
        }
        return -1;
    }
    
    
    
    public function RenderPhysicsLineObjectInner_Surface()
    {
    }
    
    public function RenderPhysicsLineObjectInner()
    {
        if (Game.gameState == Game.gameState_UI)
        {
            return;
        }

        // HD: the terrain fill is drawn into the 2x screenBD; this scales the (logical-coord) fillScreenMC
        // up to match. null in the live build (HD.SCALE=1) → bd.draw(..., null, ...) === original behaviour.
        var hdDrawMat : Matrix = null;
        #if hd
        hdDrawMat = new Matrix();
        hdDrawMat.scale(HD.SCALE, HD.SCALE);
        #end

        var x : Float = Math.round(xpos);
        var y : Float = Math.round(ypos);
        x -= Math.round(Game.camera.x);
        y -= Math.round(Game.camera.y);
        
        
        
        
        var g : Graphics = Game.fillScreenMC.graphics;
        g.clear();
        
        var sx : Float = Math.round(Game.camera.x);
        var sy : Float = Math.round(Game.camera.y);
        
        var z : Int = as3hx.Compat.parseInt(zpos);
        
        var bmat : Matrix = new Matrix();
        
        
        bmat.translate(-sx, -sy);
        
        var p0 : Point = null;        var p1 : Point = null;        
        var newpoints : Array<Dynamic> = [];
        
        var m : Matrix = new Matrix();
        m.rotate(dir);
        
        var sc : Float = Game.camera.scale;
        
        var r : Rectangle = new Rectangle(0, 0, 1, 1);
        
        var index : Int = 0;
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(linkedPhysLine),points) type: null */ in linkedPhysLine.points)
        {
            p0 = p.clone();
            p0.x -= linkedPhysLine.centrex;
            p0.y -= linkedPhysLine.centrey;
            p0 = m.transformPoint(p0);
            p0.x += xpos;
            p0.y += ypos;
            p0.x -= sx;
            p0.y -= sy;
            p0.x *= sc;
            p0.y *= sc;
            newpoints.push(p0);
            
            if (index == 0)
            {
                r = new Rectangle(p0.x, p0.y, 1, 1);
            }
            else
            {
                if (p0.x < r.left)
                {
                    r.left = p0.x;
                }
                if (p0.x > r.right)
                {
                    r.right = p0.x;
                }
                if (p0.y < r.top)
                {
                    r.top = p0.y;
                }
                if (p0.y > r.bottom)
                {
                    r.bottom = p0.y;
                }
            }
            index++;
        }
        
        
        
        
        if (false)
        {
            g.lineStyle(null, null, 0);
        }
        else
        {
            g.lineStyle(2, lineRender_Color, 1);
        }
        
        
        
        g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), bmat, true);
        
        var gradientColors : Array<Dynamic> = [lineRender_Color0, lineRender_Color1];
        var gradientAlphas : Array<Dynamic> = [1, 1];
        var gradientRatios : Array<Dynamic> = [0, 255];
        var gradientMatrix : Matrix = new Matrix();
        gradientMatrix.createGradientBox(r.width, r.height, 0, r.x, r.y);
        
        
        
        
        
        
        g.lineStyle(null, null, 0);
        
        if (name == "line_for_show")
        {
            g.lineStyle(2, 0xffffff, 1);
            
            p1 = newpoints[0].clone();
            g.moveTo(p1.x, p1.y);
            for (i in 1...newpoints.length)
            {
                p0 = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            bd.draw(Game.fillScreenMC, hdDrawMat, null, null, null, false);
            return;
        }
        
        
        
        
        
        p1 = newpoints[0].clone();
        g.moveTo(p1.x, p1.y);
        for (i in 1...newpoints.length)
        {
            p0 = newpoints[i].clone();
            g.lineTo(p0.x, p0.y);
        }
        g.lineTo(p1.x, p1.y);
        g.endFill();
        
        
        if (false)
        {
            g.lineStyle(2, lineRender_Color, 1);
            for (i in 0...newpoints.length)
            {
                var j : Int = as3hx.Compat.parseInt(i + 1);
                if (j >= newpoints.length)
                {
                    j = 0;
                }
                p0 = newpoints[i].clone();
                p1 = newpoints[j].clone();
                if (p0.x < p1.x)
                {
                    g.moveTo(p0.x, p0.y);
                    g.lineTo(p1.x, p1.y);
                }
            }
        }
        bd.draw(Game.fillScreenMC, hdDrawMat, null, null, null, false);
        
        if (name == "death")
        {
            var dob : DisplayObj = GraphicObjects.GetDisplayObjByName("terrainSpikes");
            var numf : Int = as3hx.Compat.parseInt(dob.GetNumFrames() - 1);
            Utils.RandSetSeed(Std.int(123456789101112));
            
            for (j in 0...newpoints.length)
            {
                var k : Int = as3hx.Compat.parseInt(j + 1);
                if (k >= newpoints.length)
                {
                    k = 0;
                }
                p0 = Reflect.field(newpoints, Std.string(j)).clone();
                p1 = newpoints[k].clone();
                
                
                
                var dx : Float = p1.x - p0.x;
                var dy : Float = p1.y - p0.y;
                var adx : Float = Math.abs(dx);
                var ady : Float = Math.abs(dy);
                
                var rot : Float = Math.atan2(dy, dx);
                
                var len : Float = Utils.DistBetweenPoints(p0.x, p0.y, p1.x, p1.y);
                var segDist : Float = 7;
                var numSegs : Int = as3hx.Compat.parseInt(len / segDist);
                dx /= numSegs;
                dy /= numSegs;
                
                
                for (i in 0...numSegs)
                {
                    p0.x += dx;
                    p0.y += dy;
                    var p : Point = p0.clone();
                    p.x += Utils.RandBetweenFloat_Seeded(-1, 1);
                    p.y += Utils.RandBetweenFloat_Seeded(-1, 1);
                    var f : Int = Utils.RandBetweenInt_Seeded(0, numf);
                    dob.RenderAtRotScaled(f, bd, p.x, p.y, 1, rot, null, true);
                }
            }
        }
        
        
        if (false)
        {
            var dob : DisplayObj = GraphicObjects.GetDisplayObjByName("grass");
            var numf : Int = as3hx.Compat.parseInt(dob.GetNumFrames() - 1);
            Utils.RandSetSeed(Std.int(123456789101112));
            
            for (j in 0...newpoints.length)
            {
                var k : Int = as3hx.Compat.parseInt(j + 1);
                if (k >= newpoints.length)
                {
                    k = 0;
                }
                p0 = Reflect.field(newpoints, Std.string(j)).clone();
                p1 = newpoints[k].clone();
                
                var dx : Float = p1.x - p0.x;
                var dy : Float = p1.y - p0.y;
                var adx : Float = Math.abs(dx);
                var ady : Float = Math.abs(dy);
                
                if ((p0.x < p1.x) && (adx > ady))
                {
                    var len : Float = Utils.DistBetweenPoints(p0.x, p0.y, p1.x, p1.y);
                    var segDist : Float = 3;
                    var numSegs : Int = as3hx.Compat.parseInt(len / segDist);
                    dx /= numSegs;
                    dy /= numSegs;
                    
                    
                    for (i in 0...numSegs)
                    {
                        p0.x += dx;
                        p0.y += dy;
                        var p : Point = p0.clone();
                        p.x += Utils.RandBetweenFloat_Seeded(-1, 1);
                        p.y += Utils.RandBetweenFloat_Seeded(2, 6);
                        var f : Int = Utils.RandBetweenInt_Seeded(0, numf);
                        dob.RenderAt(f, bd, p.x, p.y);
                    }
                }
                else
                {
                    var dx : Float = p1.x - p0.x;
                    var dy : Float = p1.y - p0.y;
                    var len : Float = Utils.DistBetweenPoints(p0.x, p0.y, p1.x, p1.y);
                    var segDist : Float = 3;
                    var numSegs : Int = as3hx.Compat.parseInt(len / segDist);
                    dx /= numSegs;
                    dy /= numSegs;
                    
                    
                    
                    for (i in 0...numSegs)
                    {
                        p0.x += dx;
                        p0.y += dy;
                        var p : Point = p0.clone();
                        p.x += Utils.RandBetweenFloat_Seeded(-1, 1);
                        p.y += Utils.RandBetweenFloat_Seeded(0, 2);
                        
                        var xx : Int = Std.int(p.x);
                        var yy : Int = Std.int(p.y);
                        var rand : Int = Utils.RandBetweenInt(1, 2);
                        
                        if (rand == 0)
                        {
                        }
                        else if (rand == 1)
                        {
                            bd.setPixel32(xx, yy, 0);
                            bd.setPixel32(xx + 1, yy, 0);
                            bd.setPixel32(xx, yy + 1, 0);
                            bd.setPixel32(xx + 1, yy + 1, 0);
                        }
                        else if (rand == 2)
                        {
                            bd.setPixel32(xx - 1, yy - 1, 0);
                            bd.setPixel32(xx - 1, yy + 1, 0);
                            bd.setPixel32(xx + 1, yy - 1, 0);
                            bd.setPixel32(xx + 1, yy + 1, 0);
                            bd.setPixel32(xx, yy, 0);
                        }
                    }
                }
            }
        }
    }
    
    public function RenderPhysicsLineObjectInner_Shadow()
    {
        return;
        var x : Float = xpos - Game.camera.x;
        var y : Float = ypos - Game.camera.y;
        
        var g : Graphics = Game.fillScreenMC.graphics;
        g.clear();
        
        var p0 : Point = null;        var p1 : Point = null;        
        var newpoints : Array<Dynamic> = [];
        
        var m : Matrix = new Matrix();
        m.rotate(dir);
        
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(linkedPhysLine),points) type: null */ in linkedPhysLine.points)
        {
            p0 = p.clone();
            p0.x -= linkedPhysLine.centrex;
            p0.y -= linkedPhysLine.centrey;
            p0 = m.transformPoint(p0);
            p0.x += xpos;
            p0.y += ypos;
            newpoints.push(p0);
        }
        
        
        g.lineStyle(null, null, 0);
        g.beginFill(0, 1);
        
        p1 = newpoints[0].clone();
        g.moveTo(p1.x, p1.y);
        for (i in 1...newpoints.length)
        {
            p0 = newpoints[i].clone();
            g.lineTo(p0.x, p0.y);
        }
        g.lineTo(p1.x, p1.y);
        g.endFill();
    }
    
    
    public function RenderPhysicsLineObjectShadow()
    {
        RenderPhysicsLineObjectInner();
        var shadowMat : Matrix = new Matrix();
        
        
        bd.draw(Game.fillScreenMC, shadowMat, shadowCT, null, null, false);
    }
    
    public function RenderPhysicsLineObject()
    {
        if (invisibleTimer == 0)
        {
            RenderPhysicsLineObjectInner();
        }
        RenderInvisibleBar(0, 0);
    }
    public function UpdatePhysicsLineObject()
    {
    }
    
    
    public var lineRender_Mode : String;
    public var lineRender_Color : Int = 0;
    public var lineRender_Color0 : Int = 0;
    public var lineRender_Color1 : Int = 0;
    public var lineRender_LineColor : Int = 0;
    public var lineRender_LineAlpha : Float;
    public var lineRender_lineThickness : Float;
    
    public function InitPhysicsLineObject(_line : EdLine)
    {
        isPolyObject = true;
        linkedPhysLine = _line;
        visible = true;
        updateFunction = UpdatePhysicsLineObject;
        renderFunction = RenderPhysicsLineObject;
        lineRender_Mode = "";
        lineRender_Color = 0x808080;
        lineRender_LineColor = 0x0000a0;
        lineRender_LineAlpha = 1;
        lineRender_lineThickness = 0;
        renderShadowFunction = RenderPhysicsLineObjectShadow;
        renderShadowFlag = true;
        frame = 0;
        
        var polyMatName : String = linkedPhysLine.objParameters.GetValueString("line_material");
        polyMaterial = PolyMaterials.GetByName(polyMatName);
        frame = polyMaterial.fillFrame;
        
        var layerZpos : Float = GameLayers.GetZPosByName(linkedPhysLine.objParameters.GetValueString("game_layer"));
        zpos = layerZpos;
        
        var initFunc : String = polyMaterial.initFunctionName;
        
        id = linkedPhysLine.id;
        
        dobj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
        
        if (initFunc != null && initFunc != "")
        {
            Reflect.callMethod(this, Reflect.field(this, initFunc), []); // bind `this` (AS3 this[initFunc]())
        }
    }
    
    public function InitPhysicsLineObject_Nape(_line : EdLine, _body : Body)
    {
        isPolyObject = true;
        nape_bodies = [];
        if (_body != null)
        {
            nape_bodies.push(_body);
        }
        linkedPhysLine = _line;
        visible = true;
        updateFunction = UpdatePhysicsLineObject;
        renderFunction = RenderPhysicsLineObject;
        lineRender_Mode = "";
        lineRender_Color = 0x808080;
        lineRender_LineColor = 0x0000a0;
        lineRender_LineAlpha = 1;
        lineRender_lineThickness = 0;
        renderShadowFunction = RenderPhysicsLineObjectShadow;
        renderShadowFlag = true;
        frame = 0;
        
        var polyMatName : String = linkedPhysLine.objParameters.GetValueString("line_material");
        polyMaterial = PolyMaterials.GetByName(polyMatName);
        frame = polyMaterial.fillFrame;
        
        var layerZpos : Float = GameLayers.GetZPosByName(linkedPhysLine.objParameters.GetValueString("game_layer"));
        zpos = layerZpos;
        
        var initFunc : String = polyMaterial.initFunctionName;
        
        id = linkedPhysLine.id;
        
        dobj = GraphicObjects.GetDisplayObjByName(polyMaterial.graphicName);
        
        if (initFunc != null && initFunc != "")
        {
            Reflect.callMethod(this, Reflect.field(this, initFunc), []); // bind `this` (AS3 this[initFunc]())
        }
    }
    
    
    public function SetPolysMaterial_Nape(materialName : String)
    {
        var physMaterial : PhysObjMaterial = Game.GetPhysMaterialByName(materialName);
        
        
        for (i in 0...nape_bodies.length)
        {
            var b : Body = nape_bodies[i];
        }
    }
    /*
		function SetPolysMaterial(materialName:String)
		{
			var physMaterial:PhysObjMaterial = Game.GetPhysMaterialByName(materialName);

			var b:b2Body = bodies[0];
			var s:b2Shape;

			for (s = b.GetShapeList(); s; s = s.GetNext())
			{
				s.m_friction = physMaterial.friction;
				s.m_restitution = physMaterial.restitution;
				s.m_density = physMaterial.density;
			}
		}
		*/
    
    
    public var invisibleTimer : Int = 0;
    public var invisibleTimerMax : Int = 0;
    public function UpdateInvisibleTimer() : Bool
    {
        if (invisibleTimer == 0)
        {
            return false;
        }
        invisibleTimer--;
        if (invisibleTimer <= 0)
        {
            invisibleTimer = 0;
            return true;
        }
        return false;
    }
    public function InitInvisibleTimer()
    {
        invisibleTimer = invisibleTimerMax = 0;
    }
    public function SetInvisibleTimer(time : Int)
    {
        invisibleTimer = invisibleTimerMax = time;
    }
    public function RenderInvisibleBar(x : Float, y : Float)
    {
        if (invisibleTimer == 0)
        {
            return;
        }
        
        var w : Int = 30;
        var h : Int = 5;
        
        var r : Rectangle = new Rectangle(xpos + x + (-w / 2), ypos + y, w, h);
        
        bd.fillRect(r, 0xff000000);
        
        r.width = Utils.ScaleTo(0, w, 0, invisibleTimerMax, invisibleTimer);
        bd.fillRect(r, 0xffff0000);
    }
    
    public var jointController_joints : Array<Constraint>;
    public function InitGameObjJoint_Null(cons : Array<Constraint>)
    {
        jointController_joints = null;
        visible = false;
    }
    
    
    
    
    public function RenderJointRenderer()
    {
        if (false)
        {
            return;
        }
        
        for (c in jointController_joints)
        {
            if (Std.is(c, DistanceJoint))
            {
                var d : DistanceJoint = try cast(c, DistanceJoint) catch(e:Dynamic) null;
                
                var p0 : Point = new Point(d.anchor1.x, d.anchor1.y);
                var p1 : Point = new Point(d.anchor2.x, d.anchor2.y);
                
                
                gmat.identity();
                gmat.rotate(d.body1.rotation);
                p0 = gmat.transformPoint(p0);
                gmat.identity();
                gmat.rotate(d.body2.rotation);
                p1 = gmat.transformPoint(p1);
                
                p0.x += d.body1.position.x;
                p0.y += d.body1.position.y;
                p1.x += d.body2.position.x;
                p1.y += d.body2.position.y;
                
                
                
                
                p0.x -= Game.camera.x;
                p1.x -= Game.camera.x;
                p0.y -= Game.camera.y;
                p1.y -= Game.camera.y;
                
                var g : Graphics = Game.fillScreenMC.graphics;
                g.clear();
                g.lineStyle(3, 0xF7ECC7, 1);
                g.moveTo(p0.x, p0.y);
                g.lineTo(p1.x, p1.y);
                bd.draw(Game.fillScreenMC);
            }
        }
    }
    
    
    
    
    
    
    
    
    public function SwitchOnceHit(goHitter : GameObj)
    {
        if (state != 0)
        {
            return false;
        }
        if (goHitter.collisionType != "football" && goHitter.collisionType != "beachball")
        {
            return false;
        }
        state = 1;
        frame = 1;
        return true;
    }
    public function UpdateSwitchOnce()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            Game.DoSwitch(this);
            frame = 1;
            state = 2;
        }
    }
    
    
    public function InitSwitch_Once()
    {
        Utils.GetParams(initParams);
        switchType = "once";
        onHitFunction = SwitchOnceHit;
        updateFunction = UpdateSwitchOnce;
        state = 0;
    }
    
    
    
    
    public function Switch2WayHit(goHitter : GameObj)
    {
        if (goHitter.collisionType != "football" && goHitter.collisionType != "beachball")
        {
            return false;
        }
        
        if (state != 0)
        {
            return false;
        }
        if (timer > 0)
        {
            return false;
        }
        
        timer = 3;
        if (switchFlag == false)
        {
            state = 1;
        }
        else
        {
            state = 2;
        }
        return true;
    }
    public function UpdateSwitch2Way()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            Game.DoSwitch(this);
            frame = 1;
            switchFlag = true;
            state = 0;
        }
        else if (state == 2)
        {
            Game.DoSwitch(this);
            frame = 0;
            switchFlag = false;
            state = 0;
        }
        timer--;
        if (timer <= 0)
        {
            timer = 0;
        }
    }
    
    
    public function InitSwitch_2Way()
    {
        Utils.GetParams(initParams);
        switchType = "once";
        onHitFunction = Switch2WayHit;
        updateFunction = UpdateSwitch2Way;
        state = 0;
        switchFlag = false;
        timer = 0;
    }
    
    
    
    
    
    public function SwitchWeightHitPersist(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return false;
        }
        if (goHitter.physobj == null)
        {
            return false;
        }
        if (state != 2)
        {
            return false;
        }
        
        
        // LOAD-BEARING typed local — do NOT inline back to goHitter.nape_bodies[0].velocity.y -= …
        // The typed `nape.phys.Body` forces the velocity PROXY setter (-> engine.setVel, which keeps the
        // body awake); the inlined form takes the Dynamic path and the nudge silently never reaches the
        // engine, so the block sleeps at the 60-frame threshold and the switch drops green after ~1s.
        var b : nape.phys.Body = goHitter.nape_bodies[0];
        b.velocity.y -= 0.00000001;

        timer = 4;
        return false;
    }
    public function SwitchWeightHit(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return false;
        }
        if (goHitter.physobj == null)
        {
            return false;
        }
        if (state != 0)
        {
            return false;
        }
        
        
        
        Utils.print("SwitchWeightHit");
        
        
        
        if (switchFlag == false)
        {
            state = 1;
        }
        return true;
    }
    public function UpdateSwitchWeight()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            Game.DoSwitch(this);
            frame = 1;
            switchFlag = true;
            state = 2;
            timer = 4;
        }
        else if (state == 2)
        {
            timer--;
            if (timer <= 0)
            {
                Game.DoSwitch(this);
                frame = 0;
                switchFlag = false;
                state = 0;
            }
        }
    }
    
    
    public function InitSwitch_Weight()
    {
        Utils.GetParams(initParams);
        switchType = "2way";
        onHitFunction = SwitchWeightHit;
        onHitPersistFunction = SwitchWeightHitPersist;
        updateFunction = UpdateSwitchWeight;
        state = 0;
        switchFlag = false;
    }
    
    
    
    
    public function SwitchTimerHit(goHitter : GameObj)
    {
        if (state != 0)
        {
            return false;
        }
        if (goHitter.collisionType != "football" && goHitter.collisionType != "beachball")
        {
            return false;
        }
        
        state = 1;
        timer = switch_timer;
        
        return true;
    }
    public function UpdateSwitchTimer()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            Game.DoSwitch(this);
            frame = 1;
            state = 2;
            timer1 = 8;
            switchFlag = true;
        }
        else if (state == 2)
        {
            minFrame = 1;
            maxFrame = as3hx.Compat.parseInt(dobj.GetNumFrames() - 1);
            frame = as3hx.Compat.parseInt(Utils.ScaleTo(minFrame, maxFrame, 0, switch_timer, timer));
            timer--;
            if (timer <= 0)
            {
                Game.DoSwitch(this);
                frame = 0;
                state = 0;
                switchFlag = false;
            }
            timer1--;
            if (timer1 <= 0)
            {
                timer1 = 8;
            }
        }
    }
    
    
    public function InitSwitch_Timer()
    {
        Utils.GetParams(initParams);
        switch_timer = as3hx.Compat.parseInt(Utils.GetParamNumber("switch_time") * Defs.fps);
        
        switchType = "timer";
        onHitFunction = SwitchTimerHit;
        updateFunction = UpdateSwitchTimer;
        state = 0;
        switchFlag = false;
    }
    
    
    
    
    
    public function Switchable_Disappear_Switched()
    {
        if (state != 0)
        {
            return;
        }
        if (switchFlag == false)
        {
            state = 1;
        }
        else
        {
            state = 2;
        }
    }
    public function UpdateSwitchable_Disappear()
    {
        if (state == 0)
        {
            PlayAnimation();
        }
        else if (state == 1)
        {
            SetBodyCollisionMask(0, 0);
            state = 0;
            switchFlag = true;
            frameVel = 1;
        }
        else if (state == 2)
        {
            SetBodyCollisionMask(0, 15);
            state = 0;
            switchFlag = false;
            frameVel = -1;
        }
    }
    public function InitSwitchable_Disappear()
    {
        frameVel = -1;
        Utils.GetParams(initParams);
        switchName = Utils.GetParamString("switch_name", "");
        updateFunction = UpdateSwitchable_Disappear;
        switchFunction = Switchable_Disappear_Switched;
        switchFlag = false;
    }
    
    public function InitJointRenderer()
    {
        visible = false;
    }
    
    public function ClipTest(rad : Float = 40) : Bool
    {
        if (GameVars.takingADump)
        {
            return true;
        }
        if (xpos + rad < Game.camera.x)
        {
            return false;
        }
        if (ypos + rad < Game.camera.y)
        {
            return false;
        }
        if (xpos - rad > Game.camera.x + Defs.displayarea_w)
        {
            return false;
        }
        if (ypos - rad > Game.camera.y + Defs.displayarea_h)
        {
            return false;
        }
        return true;
    }
    
    
    public function LimitVelocity_Nape(max : Float)
    {
        var b : Body = nape_bodies[0];
        var vel : Vec2 = b.velocity;
        
        if (vel.length > max)
        {
            var v : Vec = new Vec();
            v.SetFromDxDy(vel.x, vel.y);
            v.speed = max;
            b.velocity.x = v.X();
            b.velocity.y = v.Y();
        }
    }
    
    public function LimitVelocity_B2D(max : Float)
    {  /*
			var b:b2Body = bodies[0];
			var vel:b2Vec2 = b.GetLinearVelocity();
			if (vel.Length() > max)
			{
				var v1:b2Vec2 = vel.Copy();
				v1.Normalize();
				v1.Multiply(max);
				b.SetLinearVelocity(v1);
			}
			*/  
        
        
    }
    
    public function LimitXVelocity_B2D(max : Float)
    {  /*
			var b:b2Body = bodies[0];
			var vel:b2Vec2 = b.GetLinearVelocity();
			if(Math.abs (vel.x) > max)
			{
				if (vel.x > 0)
				{
					vel.x = max;
				}
				else
				{
					vel.x = -max;
				}
				b.SetLinearVelocity(vel);
			}
			*/  
        
    }
    public function GetUniqueId()
    {
        var s : String = "uidig_";
        for (i in 0...6)
        {
            s += Utils.RandBetweenInt(0, 99);
        }
        id = s;
    }
    
    
    /*


function OnHit$(SelText)(goHitter:GameObj)
{
	if (goHitter == null) return;
}
function Render$(SelText)()
{
}
function Update$(SelText)()
{
}
function Init$(SelText)()
{
	onHitFunction = OnHit$(SelText);
	renderFunction = Render$(SelText);
	updateFunction = Update$(SelText);
}

		*/
    
    public function SFX_OneShot(name : String, _positional : Bool = true, _volume : Float = 1)
    {
        var x : Float = xpos - Game.camera.x;
        x = Utils.LimitNumber(0, Defs.displayarea_w, x);
        
        var pan : Float = Utils.ScaleTo(-1, 1, 0, Defs.displayarea_w, x);
        
        Audio.OneShot(name, pan, _volume);
    }
    
    
    public var path_startmode : String;
    public var path_endmode : String;
    public var path_switchmode : String;
    public function InitPhysObj_Path()
    {
        Utils.GetParams(initParams);
        
        path_startmode = Utils.GetParamString("path_startmode", "start");
        path_endmode = Utils.GetParamString("path_endmode", "stop");
        path_switchmode = Utils.GetParamString("path_switchmode", "stop");
        
        pathEaseName = Utils.GetParamString("path_ease", "linear");
        pathEaseValue = Utils.GetParamNumber("path_easevalue", 1);
        
        for (i in 0...Utils.paramNames.length)
        {
        }
        
        var lineName : String = Utils.GetParam("path_line", "");
        if (lineName == "")
        {
            Utils.print("ERROR: Path Object has no line");
            return;
        }
        lineIndex = GetLineIndexByName(lineName);
        
        var line : EdLine = Levels.GetCurrent().lines[lineIndex];
        
        lineSpline = line.IsSpline();

        dir = GetBodyAngle(0);
        FrameStep.PathInit(name, nape_bodies[0].rotation, dir, nape_bodies[0].position.x, nape_bodies[0].position.y);
        
        lineSpeed = 1 / (Utils.GetParamNumber("path_speed") * Defs.fps);
        
        switchName = Game.GetSwitchJointName(id);
        
        lineRotateToPath = Utils.GetParamBool("path_rotatetopath", false);
        var startPos : Float = Utils.GetParamNumber("path_startpos", 0);
        lineLinearPos = startPos;
        
        pathPos = new Point();
        
        pathControlMode = 0;
        switchFunction = null;
        updateFunction = null;
        
        var pos : Point = UpdateLine(0);
        pathPos.x = pos.x;
        pathPos.y = pos.y;
        xpos = oldxpos = pos.x;
        ypos = oldypos = pos.y;
        oldrot = dir;
        
        
        SetBodyXForm_Immediate(0, xpos, ypos, dir);
        
        switchFunction = SwitchFunction_PhysObj_Path_New;
        updateFunction = UpdatePhysObj_Path_New;
        
        
        if (path_startmode == "stop")
        {
            pathControlMode = 0;
        }
        if (path_startmode == "start")
        {
            pathControlMode = 1;
        }
        if (path_startmode == "start_reverse")
        {
            pathControlMode = 1;
            lineSpeed *= -1;
        }
    }
    
    
    public function SwitchFunction_PhysObj_Path_New()
    {
        if (path_switchmode == "start")
        {
            pathControlMode = 1;
        }
        if (path_switchmode == "start_doubleswitch")
        {
            if (lineLinearPos == 0)
            {
                lineSpeed = Math.abs(lineSpeed);
            }
            else
            {
                lineSpeed = -Math.abs(lineSpeed);
            }
            pathControlMode = 1;
        }
        if (path_switchmode == "stop")
        {
            pathControlMode = 0;
        }
        if (path_switchmode == "toggle_dir")
        {
            lineSpeed *= -1;
            pathControlMode = 1;
        }
        if (path_switchmode == "toggle_movement")
        {
            pathControlMode = as3hx.Compat.parseInt(1 - pathControlMode);
        }
    }
    
    public function UpdatePhysObj_Path_SetPos()
    {
        var pos : Point = UpdateLine(0);
        pathPos.x = pos.x;
        pathPos.y = pos.y;
        SetBodyXForm(0, pos.x, pos.y, dir);
    }
    public function UpdatePhysObj_Path_New() : Void
    {
        if (pathControlMode == 0)
        {
            UpdatePhysObj_Path_SetPos();
        }
        else if (pathControlMode == 1)
        {
            lineLoop = false;
            if (path_endmode == "loop")
            {
                lineLoop = true;
            }
            
            lineLinearPos += lineSpeed;
            
            if (path_endmode == "loop")
            {
                if (lineLinearPos > 1)
                {
                    lineLinearPos -= 1;
                }
                else if (lineLinearPos < 0)
                {
                    lineLinearPos += 1;
                }
            }
            else if (path_endmode == "bounce")
            {
                if (lineLinearPos > 1)
                {
                    lineLinearPos = 1;
                    lineSpeed *= -1;
                }
                else if (lineLinearPos < 0)
                {
                    lineLinearPos = 0;
                    lineSpeed *= -1;
                }
            }
            else if (path_endmode == "stop")
            {
                if (lineLinearPos > 1)
                {
                    lineLinearPos = 1;
                    pathControlMode = 0;
                }
                else if (lineLinearPos < 0)
                {
                    pathControlMode = 0;
                    lineLinearPos = 0;
                }
            }
            else if (path_endmode == "reset")
            {
                if (lineLinearPos > 1)
                {
                    lineLinearPos = 0;
                    pathControlMode = 0;
                }
                else if (lineLinearPos < 0)
                {
                    lineLinearPos = 1;
                    pathControlMode = 0;
                }
            }
            
            var line : EdLine = Levels.GetCurrent().lines[lineIndex];
            if (line == null)
            {
                return;
            }
            
            var p : Point = null;            
            
            
            
            var lp : Float = lineLinearPos;
            
            if (pathEaseName != null && pathEaseName != "" && pathEaseName != "linear")
            {
                lp = Ease.EaseByName(pathEaseName, lp, pathEaseValue);
            }
            
            if (lineLoop == true && lineSpline == false)
            {
                p = line.GetInterpolatedPoint_SegmentRatio(lp, lineLoop, lineSpline);
            }
            else
            {
                p = line.GetInterpolatedPoint_EqualSpacing(lp, lineLoop, lineSpline);
            }
            
            
            UpdatePhysObj_Path_SetPos();
        }
    }
}


