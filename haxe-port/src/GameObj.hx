import audioPackage.Audio;
import editorPackage.EdJoint;
import editorPackage.GameLayers;
import editorPackage.PhysEditor;
import flash.display.Graphics;
import flash.display.GraphicsPath;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.events.*;
import flash.filters.BlurFilter;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.*;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.media.SoundChannel;
import flash.ui.Mouse;
import licPackage.Lic;
import licPackage.LicDef;
import nape.callbacks.InteractionCallback;
import nape.constraint.AngleJoint;
import nape.constraint.Constraint;
import nape.constraint.DistanceJoint;
import nape.constraint.MotorJoint;
import nape.constraint.PivotJoint;
import nape.dynamics.Arbiter;
import nape.dynamics.ArbiterList;
import nape.dynamics.CollisionArbiter;
import nape.dynamics.Contact;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.shape.Circle;
import textPackage.TextRenderer;

class GameObj extends GameObjBase
{
    
    
    
    
    
    
    
    public function ShowHealthBar()
    {
        healthBarTimer = Std.int(Defs.fps * 1);
    }
    public function RenderHealthBar(_xoff : Int, _yoff : Int) : Void
    {
        if (healthBarTimer > 0)
        {
            var x : Float = (xpos + _xoff) - Game.camera.x;
            var y : Float = (ypos + _yoff) - Game.camera.y;
            
            
            if (false == false)
            {
                var rect : Rectangle = new Rectangle(x - 10, y, 20, 3);
                bd.fillRect(rect, 0xff000000);
                rect.width = Utils.ScaleTo(0, 20, 0, maxHealth, health);
                bd.fillRect(rect, 0xffff0000);
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    public var textMessage : String;
    public var textMessage1 : String;
    public function InitTextMessage(_message : String, _x : Float, _y : Float) : Void
    {
        textMessage = _message;
        
        updateFunction = UpdateTextMessage;
        renderFunction = RenderTextMessage;
        timer = 50;
        yvel = 0;
        zpos = -1000;
        yvel = 0;
        scale = 1;
        zvel = 0.1;
        alpha = 1;
    }
    public function RenderTextMessage()
    {
        var x : Float = xpos;
        var y : Float = ypos;
    }
    public function UpdateTextMessage()
    {
        yvel -= 0.02;
        ypos += yvel;
        
        timer--;
        if (timer <= 0)
        {
            timer = 0;
            RemoveObject();
        }
    }
    
    
    
    public function RenderScoreOverlay() : Void
    {
        RenderDispObjNormally();
    }
    public function UpdateScoreOverlay() : Void
    {
        yvel -= 0.002;
        ypos += yvel;
        
        scale += scaleVel;
        if (scale > 1)
        {
            scaleVel -= scaleAcc;
        }
        if (scale < 1)
        {
            scaleVel += scaleAcc;
        }
        scaleVel = Utils.LimitNumber(-scaleMax, scaleMax, scaleVel);
        scaleMax *= 0.95;
        if (scaleMax <= 0.01)
        {
            RemoveObject();
        }
    }
    public var scaleVel : Float;
    public var scaleAcc : Float;
    public var scaleMax : Float;
    public function InitScoreOverlay(_frame : Int) : Void
    {
        ypos -= 50;
        updateFunction = UpdateScoreOverlay;
        renderFunction = RenderScoreOverlay;
        timer = as3hx.Compat.parseInt(Defs.fps * 5.8);
        frame = _frame;
        dobj = GraphicObjects.GetDisplayObjByName("ScoreText");
        scale = 0;
        scaleVel = 0.1;
        scaleAcc = 0.01;
        scaleMax = 0.1;
    }
    
    
    public function InitMessage(_type : Int) : Void
    {
        updateFunction = UpdateMessage;
        timer = as3hx.Compat.parseInt(Defs.fps * 0.8);
        frame = _type;
        dobj = GraphicObjects.GetDisplayObjByName("StartRaceText");
    }
    public function UpdateMessage()
    {
        xpos = 320 + Game.camera.x;
        ypos = 100 + Game.camera.y;
        timer--;
        if (timer <= 0)
        {
            RemoveObject();
        }
    }
    
    
    
    
    
    
    
    
    
    public var physObjOffsetX : Float;
    public var physObjOffsetY : Float;
    public var physObjInitVarString : String;
    public function InitPhysicsObject(_gid : Int, _frame : Int, _offsetX : Float = 0, _offsetY : Float = 0, _initvarstring : String = "", _hasShadow : Bool = false)
    {  /*

			colFlag_isPhysObj = true;
			physObjOffsetX = _offsetX;
			physObjOffsetY = _offsetY;
			isPhysObj = true;
			dobj = GraphicObjects.GetDisplayObjByIndex(_gid);
			frame = _frame;
			updateFunction = UpdatePhysicsObject;
			renderShadowFlag = _hasShadow;
			physObjInitVarString = _initvarstring;
			*/  
        
        
    }
    public function UpdatePhysicsObject()
    {
    }
    
    
    
    public function SetMarkerPos(x : Float, y : Float)
    {
        if (visible == false)
        {
            xpos = x;
            ypos = y;
        }
        toPosX = x;
        toPosY = y;
        
        visible = true;
    }
    
    
    
    
    
    public function BossHitByBubble()
    {
        if (state == 0)
        {
            var soundName : String = "sfx_boss_hit" + Utils.RandBetweenInt(1, 3);
            SFX_OneShot(soundName);
            
            health--;
            if (health <= 0)
            {
                state = 2;
                SetAnimRangeSingle("defeated", true);
                RemovePhysObj();
                yvel = 0;
            }
            else
            {
                SetAnimRangeSingle("hit", true);
                state = 1;
            }
        }
    }
    public function UpdatePhysObj_Path_Boss()
    {
        if (state == 0)
        {
            UpdatePhysObj_Path();
            CycleAnimationEx();
        }
        else if (state == 1)
        {
            UpdatePhysObj_Path();
            Utils.print("state 1: " + frame);
            if (PlayAnimationEx())
            {
                state = 0;
                SetAnimRangeSingle("idle", true);
            }
        }
        else if (state == 2)
        {
            CycleAnimationEx();
            yvel += -1;
            ypos += yvel;
            if (ypos < -50)
            {
                RemoveObject();
                GameVars.bossDefeated = true;
            }
        }
        if (dobj1 != null)
        {
            CycleAnimation1();
        }
    }
    
    public function UpdatePhysObj_Boss()
    {
        if (state == 0)
        {
            CycleAnimationEx();
        }
        else if (state == 1)
        {
            Utils.print("state 1: " + frame);
            if (PlayAnimationEx())
            {
                state = 0;
                SetAnimRangeSingle("idle", true);
            }
        }
        else if (state == 2)
        {
            CycleAnimationEx();
            yvel += -1;
            ypos += yvel;
            if (ypos < -50)
            {
                RemoveObject();
                GameVars.bossDefeated = true;
            }
        }
        if (dobj1 != null)
        {
            CycleAnimation1();
        }
    }
    
    
    public function RenderPhysObj_Path_Boss()
    {
        RenderDispObjNormally();
        healthBarTimer = 1;
        RenderHealthBar(0, -40);
        if (dobj1 != null)
        {
            RenderDispObjAt(xpos, ypos + 40, dobj1, Std.int(frame1));
        }
    }
    public function InitPhysObj_Path_Boss_Tractor()
    {
        InitPhysObj_Path_Boss();
        dobj1 = GraphicObjects.GetDisplayObjByName("tractorBeam");
        frame1 = 0;
        frameVel1 = 1;
    }
    
    public function InitPhysObj_Path_Boss()
    {
        name = "boss";
        collisionType = "boss";
        InitPhysObj_Path();
        updateFunction = UpdatePhysObj_Path_Boss;
        renderFunction = RenderPhysObj_Path_Boss;
        SetAnimRangeSingle("idle", true);
        state = 0;
        health = maxHealth = 2;
        dobj1 = null;
    }
    
    public function InitPhysObj_Boss()
    {
        name = "boss";
        collisionType = "boss";
        updateFunction = UpdatePhysObj_Boss;
        renderFunction = RenderPhysObj_Path_Boss;
        SetAnimRangeSingle("idle", true);
        state = 0;
        health = maxHealth = 2;
        dobj1 = null;
    }
    
    
    
    public function InitPhysObj_Path_Virtual()
    {
        InitPhysObj_Path();
        visible = false;
        if (Game.usedebug)
        {
            visible = true;
        }
    }
    
    public function InitPhysObj_Path_Normal()
    {
        InitPhysObj_Path();
    }
    public function InitPhysObj_Path_Deadly()
    {
        InitPhysObj_Path();
        name = "death";
    }
    
    
    
    
    public var fillScreenMCListMiniMap : Array<Shape>;
    public var fillScreenMCList : Array<Shape>;
    public var fillScreenMC : Shape;
    public var fillScreenMCMiniMap : Shape;
    
    public var surfacePointsList0 : Array<Point>;
    public var surfacePointsList1 : Array<Point>;
    
    
    public function PreRenderPhysicsLineObject_Surface_PointsList()
    {
        surfacePointsList0 = [];
        surfacePointsList1 = [];
        
        fillScreenMC = new Shape();
        fillScreenMC.x = 0;
        fillScreenMC.y = 0;
        
        fillScreenMCList = [];
        fillScreenMCListMiniMap = [];
        
        var p0 : Point = null;        var p1 : Point = null;        var p2 : Point = null;        
        
        var num : Int = linkedPhysLine.points.length;
        
        for (i in 0...num)
        {
            var p : Point = linkedPhysLine.points[i];
            p0 = p.clone();
            p1 = p0.clone();
            p1.y += Utils.RandBetweenInt(20, 60);
            
            surfacePointsList0.push(p0);
            surfacePointsList1.push(p1);
        }
        
        s3dTriListIndex = -1;
    }
    
    public function RenderPhysicsLineObject_Surface_PointsList()
    {
        var xp : Float = Math.NaN;        var yp : Float = Math.NaN;        xp = Game.camera.x;
        yp = Game.camera.y;
        
        
        var g : Graphics = fillScreenMC.graphics;
        g.clear();
        
        gmat.identity();
        gmat.translate(-xp, -yp);
        
        g.lineStyle(null, null, 0);
        
        var len : Int = surfacePointsList0.length;
        var foundA : Bool = false;
        var foundB : Bool = false;
        
        var x0 : Int = Std.int(Game.camera.x);
        var x1 : Int = as3hx.Compat.parseInt(x0 + Defs.displayarea_w);
        
        var firstIndex : Int = 0;
        var lastIndex : Int = 100;
        
        for (i in 0...len)
        {
            if (foundA == false)
            {
                if (surfacePointsList0[i].x > x0)
                {
                    foundA = true;
                    firstIndex = as3hx.Compat.parseInt(i - 1);
                }
            }
            if (foundB == false)
            {
                if (surfacePointsList0[i].x > x1)
                {
                    foundB = true;
                    lastIndex = i;
                }
            }
        }
        
        firstIndex = Std.int(Utils.LimitNumber(0, len - 1, firstIndex));
        lastIndex = Std.int(Utils.LimitNumber(0, len - 1, lastIndex));
        
        
        
        
        
        
        var p0 : Point = new Point();
        var p1 : Point = new Point();
        var p2 : Point = new Point();
        var p3 : Point = new Point();
        var p4 : Point = new Point();
        var p5 : Point = new Point();
        
        var bottom : Int = Defs.displayarea_h;
        
        if (true)
        {
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), gmat, true);
            
            p0 = surfacePointsList0[firstIndex];
            g.moveTo(p0.x - xp, p0.y - yp);
            for (index in firstIndex...lastIndex + 1)
            {
                p0 = surfacePointsList0[index];
                g.lineTo(p0.x - xp, p0.y - yp);
            }
            var index : Int = lastIndex;
            while (index >= 0)
            {
                p0 = surfacePointsList1[index];
                g.lineTo(p0.x - xp, p0.y - yp);
                index--;
            }
            g.endFill();
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame + 1)), gmat, true);
            
            p0 = surfacePointsList1[firstIndex];
            g.moveTo(p0.x - xp, p0.y - yp);
            for (index in firstIndex...lastIndex + 1)
            {
                p0 = surfacePointsList1[index];
                g.lineTo(p0.x - xp, p0.y - yp);
            }
            p0 = surfacePointsList1[lastIndex];
            g.lineTo(p0.x - xp, bottom);
            p0 = surfacePointsList1[firstIndex];
            g.lineTo(p0.x - xp, bottom);
            g.endFill();
        }
        else
        {
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), gmat, true);
            for (index in firstIndex...lastIndex + 1)
            {
                p0 = surfacePointsList0[index];
                p1 = surfacePointsList1[index];
                
                p3 = surfacePointsList0[index + 1];
                p4 = surfacePointsList1[index + 1];
                
                g.moveTo(p0.x - xp, p0.y - yp);
                g.lineTo(p3.x - xp, p3.y - yp);
                g.lineTo(p4.x - xp, p4.y - yp);
                g.lineTo(p1.x - xp, p1.y - yp);
            }
            g.endFill();
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame + 1)), gmat, true);
            for (index in firstIndex...lastIndex + 1)
            {
                p0 = surfacePointsList1[index];
                p2.x = p0.x;
                
                p3 = surfacePointsList1[index + 1];
                p5.x = p3.x;
                
                g.moveTo(p0.x - xp, p0.y - yp);
                g.lineTo(p3.x - xp, p3.y - yp);
                g.lineTo(p5.x - xp, bottom);
                g.lineTo(p2.x - xp, bottom);
            }
            g.endFill();
        }
        
        /*
			g.beginBitmapFill(dobj.GetBitmapData(frame+1), null, true);
			var p0:Point = newpoints1[0];
			g.moveTo(p0.x, p0.y);
			for (var i:int = 1; i < newpoints1.length; i++)
			{
				var p0:Point = newpoints1[i];
				g.lineTo(p0.x, p0.y);
			}


			var p0:Point = newpoints2[newpoints2.length - 1];
			g.lineTo(p0.x, p0.y);
			var p0:Point = newpoints2[0];
			g.lineTo(p0.x, p0.y);
			*/
        
        p0 = surfacePointsList0[firstIndex];
        g.moveTo(p0.x - xp, p0.y - yp);
        g.lineStyle(4, 0x0, 1);
        g.lineBitmapStyle(dobj1.GetBitmapData(Std.int(frame)), null);
        for (index in firstIndex...lastIndex + 1)
        {
            var p0 : Point = surfacePointsList0[index];
            g.lineTo(p0.x - xp, p0.y - yp);
        }
        
        
        
        
        bd.draw(fillScreenMC);
    }
    
    
    public function RenderPhysicsLineObject_Surface_PointsList_Minimap()
    {
        var xp : Float = Math.NaN;        var yp : Float = Math.NaN;        xp = Game.camera.x;
        yp = Game.camera.y;
        
        
        var g : Graphics = fillScreenMC.graphics;
        g.clear();
        
        gmat.identity();
        gmat.translate(-xp, -yp);
        
        g.lineStyle(null, null, 0);
        
        var len : Int = surfacePointsList0.length;
        var foundA : Bool = false;
        var foundB : Bool = false;
        
        var x0 : Int = Std.int(Game.camera.x);
        var x1 : Int = as3hx.Compat.parseInt(x0 + Defs.displayarea_w * 3);
        
        var firstIndex : Int = 0;
        var lastIndex : Int = 0;
        
        for (i in 0...len)
        {
            if (foundA == false)
            {
                if (surfacePointsList0[i].x > x0)
                {
                    foundA = true;
                    firstIndex = as3hx.Compat.parseInt(i - 1);
                }
            }
            if (foundB == false)
            {
                if (surfacePointsList0[i].x > x1)
                {
                    foundB = true;
                    lastIndex = i;
                }
            }
        }
        
        firstIndex = Std.int(Utils.LimitNumber(0, len - 1, firstIndex));
        lastIndex = Std.int(Utils.LimitNumber(0, len - 1, lastIndex));
        
        if (lastIndex <= firstIndex)
        {
            lastIndex = as3hx.Compat.parseInt(len - 1);
        }
        
        
        
        
        
        
        var p0 : Point = new Point();
        var p1 : Point = new Point();
        var p2 : Point = new Point();
        var p3 : Point = new Point();
        var p4 : Point = new Point();
        var p5 : Point = new Point();
        
        var bottom : Int = Defs.displayarea_h;
        
        
        g.lineStyle(1, 0xffffff, 1);
        p0 = surfacePointsList0[firstIndex];
        var x : Float = (p0.x - xp) * 0.1;
        var y : Float = (p0.y - yp) * 0.1;
        g.moveTo(x, y);
        for (index in firstIndex...lastIndex + 1)
        {
            var p0 : Point = surfacePointsList0[index];
            
            var x : Float = (p0.x - xp) * 0.1;
            var y : Float = (p0.y - yp) * 0.1;
            
            g.lineTo(x, y);
        }
        bd.draw(fillScreenMC);
    }
    
    
    public function PreRenderPhysicsLineObject_Surface_MultiPartAAAAA()
    {
        fillScreenMCList = [];
        fillScreenMCListMiniMap = [];
        
        var p0 : Point = null;        var p1 : Point = null;        var p2 : Point = null;        
        
        var numSegs : Int = 60;
        
        var num : Int = linkedPhysLine.points.length;
        var totalw : Int = as3hx.Compat.parseInt(linkedPhysLine.points[num - 1].x - linkedPhysLine.points[0].x);
        
        numSegs = as3hx.Compat.parseInt(totalw / 300);
        
        
        for (seg in 0...numSegs)
        {
            var newpoints : Array<Dynamic> = [];
            var newpoints1 : Array<Dynamic> = [];
            var newpoints2 : Array<Dynamic> = [];
            
            var aa : Int = as3hx.Compat.parseInt(num / numSegs);
            var first : Int = as3hx.Compat.parseInt(seg * aa);
            var last : Int = as3hx.Compat.parseInt(first + aa);
            
            
            if (last >= num)
            {
                last = num;
            }
            
            
            for (i in first...last + 1)
            {
                var p : Point = linkedPhysLine.points[i];
                p0 = p.clone();
                p1 = p0.clone();
                p1.y += Utils.RandBetweenInt(20, 60);
                p2 = p0.clone();
                p2.y += 1000;
                newpoints.push(p0);
                newpoints1.push(p1);
                newpoints2.push(p2);
            }
            
            
            
            
            
            fillScreenMC = new Shape();
            fillScreenMC.x = 0;
            fillScreenMC.y = 0;
            
            fillScreenMCMiniMap = new Shape();
            fillScreenMCMiniMap.x = 0;
            fillScreenMCMiniMap.y = 0;
            
            var g : Graphics = fillScreenMC.graphics;
            g.clear();
            
            g.lineStyle(null, null, 0);
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), null, true);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            var i : Int = as3hx.Compat.parseInt(newpoints1.length - 1);
            while (i >= 0)
            {
                var p0 : Point = newpoints1[i];
                g.lineTo(p0.x, p0.y);
                i--;
            }
            g.endFill();
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame + 1)), null, true);
            var p0 : Point = newpoints1[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints1.length)
            {
                var p0 : Point = newpoints1[i];
                g.lineTo(p0.x, p0.y);
            }
            
            var p0 : Point = newpoints2[newpoints2.length - 1];
            g.lineTo(p0.x, p0.y);
            var p0 : Point = newpoints2[0];
            g.lineTo(p0.x, p0.y);
            
            /*
				for (var i:int = newpoints2.length - 1; i >= 0; i--)
				{
					var p0:Point = newpoints2[i];
					g.lineTo(p0.x, p0.y);
				}
				*/
            g.endFill();
            
            
            
            g.lineStyle(4, 0x0, 1);
            g.lineBitmapStyle(dobj1.GetBitmapData(Std.int(frame)), null);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            
            fillScreenMCList.push(fillScreenMC);
            
            var g : Graphics = fillScreenMCMiniMap.graphics;
            g.clear();
            g.lineStyle(7, 0xffffff, 1);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            
            fillScreenMCListMiniMap.push(fillScreenMCMiniMap);
        }
    }
    
    
    public function PreRenderPhysicsLineObject_Surface()
    {
        var newpoints : Array<Dynamic> = [];
        var newpoints1 : Array<Dynamic> = [];
        var newpoints2 : Array<Dynamic> = [];
        var p0 : Point = null;        var p1 : Point = null;        var p2 : Point = null;        
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(linkedPhysLine),points) type: null */ in linkedPhysLine.points)
        {
            p0 = p.clone();
            p1 = p0.clone();
            p1.y += Utils.RandBetweenInt(20, 60);
            p2 = p0.clone();
            p2.y += 600;
            newpoints.push(p0);
            newpoints1.push(p1);
            newpoints2.push(p2);
        }
        
        
        
        
        if (true)
        {
            fillScreenMCMiniMap = new Shape();
            fillScreenMC = new Shape();
            fillScreenMCMiniMap.x = 0;
            fillScreenMCMiniMap.y = 0;
            fillScreenMC.x = 0;
            fillScreenMC.y = 0;
            
            var g : Graphics = fillScreenMC.graphics;
            g.clear();
            
            g.lineStyle(null, null, 0);
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), null, true);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            var i : Int = as3hx.Compat.parseInt(newpoints1.length - 1);
            while (i >= 0)
            {
                var p0 : Point = newpoints1[i];
                g.lineTo(p0.x, p0.y);
                i--;
            }
            g.endFill();
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame + 1)), null, true);
            var p0 : Point = newpoints1[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints1.length)
            {
                var p0 : Point = newpoints1[i];
                g.lineTo(p0.x, p0.y);
            }
            var i : Int = as3hx.Compat.parseInt(newpoints2.length - 1);
            while (i >= 0)
            {
                var p0 : Point = newpoints2[i];
                g.lineTo(p0.x, p0.y);
                i--;
            }
            g.endFill();
            
            
            
            g.lineStyle(4, 0x0, 1);
            g.lineBitmapStyle(dobj1.GetBitmapData(Std.int(frame)), null);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            
            var g : Graphics = fillScreenMCMiniMap.graphics;
            g.clear();
            g.lineStyle(7, 0xffffff, 1);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
        }
    }
    
    
    public function PreRenderPhysicsLineObject_Background()
    {
        var newpoints : Array<Dynamic> = [];
        var newpoints1 : Array<Dynamic> = [];
        var newpoints2 : Array<Dynamic> = [];
        var p0 : Point = null;        var p1 : Point = null;        var p2 : Point = null;        
        for (p/* AS3HX WARNING could not determine type for var: p exp: EField(EIdent(linkedPhysLine),points) type: null */ in linkedPhysLine.points)
        {
            p0 = p.clone();
            newpoints.push(p0);
        }
        
        
        
        
        if (true)
        {
            fillScreenMC = new Shape();
            fillScreenMC.x = 0;
            fillScreenMC.y = 0;
            
            var g : Graphics = fillScreenMC.graphics;
            g.clear();
            
            g.lineStyle(null, null, 0);
            
            g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), null, true);
            var p0 : Point = newpoints[0];
            g.moveTo(p0.x, p0.y);
            for (i in 1...newpoints.length)
            {
                var p0 : Point = newpoints[i];
                g.lineTo(p0.x, p0.y);
            }
            g.endFill();
        }
    }
    
    
    public function RenderPhysicsLineObject_Surface_MiniMap()
    {
    }
    
    public function RenderPhysicsLineObject_Surface_MiniMap_MultiPart()
    {
    }
    
    
    public function RenderPhysicsLineObject_Surface_MultiPart()
    {
        var sx : Float = Math.round(Game.camera.x);
        var sy : Float = Math.round(Game.camera.y);
        
        var xadd : Float = xpos - sx;
        var yadd : Float = ypos - sy;
        
        var xp : Float = Math.NaN;        var yp : Float = Math.NaN;        xp = xpos - Game.camera.x;
        yp = ypos - Game.camera.y;
        
        gmat.identity();
        gmat.translate(xp, yp);
        
        for (fillScreenMC in fillScreenMCList)
        {
            var r0 : Rectangle = fillScreenMC.getBounds(null);
            var r1 : Rectangle = fillScreenMC.getRect(null);
            
            
            if (r0.x > Game.camera.x + Defs.displayarea_w)
            {
            }
            else if (r0.right < Game.camera.x)
            {
            }
            else
            {
                bd.draw(fillScreenMC, gmat, null, null, bd.rect, false);
            }
        }
    }
    
    public function RenderPhysicsLineObject_Surface()
    {
        var sx : Float = Math.round(Game.camera.x);
        var sy : Float = Math.round(Game.camera.y);
        
        var xadd : Float = xpos - sx;
        var yadd : Float = ypos - sy;
        
        var xp : Float = Math.NaN;        var yp : Float = Math.NaN;        xp = xpos - Game.camera.x;
        yp = ypos - Game.camera.y;
        
        
        
        if (true)
        {
            gmat.identity();
            gmat.translate(xp, yp);
            bd.draw(fillScreenMC, gmat, null, null, bd.rect, true);
        }
    }
    
    
    public function InitGameObjLine_Surface()
    {
        name = "surface";
        state = 0;
        renderFunction = RenderPhysicsLineObject_Surface_PointsList;
        
        dobj1 = GraphicObjects.GetDisplayObjByName("SurfaceFills");
        
        PreRenderPhysicsLineObject_Surface_PointsList();
        miniMapRenderFunction = RenderPhysicsLineObject_Surface_PointsList_Minimap;
        zpos = 0;
    }
    
    public function InitGameObjLine_Background()
    {
        name = "background";
        state = 0;
        renderFunction = RenderPhysicsLineObject_Surface;
        dobj1 = GraphicObjects.GetDisplayObjByName("SurfaceFills");
        PreRenderPhysicsLineObject_Background();
        zpos = 1000;
    }
    
    
    
    
    
    
    
    
    public function InitGameObjLine_Null()
    {
        lineRender_Color0 = 0x000000;
        lineRender_Color1 = 0xff0000;
        lineRender_Color = 0xa0a0a0;
        
        frame = 0;
    }
    
    
    public function InitPhysObj_Death()
    {
        health = maxHealth = 100;
        name = "death";
        collisionType = "killzombie_all";
    }
    
    public function InitGameObjLine_Sticky()
    {
        name = "sticky";
        Utils.print("InitGameObjLine_Sticky");
        state = 0;
        lineRender_Color = 0xff0000;
        lineRender_Color0 = 0x008000;
        lineRender_Color1 = 0x00ff00;
        
        frame = 3;
    }
    
    
    
    
    public function PreRenderPhysicsLineObject_Movable()
    {
        if (false == false)
        {
            return;
        }
        
        linkedPhysLine.DoTriangulation();
        
        if (linkedPhysLine.triangleList == null)
        {
            return;
        }
    }
    
    
    
    
    public function RenderPhysicsLineObject_Movable()
    {
        var x : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var y : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        var g : Graphics = Game.fillScreenMC.graphics;
        g.clear();
        
        var sx : Float = Math.round(Game.camera.x);
        var sy : Float = Math.round(Game.camera.y);
        
        var z : Int = Std.int(zpos);
        
        
        var p0 : Point = null;        var p1 : Point = null;        
        var newpoints : Array<Dynamic> = [];
        
        gmat.identity();
        gmat.rotate(dir);
        
        
        
        var sc : Float = Game.camera.scale;
        
        var r : Rectangle = new Rectangle(0, 0, 1, 1);
        
        var pts : Array<Dynamic> = linkedPhysLine.points;
        if (linkedPhysLine.IsSpline())
        {
            pts = linkedPhysLine.GetCatmullRomPointsList(linkedPhysLine.points, 0, 0);
        }
        
        
        var index : Int = 0;
        for (p in pts)
        {
            p0 = p.clone();
            p0.x -= linkedPhysLine.centrex;
            p0.y -= linkedPhysLine.centrey;
            p0 = gmat.transformPoint(p0);
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
        
        
        gmat.identity();
        gmat.rotate(dir);
        gmat.translate(xpos, ypos);
        gmat.translate(-sx, -sy);
        
        
        
        g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), gmat, true);
        
        if (dobj2 == null)
        {
            g.lineStyle(null, null, null);
        }
        else
        {
            g.lineStyle(3, 0x404040, 1);
            
            g.lineBitmapStyle(dobj2.GetBitmapData(Std.int(frame)), gmat, true);
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
        
        
        
        bd.draw(Game.fillScreenMC, null, null, null, null, false);
    }
    
    
    public var staticLinePoints : Array<Point>;
    public var staticLineRectangle : Rectangle;
    public function PreRenderPhysicsLineObject_Static()
    {
        staticLinePoints = [];
        
        var pts : Array<Dynamic> = linkedPhysLine.points;
        if (linkedPhysLine.IsSpline())
        {
            pts = linkedPhysLine.GetCatmullRomPointsList(linkedPhysLine.points, 0, 0);
        }
        
        var p0 : Point = null;        var index : Int = 0;
        for (p in pts)
        {
            p0 = p.clone();
            p0.x -= linkedPhysLine.centrex;
            p0.y -= linkedPhysLine.centrey;
            
            p0.x += xpos;
            p0.y += ypos;
            
            
            
            
            staticLinePoints.push(p0);
            
            if (index == 0)
            {
                staticLineRectangle = new Rectangle(p0.x, p0.y, 1, 1);
            }
            else
            {
                if (p0.x < staticLineRectangle.left)
                {
                    staticLineRectangle.left = p0.x;
                }
                if (p0.x > staticLineRectangle.right)
                {
                    staticLineRectangle.right = p0.x;
                }
                if (p0.y < staticLineRectangle.top)
                {
                    staticLineRectangle.top = p0.y;
                }
                if (p0.y > staticLineRectangle.bottom)
                {
                    staticLineRectangle.bottom = p0.y;
                }
            }
            index++;
        }
    }

    // Per-object scratch bitmap for compositing this terrain object's vector fill into the GPU tile
    // stream (see RenderFillAsTile). Lazily allocated, re-uploaded each frame (OpenFL getTexture
    // honours image.version). Each terrain object needs its OWN bitmap so concurrent tiles don't alias.
    public var lineFillBD : BitmapData = null;

    // PERF (Settings.cachedTerrain): static terrain doesn't change shape — only the camera moves. So
    // rasterize this object's vector fill ONCE, into a bitmap sized to its world bbox, then each frame
    // just push that cached bitmap as a tile at (worldOrigin - camera). Because the BitmapData is never
    // re-drawn, its image.version is stable and OpenFL uploads its GPU texture only once (no per-frame
    // texImage2D — the iOS stall). cachedTerrainFail = bbox too big to cache → per-frame fallback.
    public var cachedTerrainBD : BitmapData = null;
    public var cachedTerrainX : Float = 0;
    public var cachedTerrainY : Float = 0;
    public var cachedTerrainFail : Bool = false;

    // GameObj instances are POOLED and recycled across levels (GameObjects.AddObj). The terrain
    // rasterisation cache lives on the instance, so it MUST be dropped on recycle — otherwise a
    // reused object renders the PREVIOUS level's terrain (background artifacts bleed between levels).
    public function ResetTerrainCache() : Void
    {
        if (cachedTerrainBD != null) { cachedTerrainBD.dispose(); cachedTerrainBD = null; }
        cachedTerrainFail = false;
    }

    // Z-ORDER FIX: emit the current Game.fillScreenMC vector terrain as a GPU tile at THIS object's
    // zpos slot, instead of `bd.draw`-ing it into the software underlay. The old underlay path forced
    // ALL terrain behind ALL sprites (two fixed depth bands), so things that should hide behind terrain
    // (trophy behind grass, clouds behind foreground dirt) rendered in front. Pushed here, the terrain
    // tile lands in TileRenderer's zpos-ordered stream and interleaves with sprites correctly.
    public function RenderFillAsTile(matrix : Matrix = null, clipRect : Rectangle = null, smoothing : Bool = false) : Void
    {
        if (lineFillBD == null) lineFillBD = new BitmapData(Defs.displayarea_w, Defs.displayarea_h, true, 0);
        lineFillBD.fillRect(lineFillBD.rect, 0);
        lineFillBD.draw(Game.fillScreenMC, matrix, null, null, clipRect, smoothing);
        TileRenderer.PushAt(lineFillBD, 0, 0);
    }

    public function RenderPhysicsLineObject_Static()
    {
        if (staticLineRectangle.right < Game.camera.x)
        {
            return;
        }
        if (staticLineRectangle.left > (Game.camera.x + Defs.displayarea_w))
        {
            return;
        }
        if (staticLineRectangle.bottom < Game.camera.y)
        {
            return;
        }
        if (staticLineRectangle.top > (Game.camera.y + Defs.displayarea_h))
        {
            return;
        }

        // PERF FIX: cache-once path. Rasterise the shape once (camera-independent), then every frame
        // just re-position the cached tile — no per-frame full-screen bitmap re-upload (the iOS stall).
        if (Settings.cachedTerrain && !cachedTerrainFail)
        {
            if (cachedTerrainBD == null) BuildTerrainCache(); // may set cachedTerrainFail if bbox is huge
            if (cachedTerrainBD != null)
            {
                TileRenderer.PushAt(cachedTerrainBD,
                    Math.round(cachedTerrainX - Game.camera.x),
                    Math.round(cachedTerrainY - Game.camera.y));
                return;
            }
            // bbox too big to cache → fall through to the original per-frame render below
        }

        var x : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var y : Float = Math.round(ypos) - Math.round(Game.camera.y);

        var g : Graphics = Game.fillScreenMC.graphics;
        g.clear();
        
        var sx : Float = Math.round(Game.camera.x);
        var sy : Float = Math.round(Game.camera.y);
        
        var z : Int = Std.int(zpos);
        
        
        var p0 : Point = null;        var p1 : Point = null;        
        gmat.identity();
        gmat.rotate(dir);
        gmat.translate(xpos, ypos);
        gmat.translate(-sx, -sy);
        
        
        
        g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), gmat, true);
        
        if (dobj2 == null)
        {
            g.lineStyle(null, null, null);
        }
        else
        {
            g.lineStyle(3, 0x404040, 1);
            
            g.lineBitmapStyle(dobj2.GetBitmapData(0), gmat, true);
        }
        
        var pts : Array<Point> = staticLinePoints;
        
        g.moveTo(pts[0].x - sx, pts[0].y - sy);
        for (i in 1...pts.length)
        {
            g.lineTo(pts[i].x - sx, pts[i].y - sy);
        }
        g.lineTo(pts[0].x - sx, pts[0].y - sy);
        g.endFill();
        
        
        
        RenderFillAsTile(null, null, false); // was bd.draw into the underlay; now a tile at this object's zpos
    }

    // Build the once-only cached rasterisation used by the Settings.cachedTerrain fast path. Draws the
    // exact same fill the per-frame path draws, but in LOCAL (bbox-relative) coordinates — the camera and
    // bbox origin both cancel out of the bitmap-fill texture mapping, so this is pixel-identical to the
    // per-frame render. The result is uploaded to the GPU once and reused (stable image.version).
    function BuildTerrainCache() : Void
    {
        if (staticLineRectangle == null || staticLinePoints == null || staticLinePoints.length == 0)
        {
            cachedTerrainFail = true;
            return;
        }

        var bx : Float = Math.floor(staticLineRectangle.left) - 2;
        var by : Float = Math.floor(staticLineRectangle.top) - 2;
        var bw : Int = Std.int(Math.ceil(staticLineRectangle.right - bx)) + 2;
        var bh : Int = Std.int(Math.ceil(staticLineRectangle.bottom - by)) + 2;
        if (bw < 1) bw = 1;
        if (bh < 1) bh = 1;
        if (bw > 4096 || bh > 4096) { cachedTerrainFail = true; return; } // too big to cache — per-frame path

        cachedTerrainX = bx;
        cachedTerrainY = by;
        cachedTerrainBD = new BitmapData(bw, bh, true, 0);

        var g : Graphics = Game.fillScreenMC.graphics;
        g.clear();

        var m : Matrix = new Matrix();
        m.rotate(dir);
        m.translate(xpos, ypos);
        m.translate(-bx, -by);

        g.beginBitmapFill(dobj.GetBitmapData(Std.int(frame)), m, true);
        if (dobj2 == null)
        {
            g.lineStyle(null, null, null);
        }
        else
        {
            g.lineStyle(3, 0x404040, 1);
            g.lineBitmapStyle(dobj2.GetBitmapData(0), m, true);
        }

        var pts : Array<Point> = staticLinePoints;
        g.moveTo(pts[0].x - bx, pts[0].y - by);
        for (i in 1...pts.length)
        {
            g.lineTo(pts[i].x - bx, pts[i].y - by);
        }
        g.lineTo(pts[0].x - bx, pts[0].y - by);
        g.endFill();

        cachedTerrainBD.draw(Game.fillScreenMC, null, null, null, null, false);
        g.clear(); // leave the shared scratch MC empty for the next object
    }


    public function RenderGrass()
    {
        if (GameVars.renderDebugMode == 1)
        {
            return;
        }
        Grass.RenderAll(bd);
    }
    public function UpdateGrass()
    {
        Grass.Update();
    }
    public function InitGrass()
    {
        updateFunction = UpdateGrass;
        renderFunction = RenderGrass;
        zpos = 1;
    }
    
    
    public function InitGameObjLine_Movable()
    {
        InitGameObjLine_Standard();
        name = "movable";
        preRenderFunction = null;
        
        renderFunction = RenderPhysicsLineObject_Static;
    }
    public function InitGameObjLine_Standard_KeepActive()
    {
        InitGameObjLine_Standard();
        keepAwakeFunction = KeepAwake_Constant;
    }
    
    public function InitGameObjLine_Path()
    {
        RemoveObject();
    }
    
    public function InitGameObjLine_Death()
    {
        InitGameObjLine_Standard();
        collisionType = "death";
    }
    public function DoNoRender()
    {
    }
    public function InitGameObjLine_Standard()
    {
        collisionType = "normal";
        preRenderFunction = null;
        
        renderFunction = RenderPhysicsLineObject_Static;
        
        PreRenderPhysicsLineObject_Static();
        
        frame = GameVars.grassFrame;
        
        dobj1 = GraphicObjects.GetDisplayObjByName("grass_rough");
        grassName = "grass_rough";
        
        preRenderFunction1 = PreRenderPhysicsLineObject_Movable_GrassSurface;
        name = "border";
        state = 0;
        
        dobj2 = GraphicObjects.GetDisplayObjByName("FillEdge");
    }
    
    public function InitGameObjLine_Mud()
    {
        collisionType = "normal";
        preRenderFunction = null;
        renderFunction = RenderPhysicsLineObject_Static;
        PreRenderPhysicsLineObject_Static();
        
        dobj2 = GraphicObjects.GetDisplayObjByName("FillSoilEdge");
        
        frame = GameVars.dirtFrame;
        
        state = 0;
    }
    public function InitGameObjLine_Decor()
    {
        collisionType = "normal";
        preRenderFunction = null;
        renderFunction = RenderPhysicsLineObject_Static;
        PreRenderPhysicsLineObject_Static();
        state = 0;
        dobj2 = null;
        frame = GameVars.dirtFrame;
    }
    
    public var grassName : String;
    
    public function PreRenderPhysicsLineObject_Movable_GrassSurface()
    {
        var newPoints : Array<Dynamic> = linkedPhysLine.points;
        var p0 : Point = null;        var p1 : Point = null;        
        for (i in 0...newPoints.length - 1)
        {
            p0 = newPoints[i].clone();
            p1 = newPoints[i + 1].clone();
            
            Grass.AddLine(p0, p1, grassName);
        }
    }
    
    public function InitGameObjLine_UpperSurface()
    {
        renderFunction = RenderPhysicsLineObject_Movable;
        name = "grass";
        state = 0;
    }
    
    public function InitGameObjLine_Grassy()
    {
        InitGameObjLine_Wood();
    }
    public function InitGameObjLine_Wood()
    {
        name = "grass";
        Utils.print("InitGameObjLine_Wood");
        state = 0;
        frame = 1;
        SetPolysMaterial_Nape("average");
        Utils.GetParams(initParams);
        
        frame = linkedPhysLine.objParameters.GetValueInt("line_background_frame", 1);
        frame--;
        frame = Utils.LimitNumber(0, dobj.GetNumFrames() - 1, frame);
        
        lineRender_Color = 0x2B4314;
    }
    public function InitGameObjLine_Smooth()
    {
        Utils.print("InitGameObjLine_Smooth");
        state = 0;
        frame = 2;
        SetPolysMaterial_Nape("smooth");
    }
    public function InitGameObjLine_Bouncy()
    {
        Utils.print("InitGameObjLine_Bouncy");
        state = 0;
        frame = 2;
        SetPolysMaterial_Nape("bouncy");
    }
    public function InitGameObjLine_Icy()
    {
        Utils.print("InitGameObjLine_Icy");
        state = 0;
        frame = 3;
        SetPolysMaterial_Nape("smooth");
    }
    
    
    
    public function InitGameObjLine_NonCollision()
    {
        SetBodyCollisionMask(0, 0);
    }
    
    public function InitGameObjLine_ScrollArea()
    {
        visible = false;
        
        linkedPhysLine.CalcBoundingRectangle();
        Game.boundingRectangle = linkedPhysLine.boundingRectangle.clone();
    }
    
    
    public function InitGameObjLine_Invisible()
    {
        visible = false;
    }
    
    
    
    public function InitGameObjLine_Switch_Hit(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return false;
        }
        if (state != 0)
        {
            return false;
        }
        if (goHitter.collisionType != "football" && goHitter.collisionType != "beachball")
        {
            return false;
        }
        state = 1;
        onHitFunction = null;
        return true;
    }
    public function InitGameObjLine_Switch()
    {
        name = "invisible_switch";
        
        
        onHitFunction = InitGameObjLine_Switch_Hit;
        updateFunction = UpdateSwitchOnce;
        
        state = 0;
        visible = false;
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    public function RenderPhysObj_Generic()
    {
        RenderDispObjNormally();
    }
    
    
    
    
    
    
    
    
    
    
    public function RenderBackground()
    {
    }
    
    public function UpdateBackground()
    {
        timer--;
        if (timer <= 0)
        {
            timer = 0;
        }
    }
    public function InitBackground()
    {
        renderFunction = RenderBackground;
        updateFunction = UpdateBackground;
        
        var level : Level = Levels.GetCurrent();
        dobj = GraphicObjects.GetDisplayObjByName("backgrounds");
        
        
        frame = as3hx.Compat.parseInt((Levels.currentIndex) % dobj.GetNumFrames());
        xpos = ypos = 0;
    }
    
    
    
    
    
    public function RenderPolyLayer()
    {
    }
    public function UpdatePolyLayer()
    {
    }
    public function InitPolyLayer()
    {
        updateFunction = UpdatePolyLayer;
        renderFunction = RenderPolyLayer;
    }
    
    
    
    
    
    
    
    
    
    public function OnHitDoorSwitch(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
    }
    public function onSwitchedDoorSwitch()
    {
    }
    
    
    
    public function TryLinkedDoorSwtiches()
    {
        if (doorSwitch_linkid == 0)
        {
            return;
        }
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameObjects),objs) type: null */ in GameObjects.objs)
        {
            if (go.active && (go.name == "doorswitch") && (go.doorSwitch_linkid == doorSwitch_linkid))
            {
                if (go != this)
                {
                    go.OnClickedDoorSwitch_Inner();
                }
            }
        }
    }
    
    
    public function OnClickedDoorSwitch()
    {
        OnClickedDoorSwitch_Inner();
        TryLinkedDoorSwtiches();
    }
    
    public function OnClickedDoorSwitch_Inner()
    {
        if (doorSwitch_2Way)
        {
            if (state == 0)
            {
                state = 1;
            }
            else
            {
                state = 0;
            }
        }
        else if (doorSwitch_ccw)
        {
            if (state != 1)
            {
            }
            state = 0;
        }
        else
        {
            if (state != 0)
            {
            }
            state = 1;
        }
    }
    
    public function UpdateDoorSwitch()
    {
        var b : Body = GetBody(0);
        b.type = BodyType.KINEMATIC;
        
        if (doorSwitch_parentGO != null)
        {
            SetBodyXForm(0, doorSwitch_parentGO.xpos + doorSwitch_parentOffsetX, doorSwitch_parentGO.ypos + doorSwitch_parentOffsetY, 0);
        }
        
        
        var v : Float = doorSwitch_rotvel;
        
        rotVel = 0;
        if (state == 0)
        {
            rotVel = -v;
        }
        else if (state == 1)
        {
            rotVel = v;
        }
        
        
        var a : Float = GetBodyAngle(0);
        if ((rotVel < 0) && (a <= minAng + origAng))
        {
            rotVel = 0;
            SetBodyAngle(0, minAng + origAng);
        }
        if ((rotVel > 0) && (a >= maxAng + origAng))
        {
            rotVel = 0;
            SetBodyAngle(0, maxAng + origAng);
        }
        b.angularVel = rotVel;
        
        if (doorSwitch_parentGO == null)
        {
            b.position.setxy(startx, starty);
        }
    }
    
    
    public function AddJoint_Nape(joint : EdJoint)
    {
        PhysicsBase.AddJoint_Nape(joint);
    }
    
    public var minAng : Float;
    public var maxAng : Float;
    public var origAng : Float;
    public var doorSwitch_angAdd : Float;
    public var doorSwitch_rotvel : Float;
    public var doorSwitch_2Way : Bool;
    public var doorSwitch_ccw : Bool;
    public var doorSwitch_linkid : Int = 0;
    public var doorSwitch_parentGO : GameObj;
    public var doorSwitch_parentOffsetX : Float;
    public var doorSwitch_parentOffsetY : Float;
    public function InitDoorSwitch()
    {
        name = "doorswitch";
        
        var s : String = "uidig_";
        for (i in 0...6)
        {
            s += Utils.RandBetweenInt(0, 99);
        }
        id = s;
        
        Utils.GetParams(initParams);
        
        doorSwitch_angAdd = Utils.GetParamNumber("doorswitch_openangle", 0);
        doorSwitch_2Way = Utils.GetParamBool("doorswitch_2way", false);
        doorSwitch_ccw = Utils.GetParamBool("doorswitch_ccw", false);
        doorSwitch_linkid = Utils.GetParamInt("doorswitch_linkid", 0);
        doorSwitch_rotvel = Utils.GetParamInt("doorswitch_rotvel", 6);
        doorSwitch_angAdd = Utils.DegToRad(doorSwitch_angAdd);
        var switch_linkName : String = Utils.GetParamString("doorswitch_link", "");
        
        if (switch_linkName != "")
        {
            doorSwitch_parentGO = GameObjects.GetGameObjById(switch_linkName);
            SetBodyXForm_Immediate(0, doorSwitch_parentGO.xpos, doorSwitch_parentGO.ypos, 0);
            useMultiplePhysicsUpdates = true;
            
            
            if (doorSwitch_parentGO == null)
            {
                Utils.print("ERROR, can't find " + switch_linkName);
            }
            else
            {
                doorSwitch_parentOffsetX = xpos - doorSwitch_parentGO.xpos;
                doorSwitch_parentOffsetY = ypos - doorSwitch_parentGO.ypos;
            }
        }
        
        updateFunction = UpdateDoorSwitch;
        onHitFunction = OnHitDoorSwitch;
        onClickedFunction = OnClickedDoorSwitch;
        switchFunction = onSwitchedDoorSwitch;
        
        var joint : EdJoint = new EdJoint();
        
        joint.SetType(EdJoint.Type_Rev);
        joint.obj0Name = "";
        joint.obj1Name = id;
        joint.rev_pos.x = startx;
        joint.rev_pos.y = starty;
        
        joint.objParameters.SetValueBoolean("rev_enablemotor", false);
        joint.objParameters.SetValueNumber("rev_motorrate", 1);
        joint.objParameters.SetValueNumber("rev_motorratio", 1);
        joint.objParameters.SetValueNumber("rev_motormax", 10000);
        
        joint.objParameters.SetValueBoolean("rev_enablelimit", false);
        joint.objParameters.SetValueNumber("rev_lowerangle", 0);
        joint.objParameters.SetValueNumber("rev_upperangle", 0);
        
        
        
        origAng = dir;
        
        minAng = 0;
        maxAng = 0;
        
        if (doorSwitch_ccw)
        {
            minAng -= doorSwitch_angAdd;
        }
        else
        {
            maxAng += doorSwitch_angAdd;
        }
        
        
        state = 0;
        if (doorSwitch_ccw)
        {
            state = 1;
        }
    }
    
    
    
    public function InitGameObjLine_Clicker()
    {
        initParams = "doorswitch_openangle=90,doorswitch_2way=true,doorswitch_ccw=false";
        InitDoorSwitch();
        name = "hello";
        clickTestType = 1;
    }
    
    
    
    
    
    
    
    public function OnHit_Wind(goHitter : GameObj)
    {
        if (goHitter.collisionType != "football" && goHitter.collisionType != "beachball")
        {
            return;
        }
        
        var ang : Float = GetBodyAngle(0);
        var dx : Float = 1;
        var dy : Float = 0;
        
        dx = Math.cos(ang) * force_strength;
        dy = Math.sin(ang) * force_strength;
        
        goHitter.ApplyForce(dx, dy);
    }
    
    public function UpdateWind()
    {
        var ang : Float = GetBodyAngle(0);
        ang -= Math.PI / 2;
        
        timer--;
        if (timer <= 0)
        {
            var p1 : Point = new Point(Utils.RandBetweenInt(-20, 20), Utils.RandBetweenInt(-20, 20));
            var m : Matrix = new Matrix();
            m.rotate(ang);
            p1 = m.transformPoint(p1);
            
            var pos : Point = new Point(xpos, ypos);
            pos.x += p1.x;
            pos.y += p1.y;
            
            timer = Utils.RandBetweenInt(10, 20);
            var go : GameObj = GameObjects.AddObj(pos.x, pos.y, zpos);
            go.InitWindPart(dir);
        }
    }
    public function InitWind()
    {
        name = "wind";
        timer = Utils.RandBetweenInt(10, 30);
        force_strength = Vars.GetVarAsNumber("windforce");
        state = 0;
        onHitFunction = OnHit_Wind;
        onHitPersistFunction = OnHit_Wind;
        updateFunction = UpdateWind;
        if (Game.usedebug == false)
        {
            visible = false;
        }
        visible = false;
    }
    public var force_strength : Float;
    public var initial_force_strength : Float;
    
    
    
    
    
    public function RenderWindPart()
    {
        var xp : Float = as3hx.Compat.parseInt(xpos) - as3hx.Compat.parseInt(Game.camera.x);
        var yp : Float = as3hx.Compat.parseInt(ypos) - as3hx.Compat.parseInt(Game.camera.y);
        var c : Int = 0xffffffff;
        bd.setPixel32(Std.int(xp), Std.int(yp), c);
        bd.setPixel32(Std.int(xp + 1), Std.int(yp), c);
        bd.setPixel32(Std.int(xp - 1), Std.int(yp), c);
        bd.setPixel32(Std.int(xp), Std.int(yp + 1), c);
        bd.setPixel32(Std.int(xp), Std.int(yp - 1), c);
    }
    public function UpdateWindPart()
    {
        xvel *= 1.1;
        yvel *= 1.1;
        xpos += xvel;
        ypos += yvel;
        timer--;
        if (timer <= 0)
        {
            RemoveObject();
        }
    }
    public function InitWindPart(_ang : Float)
    {
        state = 0;
        updateFunction = UpdateWindPart;
        renderFunction = RenderWindPart;
        frame = 0;
        frameVel = 4;
        dir = _ang;
        timer = timerMax = Utils.RandBetweenInt(8, 13);
        movementVec = new Vec();
        movementVec.Set(_ang, Utils.RandBetweenFloat(1, 2));
        xvel = movementVec.X();
        yvel = movementVec.Y();
    }
    
    
    
    public function UpdateSpawner()
    {
        rotVel += 0.09;
        
        if (state == -1)
        {
            state = 0;
        }
        if (state == 0)
        {
            timer--;
            if (timer <= 0)
            {
                state = 1;
            }
        }
        else if (state == 1)
        {
            var o : Dynamic = {};
            o.xpos = xpos;
            o.ypos = ypos;
            o.name = spawner_spawnobjectList[spawner_spawncount % spawner_spawnobjectList.length];
            GameObjects.AddToAddList(Spawner_GenerateObjectsCallback, o);
            
            SFX_OneShot("sfx_portal");
            
            spawner_spawncount++;
            
            timer = spawner_frequency;
            state = 0;
            
            if (spawner_total != 0)
            {
                if (spawner_spawncount >= spawner_total)
                {
                    state = 2;
                }
            }
        }
        else if (state == 2)
        {
        }
    }
    
    public function Spawner_GenerateObjectsCallback(o : Dynamic)
    {
        var go : GameObj = PhysicsBase.AddPhysObjAt(o.name, o.xpos, o.ypos, 0, 1, "", "", "");
    }
    
    
    public var spawner_initialdelay : Int = 0;
    public var spawner_frequency : Int = 0;
    public var spawner_total : Int = 0;
    public var spawner_spawncount : Int = 0;
    public var spawner_spawnobjectList : Array<Dynamic>;
    public function OnClickedSpawner()
    {
    }
    
    public function RenderSpawner()
    {
        dir = rotVel;
        RenderDispObjNormally();
        var dir2 : Float = rotVel * 0.3;
        RenderDispObjAt(xpos, ypos, dobj1, 0, null, dir2);
    }
    public function InitSpawner()
    {
        renderFunction = RenderSpawner;
        
        Utils.GetParams(initParams);
        switchName = Utils.GetParamString("switch_name", "");
        spawner_initialdelay = as3hx.Compat.parseInt(Utils.GetParamNumber("spawner_initialdelay", 0) * Defs.fps);
        spawner_frequency = as3hx.Compat.parseInt(Utils.GetParamNumber("spawner_frequency", 3) * Defs.fps);
        spawner_total = Utils.GetParamInt("spawner_totalamount", 10);
        spawner_spawnobjectList = [];
        var s : String = Utils.GetParamString("spawner_spawnobject", "");
        spawner_spawnobjectList = s.split("+");
        
        dobj1 = GraphicObjects.GetDisplayObjByName("wormhole_small");
        
        state = 0;
        timer = spawner_initialdelay;
        spawner_spawncount = 0;
        
        updateFunction = UpdateSpawner;
        
        
        state = -1;
        dir = 1;
        rotVel = 1;
    }
    
    
    
    
    public function RenderScoreText()
    {
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        (untyped dobj.origMC.text1).theText.text = Std.string(textMessage);
        (untyped dobj.origMC.text2).theText.text = Std.string(textMessage1);
        dobj.RenderAtRotScaled_Vector(Std.int(frame), bd, xp, yp, 1, 0, null, false, xflip);
    }
    public function UpdateScoreText()
    {
        if (state == 0)
        {
            if (PlayAnimation())
            {
                RemoveObject();
            }
        }
    }
    public function InitScoreText(_message : String, _points : Int)
    {
        textMessage = _message;
        textMessage1 = Std.string(_points) + " PTS";
        updateFunction = UpdateScoreText;
        renderFunction = RenderScoreText;
        dobj = GraphicObjects.GetDisplayObjByName("scoreText");
        frame = 0;
    }
    
    public function AddScore(sc : Int)
    {
        Game.AddScore(sc);
    }
    
    
    
    
    
    
    
    
    
    public function OnHitBonusPickup(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (goHitter.name == "alien")
        {
            state = 1;
        }
    }
    public function UpdateBonusPickup()
    {
        if (state == 1)
        {
            RemoveObject(RemovePhysObj);
        }
    }
    public function InitBonusPickup()
    {
        updateFunction = UpdateBonusPickup;
        onHitFunction = OnHitBonusPickup;
        state = 0;
    }
    
    
    
    
    public function OnHitPortalIn(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        
        {
            if (logicLink1 == null)
            {
                Utils.print("ERROR, no PORTAL OUT logic link defined");
            }
            else
            {
                SFX_OneShot("sfx_portal");
                
                if (logicLink1.name == "portal_out")
                {
                    goHitter.SetBodyXForm_Immediate(0, logicLink1.xpos, logicLink1.ypos, dir);
                    goHitter.LimitVelocity_Nape(100);
                    logicLink1.PortalOutSetSparks();
                    PortalInSetSparks();
                }
                if (logicLink1.name == "portal_out_directional")
                {
                    var m : Vec = new Vec();
                    m.Set(logicLink1.dir - (Math.PI / 2), 250);
                    
                    goHitter.SetBodyLinearVelocity(0, m.X(), m.Y());
                    goHitter.SetBodyAngularVelocity(0, 0);
                    goHitter.SetBodyXForm_Immediate(0, logicLink1.xpos, logicLink1.ypos, dir);
                    logicLink1.PortalOutSetSparks();
                    PortalInSetSparks();
                }
            }
        }
    }
    public function UpdatePortalIn()
    {
        CycleAnimation();
        if (dobj1 != null)
        {
            if (PlayAnimation1())
            {
                dobj1 = null;
            }
        }
    }
    public var portalExitGO : GameObj;
    
    public function PortalInSetSparks()
    {
        dobj1 = GraphicObjects.GetDisplayObjByName("portalINsparks");
        frame1 = 0;
    }
    
    public function RenderPortalIn()
    {
        RenderDispObjNormally();
        if (dobj1 != null)
        {
            RenderDispObjAt(xpos, ypos, dobj1, Std.int(frame1));
        }
    }
    public function InitPortalIn()
    {
        name = "portal_in";
        
        updateFunction = UpdatePortalIn;
        onHitFunction = OnHitPortalIn;
        renderFunction = RenderPortalIn;
        state = 0;
        dobj1 = null;
        frameVel1 = 1;
    }
    
    
    
    
    
    
    
    public function RenderPortalOut()
    {
        RenderDispObjNormally();
        if (dobj1 != null)
        {
            RenderDispObjAt(xpos, ypos, dobj1, Std.int(frame1));
        }
    }
    public function PortalOutSetSparks()
    {
        dobj1 = GraphicObjects.GetDisplayObjByName("portalOUTsparks");
        frame1 = 0;
    }
    public function UpdatePortalOut()
    {
        CycleAnimation();
        if (dobj1 != null)
        {
            if (PlayAnimation1())
            {
                dobj1 = null;
            }
        }
    }
    public function InitPortalOut()
    {
        name = "portal_out";
        updateFunction = UpdatePortalOut;
        renderFunction = RenderPortalOut;
        dobj1 = null;
        frameVel1 = 1;
    }
    
    
    public function UpdatePortalOutDirectional()
    {
        CycleAnimation();
        if (dobj1 != null)
        {
            if (PlayAnimation1())
            {
                dobj1 = null;
            }
        }
    }
    public function InitPortalOutDirectional()
    {
        name = "portal_out_directional";
        updateFunction = UpdatePortalOutDirectional;
        renderFunction = RenderPortalOut;
        dobj1 = null;
        frameVel1 = 1;
    }
    
    
    
    public function OnClickSnake()
    {
        if (GameVars.snakeUpgrade == GameVars.snakeUpgrade_Spitter && GameVars.snakeUpgradeGO == this)
        {
            return;
        }
        if (state1 == 0)
        {
            Snake_ReleasePig();
            state1 = 1;
        }
    }
    public function OnHitSnake(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
    }
    public var spitTimer : Int = 0;
    public function UpdateSnake()
    {
        var mx : Float = MouseControl.x;
        var my : Float = MouseControl.y;
        var mouseOver : Bool = false;
        if (Utils.DistBetweenPoints(xpos, ypos, mx, my) < 30)
        {
            mouseOver = true;
        }
        
        if (mouseOverDobj != null)
        {
            if (mouseOver)
            {
                if (mouseOverFrame > 11)
                {
                    mouseOverFrame = 0;
                }
                mouseOverFrame++;
                if (mouseOverFrame >= 11)
                {
                    mouseOverFrame = 11;
                }
            }
            else
            {
                if (mouseOverFrame < 11)
                {
                    mouseOverFrame = 11;
                }
                mouseOverFrame++;
                if (mouseOverFrame >= 15)
                {
                    mouseOverFrame = 15;
                }
            }
        }
        
        
        if (GameVars.snakeUpgrade == GameVars.snakeUpgrade_Spitter && GameVars.snakeUpgradeGO == this)
        {
            Snake_ReleasePig();
            spitTimer--;
            if (spitTimer <= 0)
            {
                var soundName : String = "sfx_spit" + Utils.RandBetweenInt(1, 3);
                SFX_OneShot(soundName);
                
                var go : GameObj = snakeObjList[snakeObjList.length - 1];
                
                var p : Point = new Point(0, 20);
                var m : Matrix = new Matrix();
                m.rotate(go.dir);
                p = m.transformPoint(p);
                var x : Float = go.xpos + p.x;
                var y : Float = go.ypos + p.y;
                
                var go1 : GameObj = PhysicsBase.AddPhysObjAt("spit_rock", x, y, 0, 1, "", "");
                
                var f : Float = 1000;
                var dx : Float = Math.cos(go.dir + (Math.PI / 2)) * f;
                var dy : Float = Math.sin(go.dir + (Math.PI / 2)) * f;
                
                go1.ApplyImpulse(dx, dy);
                spitTimer = 3;
            }
        }
        else if (state1 == 0)
        {
            frame = 0;
        }
        else if (state1 == 1)
        {
            if (PlayAnimation())
            {
                state1 = 2;
                timer1 = GameVars.SnakeReloadTimeNormal;
                
                if (GameVars.snakeUpgrade == GameVars.snakeUpgrade_SuperRegen && GameVars.snakeUpgradeGO == this)
                {
                    timer1 = GameVars.SnakeReloadTimeSuper;
                }
            }
        }
        else if (state1 == 2)
        {
            timer1--;
            if (timer1 <= 0)
            {
                Snake_AddPig();
                state1 = 0;
            }
        }
        
        var f : Float = Utils.DegToRad(snake_swingForce);
        var tm : Int = Std.int(timerMax);
        
        
        if (GameVars.snakeUpgrade == GameVars.snakeUpgrade_FastSwing && GameVars.snakeUpgradeGO == this)
        {
            f *= 2;
            tm -= 5;
        }
        
        
        
        
        var motorJoint : MotorJoint = try cast(nape_joints[1], MotorJoint) catch(e:Dynamic) null;
        if (state == 0)
        {
            timer--;
            if (timer <= 0)
            {
                timer = tm;
                state = 1;
            }
        }
        else if (state == 1)
        {
            f = -f;
            timer--;
            if (timer <= 0)
            {
                timer = tm;
                state = 0;
            }
        }
        
        var pj : PivotJoint = try cast(nape_joints[0], PivotJoint) catch(e:Dynamic) null;
        pj.body2.rotation += f;
        
        for (go/* AS3HX WARNING could not determine type for var: go exp: EIdent(snakeObjList) type: null */ in snakeObjList)
        {
            if (go.nape_joints != null)
            {
                pj = try cast(go.nape_joints[0], PivotJoint) catch(e:Dynamic) null;
                if (pj != null)
                {
                    pj.body2.rotation += f;
                }
            }
        }
    }
    
    public var snakeObjList : Array<Dynamic>;
    
    
    
    public function InitSnake1_Normal()
    {
        InitSnake(0, 5, 13, 0.8, 10, 8);
    }
    public function InitSnake2_Normal()
    {
        InitSnake(0, 7, 13, 1, 10, 8);
    }
    
    
    public function SwitchSnake2_Normal_Invisible()
    {
        visible = true;
        for (go in snakeObjList)
        {
            go.visible = true;
        }
        snake_pigGO.visible = true;
    }
    public function InitSnake2_Normal_Invisible()
    {
        InitSnake2_Normal();
        visible = false;
        switchFunction = SwitchSnake2_Normal_Invisible;
        switchName = Game.GetSwitchJointName(id);
        
        for (go in snakeObjList)
        {
            go.visible = false;
        }
        snake_pigGO.visible = false;
    }
    
    public function InitSnake3_Normal()
    {
        InitSnake(0, 9, 13, 1.2, 10, 8);
    }
    public function InitSnake1_Floater()
    {
        InitSnake(1, 5, 13, 0.8, 10, 8);
    }
    public function InitSnake2_Floater()
    {
        InitSnake(1, 7, 13, 1, 10, 8);
    }
    public function InitSnake3_Floater()
    {
        InitSnake(1, 9, 13, 1.1, 10, 8);
    }
    public function InitSnake1_Sticker()
    {
        InitSnake(2, 5, 13, 0.8, 10, 8);
    }
    public function InitSnake2_Sticker()
    {
        InitSnake(2, 7, 13, 1, 10, 8);
    }
    public function InitSnake3_Sticker()
    {
        InitSnake(2, 9, 13, 1.1, 10, 8);
    }
    
    public var snake_swingForce : Float;
    public var mouseOverDobj : DisplayObj;
    public var mouseOverFrame : Float;
    public function RenderSnake()
    {
        RenderDispObjNormally();
        if (mouseOverDobj == null)
        {
            return;
        }
        RenderDispObjAt(xpos, ypos, mouseOverDobj, Std.int(mouseOverFrame));
    }
    public function InitSnake(_type : Int, _numBits : Int, _angLimit : Float, _swingTimer : Float, _force : Float = 10, yoffset : Float = 10)
    {
        name = "snake";
        snake_pigGO = null;
        snakeObjList = [];
        onClickedFunction = OnClickSnake;
        onHitFunction = OnHitSnake;
        updateFunction = UpdateSnake;
        renderFunction = RenderSnake;
        
        spitTimer = 0;
        
        mouseOverDobj = null;
        if (_type == 1)
        {
            mouseOverDobj = GraphicObjects.GetDisplayObjByName("GumIndicatorFloater");
        }
        if (_type == 2)
        {
            mouseOverDobj = GraphicObjects.GetDisplayObjByName("GumIndicatorExploder");
        }
        mouseOverFrame = 0;
        
        timer = 0;
        timerMax = as3hx.Compat.parseInt(_swingTimer * Defs.fps);
        var angLimit : Float = _angLimit;
        snake_swingForce = _force;
        var numBits : Int = _numBits;
        
        if (id == "")
        {
            id = PhysEditor.CreateNewUniqueID();
        }
        
        state1 = 0;
        timer1 = 0;
        
        
        var p : Point = new Point(0, 0);
        var m : Matrix = new Matrix();
        m.rotate(dir);
        p = m.transformPoint(p);
        
        var x : Float = xpos + p.x;
        var y : Float = ypos + p.y;
        var go : GameObj = null;        
        
        var parentGO : GameObj = this;
        
        
        type = _type;
        
        var num : Int = as3hx.Compat.parseInt(type + 1);
        
        var z : Float = zpos - 0.001;
        
        for (i in 0...numBits)
        {
            if (i < numBits - 1)
            {
                go = PhysicsBase.AddPhysObjAt("snake_" + num + "_body", x, y, Utils.RadToDeg(dir), 1, "", "", "");
                go.id = PhysEditor.CreateNewUniqueID();
                go.zpos = z;
            }
            else
            {
                go = PhysicsBase.AddPhysObjAt("snake_" + num + "_head", x, y, Utils.RadToDeg(dir), 1, "", "", "");
                go.id = PhysEditor.CreateNewUniqueID();
                go.zpos = z;
            }
            z -= 0.001;
            snakeObjList.push(go);
            
            
            
            
            var joint : EdJoint = new EdJoint();
            
            joint.SetType(EdJoint.Type_Rev);
            joint.obj0Name = parentGO.id;
            joint.obj1Name = go.id;
            joint.rev_pos.x = x;
            joint.rev_pos.y = y;
            
            joint.objParameters.SetValueBoolean("rev_enablemotor", false);
            
            joint.objParameters.SetValueNumber("rev_motorrate", 10);
            joint.objParameters.SetValueNumber("rev_motorratio", 1);
            joint.objParameters.SetValueNumber("rev_motormax", 20000);
            
            joint.objParameters.SetValueBoolean("rev_enablelimit", true);
            joint.objParameters.SetValueNumber("rev_lowerangle", -angLimit);
            joint.objParameters.SetValueNumber("rev_upperangle", angLimit);
            
            parentGO.AddJoint_Nape(joint);
            
            
            var p : Point = new Point(0, yoffset);
            var m : Matrix = new Matrix();
            m.rotate(parentGO.dir);
            p = m.transformPoint(p);
            x += p.x;
            y += p.y;
            
            parentGO = go;
        }
        
        Snake_AddPig();
    }
    public function Snake_ReleasePig()
    {
    }
    
    public var snake_pigGO : GameObj;
    public var snake_pigGOJoint : Constraint;
    public var snake_pigGOJoint1 : Constraint;
    
    public function Snake_AddPig()
    {
        var go : GameObj = snakeObjList[snakeObjList.length - 1];
        
        var p : Point = new Point(0, 30);
        var m : Matrix = new Matrix();
        m.rotate(go.dir);
        p = m.transformPoint(p);
        var x : Float = go.xpos + p.x;
        var y : Float = go.ypos + p.y;
        
        var pigType : Int = Utils.RandBetweenInt(1, GameVars.guineaPigTypesAllowed);
        
        var pigGO : GameObj = null;        pigGO = PhysicsBase.AddPhysObjAt("guinea_pig_" + pigType, x, y, 0, 1, "", "", "");
        pigGO.type = type;
        pigGO.id = PhysEditor.CreateNewUniqueID();
        
        var joint : EdJoint = new EdJoint();
        
        joint.SetType(EdJoint.Type_Rev);
        joint.obj0Name = go.id;
        joint.obj1Name = pigGO.id;
        joint.rev_pos.x = x;
        joint.rev_pos.y = y;
        
        joint.objParameters.SetValueBoolean("rev_enablemotor", false);
        joint.objParameters.SetValueNumber("rev_motorrate", 10);
        joint.objParameters.SetValueNumber("rev_motorratio", 1);
        joint.objParameters.SetValueNumber("rev_motormax", 40000);
        
        joint.objParameters.SetValueBoolean("rev_enablelimit", false);
        joint.objParameters.SetValueNumber("rev_lowerangle", -10);
        joint.objParameters.SetValueNumber("rev_upperangle", 10);
        
        snake_pigGO = pigGO;
        snake_pigGO.AddJoint_Nape(joint);
        
        pigGO.zpos = go.zpos + 1;
        
        
        snake_pigGOJoint = snake_pigGO.nape_joints[0];
        snake_pigGOJoint1 = null;
        
        if (GameVars.snakeUpgrade == GameVars.snakeUpgrade_PigChain && GameVars.snakeUpgradeGO == this)
        {
            go = pigGO;
            y += 20;
            for (i in 0...3)
            {
                pigGO = PhysicsBase.AddPhysObjAt("guinea_pig_1", x, y, 0, 1, "", "", "");
                pigGO.type = type;
                pigGO.id = PhysEditor.CreateNewUniqueID();
                
                var joint : EdJoint = new EdJoint();
                
                joint.SetType(EdJoint.Type_Rev);
                joint.obj0Name = go.id;
                joint.obj1Name = pigGO.id;
                joint.rev_pos.x = x;
                joint.rev_pos.y = y;
                
                joint.objParameters.SetValueBoolean("rev_enablemotor", false);
                joint.objParameters.SetValueNumber("rev_motorrate", 10);
                joint.objParameters.SetValueNumber("rev_motorratio", 1);
                joint.objParameters.SetValueNumber("rev_motormax", 40000);
                
                joint.objParameters.SetValueBoolean("rev_enablelimit", false);
                joint.objParameters.SetValueNumber("rev_lowerangle", -10);
                joint.objParameters.SetValueNumber("rev_upperangle", 10);
                
                pigGO.AddJoint_Nape(joint);
                y += 20;
                go = pigGO;
            }
        }
    }
    
    
    
    
    
    public function OnHitGuineaPig(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        
        var spd : Float = GetBodyLinearVelocity(0).length;
        var r : Float = 0;
        if (hitContactPoint_Nape != null)
        {
        }
        
        if (hitContactPoint_Nape != null)
        {
            if (hitContactPoint_Nape.arbiter.isCollisionArbiter())
            {
                if (true)
                {
                    if (spd > 40)
                    {
                        var soundName : String = "sfx_pig_bounce" + Utils.RandBetweenInt(1, 10);
                        SFX_OneShot(soundName);
                    }
                }
            }
        }
    }
    public var stillTimer : Int = 0;
    public function GuineaPigStartBlow()
    {
        if (state == 0)
        {
            var soundName : String = "sfx_blow" + Utils.RandBetweenInt(1, 3);
            SFX_OneShot(soundName);
            if (type == 0)
            {
                dobj1 = GraphicObjects.GetDisplayObjByName("Bubble");
                state = 11;
            }
            if (type == 1)
            {
                dobj1 = GraphicObjects.GetDisplayObjByName("Bubble_floater");
                state = 21;
            }
            if (type == 2)
            {
                dobj1 = GraphicObjects.GetDisplayObjByName("Bubble_sticky");
                state = 11;
            }
            frame1 = 0;
            zpos = GameLayers.GetZPosByName("Bubbles");
        }
    }
    public function RemoveGuineaPig()
    {
        state = 100;
    }
    
    
    
    
    public function GuineaPig_BubblePops(numBits : Int = 32, time : Int = 6)
    {
        if (type == 2)
        {
        }
        else
        {
        }
        
        var soundName : String = "sfx_pop" + Utils.RandBetweenInt(1, 3);
        SFX_OneShot(soundName);
        
        for (i in 0...numBits)
        {
            if (type == 2)
            {
                var d : Float = 700;
                var r : Float = (Math.PI * 2) / as3hx.Compat.parseFloat(numBits) * as3hx.Compat.parseFloat(i);
                var dx : Float = Math.cos(r) * d;
                var dy : Float = Math.sin(r) * d;
                var go : GameObj = PhysicsBase.AddPhysObjAt("bubblebit_dense", xpos, ypos, 0, 1);
                go.timer = time;
                go.ApplyImpulse(dx, dy);
            }
            else
            {
                var d : Float = 6;
                var r : Float = (Math.PI * 2) / as3hx.Compat.parseFloat(numBits) * as3hx.Compat.parseFloat(i);
                var dx : Float = Math.cos(r) * d;
                var dy : Float = Math.sin(r) * d;
                var go : GameObj = PhysicsBase.AddPhysObjAt("bubblebit", xpos, ypos, 0, 1);
                go.timer = time;
                go.ApplyImpulse(dx, dy);
            }
        }
    }
    
    
    
    
    public function OnHitBubbleBit(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        
        
        if (goHitter.collisionType == "animal")
        {
            RemoveObject(RemovePhysObj);
        }
        if (goHitter.collisionType == "boss")
        {
            goHitter.BossHitByBubble();
            RemoveObject(RemovePhysObj);
        }
        else
        {
            state = 1;
        }
    }
    public function BubbleBit_StopIt()
    {
        state = 1;
    }
    public function UpdateBubbleBit()
    {
        if (state == 0)
        {
            timer--;
            if (timer <= 0)
            {
                RemoveObject(RemovePhysObj);
            }
        }
        else if (state == 1)
        {
            RemovePhysObj();
            state = 2;
            alphaVel = -Utils.RandBetweenFloat(0.02, 0.05);
        }
        else if (state == 2)
        {
            alpha += alphaVel;
            if (alpha <= 0)
            {
                alpha = 0;
                RemoveObject();
            }
        }
    }
    public function RenderCallback_Alpha()
    {
        RenderDispObjNormallyAlpha();
    }
    public function InitBubbleBit()
    {
        collisionType = "bubble";
        onHitFunction = OnHitBubbleBit;
        updateFunction = UpdateBubbleBit;
        renderFunction = RenderCallback_Alpha;
        alpha = 1;
        timer = 6;
    }
    
    
    public function UpdateBubbleBitDense()
    {
        timer--;
        if (timer <= 0)
        {
            RemoveObject(RemovePhysObj);
        }
    }
    public function InitBubbleBitDense()
    {
        updateFunction = UpdateBubbleBitDense;
        timer = 12;
    }
    
    
    
    public function OnHitSpitRock(hitterGO : GameObj)
    {
        if (hitterGO == null)
        {
            return;
        }
    }
    
    public function UpdateSpitRock()
    {
        timer--;
        if (timer <= 0)
        {
            RemoveObject(RemovePhysObj);
        }
    }
    public function InitSpitRock()
    {
        updateFunction = UpdateSpitRock;
        onHitFunction = OnHitSpitRock;
        timer = as3hx.Compat.parseInt(Defs.fps * 2);
    }
    
    
    
    
    
    
    
    public function OnHitAnimalGold(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (goHitter.name == "guineapig")
        {
            state = 1;
            RemovePhysObj();
            onHitFunction = null;
            dobj = GraphicObjects.GetDisplayObjByName("collectPickup");
            frame = 0;
            GameVars.collectedBonus = true;
            SFX_OneShot("sfx_pickup_gold");
        }
    }
    public function UpdateAnimalGold()
    {
        if (state == 0)
        {
            CycleAnimation();
        }
        else if (state == 1)
        {
            if (PlayAnimation())
            {
                RemoveObject();
            }
        }
    }
    public function InitAnimalGold()
    {
        name = "goldanimal";
        collisionType = "goldanimal";
        onHitFunction = OnHitAnimalGold;
        updateFunction = UpdateAnimalGold;
        if (Levels.GetCurrent().gotBonus)
        {
            visible = false;
            onHitFunction = null;
        }
    }
    
    
    
    
    public function OnHitIcecreamVan(hitterGO : GameObj)
    {
        if (hitterGO == null)
        {
            return;
        }
        if (state != 0)
        {
            return;
        }
        state = 1;
        timer = as3hx.Compat.parseInt(Defs.fps * 5);
        SFX_OneShot("sfx_icecreamvan");
    }
    public function UpdateIcecreamVan()
    {
        if (state == 1)
        {
            timer--;
            if (timer <= 0)
            {
                state = 0;
            }
        }
    }
    public function InitIcecreamVan()
    {
        updateFunction = UpdateIcecreamVan;
        onHitFunction = OnHitIcecreamVan;
    }
    
    
    
    public function OnHitSandBlock(hitterGO : GameObj)
    {
        if (hitterGO == null)
        {
            return;
        }
        if (state != 0)
        {
            return;
        }
        if (hitterGO.collisionType == "beachball")
        {
            SFX_OneShot("sfx_hit_sandblock");
            RemovePhysObj();
            state = 1;
        }
    }
    
    public function UpdateSandBlock()
    {
        if (state == 1)
        {
            if (PlayAnimation())
            {
                RemoveObject();
            }
        }
    }
    public function InitSandBlock()
    {
        onHitFunction = OnHitSandBlock;
        updateFunction = UpdateSandBlock;
        frameVel = 0.3;
    }
    
    
    public function InitBreakable_WoodenCrate()
    {
        var x : Float = -18;
        var y : Float = -16;
        var list : Array<Dynamic> = [];
        list.push(new BreakablePieceDef(x + 7, y + 5, "woodenCrate1_part1"));
        list.push(new BreakablePieceDef(x + 30, y + 4, "woodenCrate1_part2"));
        list.push(new BreakablePieceDef(x + 42, y + 9, "woodenCrate1_part3"));
        list.push(new BreakablePieceDef(x + 5, y + 25, "woodenCrate1_part4"));
        list.push(new BreakablePieceDef(x + 17, y + 15, "woodenCrate1_part5"));
        list.push(new BreakablePieceDef(x + 33, y + 19, "woodenCrate1_part6"));
        list.push(new BreakablePieceDef(x + 19, y + 28, "woodenCrate1_part7"));
        list.push(new BreakablePieceDef(x + 36, y + 30, "woodenCrate1_part8"));
        Init_Breakable_Pieces(list);
    }
    
    public function InitBreakable_WoodenPost()
    {
        var list : Array<Dynamic> = [];
        list.push(new BreakablePieceDef(0, -20, "woodPost0_part3"));
        list.push(new BreakablePieceDef(0, -1, "woodPost0_part2"));
        list.push(new BreakablePieceDef(0, 19, "woodPost0_part1"));
        Init_Breakable_Pieces(list);
    }
    
    public function InitBreakable_Block()
    {
        var list : Array<Dynamic> = [];
        list.push(new BreakablePieceDef(-20, 0, "Block_part1"));
        list.push(new BreakablePieceDef(-7, 19, "Block_part2"));
        list.push(new BreakablePieceDef(18, 10, "Block_part3"));
        list.push(new BreakablePieceDef(9, 6, "Block_part4"));
        list.push(new BreakablePieceDef(-6, 0, "Block_part5"));
        list.push(new BreakablePieceDef(-17, -18, "Block_part6"));
        list.push(new BreakablePieceDef(4, -13, "Block_part7"));
        list.push(new BreakablePieceDef(17, -12, "Block_part8"));
        Init_Breakable_Pieces(list);
    }
    
    
    public function InitBreakable_Wood()
    {
        var list : Array<Dynamic> = [];
        list.push(new BreakablePieceDef(-32, 0, "Wood_part1"));
        list.push(new BreakablePieceDef(-9, 1, "Wood_part2"));
        list.push(new BreakablePieceDef(8, 5, "Wood_part3"));
        list.push(new BreakablePieceDef(34, 4, "Wood_part4"));
        list.push(new BreakablePieceDef(49, 1, "Wood_part5"));
        list.push(new BreakablePieceDef(21, -2, "Wood_part6"));
        list.push(new BreakablePieceDef(2, -2, "Wood_part7"));
        list.push(new BreakablePieceDef(-14, -4, "Wood_part8"));
        list.push(new BreakablePieceDef(2, 2, "Wood_part9"));
        list.push(new BreakablePieceDef(26, 3, "Wood_part10"));
        Init_Breakable_Pieces(list);
    }
    
    
    public function InitBreakable_SwitchCover()
    {
        name = "switch_cover";
        var list : Array<Dynamic> = [];
        list.push(new BreakablePieceDef(2, 4, "lever_part1"));
        list.push(new BreakablePieceDef(19, -10, "lever_part2"));
        list.push(new BreakablePieceDef(12, 5, "lever_part3"));
        list.push(new BreakablePieceDef(-8, 4, "lever_part4"));
        list.push(new BreakablePieceDef(18, -8, "lever_part5"));
        list.push(new BreakablePieceDef(-3, -4, "lever_part6"));
        list.push(new BreakablePieceDef(6, 3, "lever_part7"));
        list.push(new BreakablePieceDef(-13, 4, "lever_part8"));
        list.push(new BreakablePieceDef(-2, 2, "lever_part9"));
        list.push(new BreakablePieceDef(11, 2, "lever_part10"));
        Init_Breakable_Pieces(list);
    }
    
    
    public var breakable_piece_def_list : Array<Dynamic>;
    public function Init_Breakable_Pieces(_list : Array<Dynamic>)
    {
        breakable_piece_def_list = _list;
        updateFunction = Update_Breakable_Pieces;
        onHitFunction = OnHit_Breakable_Pieces;
        frame = 0;
        health = maxHealth = 1;
    }
    public function Update_Breakable_Pieces()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            var soundName : String = "sfx_wood_snap" + Utils.RandBetweenInt(1, 4);
            SFX_OneShot(soundName);
            
            if (break_sfx_name == "")
            {
            }
            else
            {
            }
            RemoveObject(RemovePhysObj);
            for (def in breakable_piece_def_list)
            {
                var r : Float = dir;
                var go : GameObj = null;                
                
                
                
                
                
                var m : Matrix = new Matrix();
                m.rotate(dir);
                var p : Point = new Point(def.x, def.y);
                p = m.transformPoint(p);
                var x : Float = xpos + p.x;
                var y : Float = ypos + p.y;
                
                
                var vec : Vec = new Vec();
                vec.rot = Utils.RandCircle();
                vec.speed = Utils.RandBetweenFloat(1, 2);
                
                vec.Add(movementVec);
                
                go = PhysicsBase.AddPhysObjAt("broken_piece", x, y, Utils.RadToDeg(dir), 1);
                go.PostInitBreakable_Piece(def, r, vec);
            }
        }
    }
    public function OnHit_Breakable_Pieces(hitterGO : GameObj)
    {
        if (hitterGO == null)
        {
            return;
        }
        
        if (hitterGO.collisionType == "football" || hitterGO.collisionType == "beachball")
        {
            var aa : InteractionCallback = hitterGO.hitInteractionCallback_Nape;
            var bb : Contact = hitterGO.hitContactPoint_Nape;
            
            
            var v0 : Vec3 = nape_bodies[0].normalImpulse(hitterGO.nape_bodies[0]);
            
            var v1 : Vec2 = new Vec2(v0.x, v0.y);
            
            var l : Float = v1.length;
            
            l /= hitterGO.GetBodyMass(0);

            // [BREAK-PROBE] always-on diagnostic: shows exactly why a crate does or
            // doesn't break. l is the ball's NORMAL velocity-change at the contact
            // (must be >=150). A mostly-tangential (sliding) hit gives a small l even
            // for a fast ball. Compare ball v=(vx,vy): if |vy|>>|vx| the ball is
            // sliding down the face, not hitting it head-on.
            var hb = hitterGO.nape_bodies[0];
            js.Browser.console.log("[BREAK] crate@(" + Std.int(xpos) + "," + Std.int(ypos) + ") l=" + Math.round(l)
                + (l < 150 ? " <150 NO-BREAK" : " >=150 BREAK")
                + "  ball v=(" + Math.round(hb.velocity.x) + "," + Math.round(hb.velocity.y) + ")"
                + "  imp=(" + Math.round(v0.x) + "," + Math.round(v0.y) + ", z" + Math.round(v0.z) + ")");
            Utils.print("hit speed " + l);

            if (l < 150)
            {
                return;
            }
            
            frame = 0;
            frameVel = 1;
            state = 1;
            onHitFunction = null;
            movementVec.SetFromDxDy(v1.x, v1.y);
            movementVec.speed *= 0.03;
        }
    }
    
    
    
    public function RenderBreakable_Piece()
    {
        RenderDispObjNormallyAlpha();
    }
    public function UpdateBreakable_Piece()
    {
        dir += rotVel;
        xpos += xvel;
        ypos += yvel;
        yvel += 0.3;
        timer--;
        if (timer <= 0)
        {
            RemoveObject();
        }
        alpha = Utils.ScaleTo(0, 1, 0, timerMax, timer);
    }
    
    public function UpdateBreakable_Piece_Physics()
    {
        timer--;
        if (timer <= 0)
        {
            RemoveObject(RemovePhysObj);
        }
    }
    
    public function PostInitBreakable_Piece(def : BreakablePieceDef, rotat : Float, vec : Vec)
    {
        dobj = GraphicObjects.GetDisplayObjByName(def.objname);
        frame = 0;
        
        ApplyImpulse(vec.X(), vec.Y());
        
        timer = timerMax = Utils.RandBetweenInt(100, 200);
    }
    public function InitBreakable_Piece_Physics()
    {
        updateFunction = UpdateBreakable_Piece_Physics;
        renderFunction = RenderBreakable_Piece;
    }
    
    public function InitBreakable_Piece(def : BreakablePieceDef, rotat : Float)
    {
        updateFunction = UpdateBreakable_Piece;
        renderFunction = RenderBreakable_Piece;
        dobj = GraphicObjects.GetDisplayObjByName(def.objname);
        frame = 0;
        
        var m : Matrix = new Matrix();
        m.rotate(rotat);
        var p : Point = new Point(def.x, def.y);
        p = m.transformPoint(p);
        xpos += p.x;
        ypos += p.y;
        
        dir = rotat;
        
        
        
        var vec : Vec = new Vec();
        vec.rot = Utils.RandCircle();
        vec.speed = Utils.RandBetweenFloat(1, 2);
        
        xvel = vec.X();
        yvel = vec.Y();
        rotVel = Utils.RandBetweenFloat(0.1, 0.2);
        if (Utils.RandBetweenInt(0, 1000) < 500)
        {
            rotVel = -rotVel;
        }
        timer = timerMax = Utils.RandBetweenInt(30, 40);
    }
    
    
    
    
    
    
    
    public function OnHitSpringboard(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (state != 0)
        {
            return;
        }
        state = 1;
        frame = 0;
    }
    public function UpdateSpringboard()
    {
        if (state == 1)
        {
            if (PlayAnimation())
            {
                state = 0;
            }
        }
    }
    public function InitSpringboard()
    {
        onHitFunction = OnHitSpringboard;
        updateFunction = UpdateSpringboard;
    }
    
    
    
    
    
    
    
    
    public function UpdateCycleAnimation()
    {
        CycleAnimation();
    }
    public function InitCycleAnimation()
    {
        updateFunction = UpdateCycleAnimation;
    }
    
    
    
    
    
    
    
    
    
    public function OnHitPickup(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (state != 0)
        {
            return;
        }
        if (goHitter.name == "football")
        {
            PickupCollected(goHitter);
            RemovePhysObj();
            SFX_OneShot("sfx_collect_coin");
            dobj1 = GraphicObjects.GetDisplayObjByName("fx_sparkles");
            zpos = -10000;
            scale1 = 1;
            frame1 = 0;
            frameVel1 = 0.5;
            scale = 0.4;
            state = 1;
            dir1 = Utils.RandCircle();
            GameVars.CollectCoin(type);
        }
    }
    public function UpdatePickup()
    {
        if (state == 0)
        {
        }
        else if (state == 1)
        {
            scale1 += 0.2;
            if (PlayAnimation1())
            {
                state = 2;
            }
        }
    }
    public function RenderPickup()
    {
        RenderDispObjNormally();
        if (state == 1)
        {
            RenderDispObjAt(xpos, ypos, dobj1, Std.int(frame1), null, dir1, scale1);
        }
    }
    
    
    public function UpdatePickup_InWalkthrough()
    {
        timer++;
        scale = 1 + (Math.cos(timer * 0.1) * 0.1);
    }
    
    public function InitPickup()
    {
        dobj1 = null;
        frameVel = 0.5;
        name = "pickup";
        onHitFunction = OnHitPickup;
        updateFunction = UpdatePickup;
        renderFunction = RenderPickup;
        
        
        type = GameVars.totalLevelCoins;
        GameVars.totalLevelCoins++;
        
        if (GameVars.IsCoinCollected(type))
        {
            scale = 0.4;
            onHitFunction = null;
        }
        
        if (Game.doWalkthrough)
        {
            zpos = -20000;
            scale = 1;
            updateInWalkthrough = true;
            updateFunction = UpdatePickup_InWalkthrough;
        }
    }
    
    
    
    public function OnHitPickupTrophy(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (state != 0)
        {
            return;
        }
        if (goHitter.name == "football")
        {
            GameVars.SetHasTrophy(type);
            RemoveObject(RemovePhysObj);
            SFX_OneShot("sfx_collect_cup");
            
            var go : GameObj = GameObjects.AddObj(xpos, ypos - 30, zpos - 2000);
            go.InitTrophyPopup();
        }
    }
    
    public function RenderWalkthroughTrophy()
    {
        RenderDispObjNormally();
        RenderDispObjAt(xpos - 25, ypos - 25, GraphicObjects.GetDisplayObjByName("walkthroughMarker"), 0, null, 0, 1);
    }
    public function UpdateWalkthroughTrophy()
    {
        timer++;
        scale = 1 + (Math.cos(timer * 0.1) * 0.1);
    }
    public function InitPickupTrophy(_trophyID : Int)
    {
        type = _trophyID;
        if (GameVars.HasTrophy(type))
        {
            RemoveObject(RemovePhysObj);
        }
        name = "pickup";
        onHitFunction = OnHitPickupTrophy;
        updateFunction = UpdatePickup;
        
        if (Game.doWalkthrough)
        {
            updateInWalkthrough = true;
            zpos = -20000;
            scale = 1;
            updateFunction = UpdateWalkthroughTrophy;
            renderFunction = RenderWalkthroughTrophy;
        }
    }
    
    public function InitPickupTrophy1()
    {
        InitPickupTrophy(0);
    }
    public function InitPickupTrophy2()
    {
        InitPickupTrophy(1);
    }
    public function InitPickupTrophy3()
    {
        InitPickupTrophy(2);
    }
    public function InitPickupTrophy4()
    {
        InitPickupTrophy(3);
    }
    public function InitPickupTrophy5()
    {
        InitPickupTrophy(4);
    }
    public function InitPickupTrophy6()
    {
        InitPickupTrophy(5);
    }
    public function InitPickupTrophy7()
    {
        InitPickupTrophy(6);
    }
    public function InitPickupTrophy8()
    {
        InitPickupTrophy(7);
    }
    public function InitPickupTrophy9()
    {
        InitPickupTrophy(8);
    }
    public function InitPickupTrophy10()
    {
        InitPickupTrophy(9);
    }
    
    
    public function PickupCollected(goHitter : GameObj)
    {
        if (type == 1)
        {
        }
        if (type == 2)
        {
        }
        if (type == 3)
        {
        }
        if (type == 4)
        {
        }
    }
    public function InitPickup1()
    {
        InitPickup();
        type = 1;
    }
    public function InitPickup2()
    {
        InitPickup();
        type = 2;
    }
    public function InitPickup3()
    {
        InitPickup();
        type = 3;
    }
    public function InitPickup4()
    {
        InitPickup();
        type = 4;
    }
    
    
    
    public var gunBombNumBits : Int = 0;
    public var gunBombTime : Int = 0;
    public function OnHitGumBomb(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (goHitter.collisionType == "bubble")
        {
            if (state == 0)
            {
                state = 1;
            }
        }
    }
    public function UpdateGumBomb()
    {
        if (state == 1)
        {
            type = 1;
            GuineaPig_BubblePops(gunBombNumBits, gunBombTime);
            RemoveObject(RemovePhysObj);
        }
    }
    public function InitGumBomb()
    {
        onHitFunction = OnHitGumBomb;
        updateFunction = UpdateGumBomb;
    }
    
    public function InitGumBombSmall()
    {
        InitGumBomb();
        gunBombNumBits = 32;
        gunBombTime = 6;
    }
    
    public function InitGumBombLarge()
    {
        InitGumBomb();
        gunBombNumBits = 64;
        gunBombTime = 10;
    }
    
    
    
    
    
    public function OnHitMagnet(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        
        var v : Vec = new Vec();
        v.SetFromDxDy(goHitter.xpos - xpos, goHitter.ypos - ypos);
        v.speed = 250;
        if (type == 0)
        {
            goHitter.ApplyForce(v.X(), v.Y());
        }
        else
        {
            goHitter.ApplyForce(-v.X(), -v.Y());
        }
    }
    public function UpdateMagnetPull()
    {
        CycleAnimation();
    }
    public function UpdateMagnet()
    {
        CycleAnimation();
    }
    public function InitMagnet()
    {
        Audio.Loop("sfx_magnet", 99999, 0, 1, true);
        
        onHitFunction = OnHitMagnet;
        updateFunction = UpdateMagnet;
        frameVel = 1;
        frame = 0;
    }
    
    public function InitMagnetPush()
    {
        InitMagnet();
        type = 1;
    }
    public function InitMagnetPull()
    {
        InitMagnet();
        updateFunction = UpdateMagnetPull;
        type = 0;
    }
    
    
    
    public var conveyor_speed : Float;
    public function OnHitConveyor(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
    }
    public function SwitchedConveyor()
    {
        conveyor_speed = -conveyor_speed;
        var conveyor_speedA : Float = Math.abs(conveyor_speed);
        frameVel = Utils.ScaleTo(0, 2, 0, 200, conveyor_speedA);
        if (conveyor_speed < 0)
        {
            frameVel = -frameVel;
        }
        
        var b : Body = nape_bodies[0];
        
        gmat.identity();
        gmat.rotate(dir);
        var p : Point = new Point(conveyor_speed, 0);
        p = gmat.transformPoint(p);
        
        b.surfaceVel = new Vec2(p.x, p.y);
    }
    public function UpdateConveyor()
    {
        CycleAnimation();
    }
    public function InitConveyor()
    {
        Utils.GetParams(initParams);
        
        conveyor_speed = Utils.GetParamNumber("conveyor_speed", 50);
        
        var conveyor_speedA : Float = Math.abs(conveyor_speed);
        frameVel = Utils.ScaleTo(0, 2, 0, 200, conveyor_speedA);
        if (conveyor_speed < 0)
        {
            frameVel = -frameVel;
        }
        
        
        switchFunction = SwitchedConveyor;
        
        onHitFunction = OnHitConveyor;
        updateFunction = UpdateConveyor;
        var b : Body = nape_bodies[0];
        
        gmat.identity();
        gmat.rotate(dir);
        var p : Point = new Point(conveyor_speed, 0);
        p = gmat.transformPoint(p);
        
        b.surfaceVel = new Vec2(p.x, p.y);
    }
    
    
    
    
    
    
    public function UpdateGameObjJoint_SwitchedDistance()
    {
        var dj : DistanceJoint = try cast(jointController_joints[0], DistanceJoint) catch(e:Dynamic) null;
        
        dj.jointMax += yvel;
        if (dj.jointMax > jointMaxDist)
        {
            dj.jointMax = jointMaxDist;
        }
        if (dj.jointMax < jointMinDist)
        {
            dj.jointMax = jointMinDist;
        }
        dj.jointMin = dj.jointMax;
    }
    public function SwitchGameObjJoint_SwitchedDistance()
    {
        yvel *= -1;
    }
    
    public var jointMinDist : Float;
    public var jointMaxDist : Float;
    public function InitGameObjJoint_SwitchedDistance1(cons : Array<Constraint>)
    {
        InitGameObjJoint_SwitchedDistance(cons);
        jointMinDist = jointMaxDist / 2;
    }
    
    
    public function InitGameObjJoint_SwitchedDistance(cons : Array<Constraint>)
    {
        yvel = 2;
        jointController_joints = [];
        for (c in cons)
        {
            jointController_joints.push(c);
        }
        switchFunction = SwitchGameObjJoint_SwitchedDistance;
        renderFunction = RenderJointRenderer;
        updateFunction = UpdateGameObjJoint_SwitchedDistance;
        
        switchName = Game.GetSwitchJointName(id);
        
        jointMaxDist = 200;
        
        for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(jointController_joints) type: null */ in jointController_joints)
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
                
                jointMaxDist = Utils.DistBetweenPoints(p0.x, p0.y, p1.x, p1.y);
                Utils.print("jointMaxDist " + jointMaxDist);
            }
        }
        
        jointMinDist = jointMaxDist / 4;
    }
    
    public function UpdateJoint_RotateSwitch()
    {
        var minAng : Float = 0;
        var maxAng : Float = 0;
        for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(jointController_joints) type: null */ in jointController_joints)
        {
            if (Std.is(c, AngleJoint))
            {
                var aj : AngleJoint = try cast(c, AngleJoint) catch(e:Dynamic) null;
                minAng = aj.jointMin;
                maxAng = aj.jointMax;
            }
        }
        for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(jointController_joints) type: null */ in jointController_joints)
        {
            if (Std.is(c, PivotJoint))
            {
                var pv : PivotJoint = try cast(c, PivotJoint) catch(e:Dynamic) null;
                
                pv.body2.angularVel = 0;
                if (rotVel < 0)
                {
                    if (pv.body2.rotation > minAng)
                    {
                        pv.body2.angularVel = rotVel;
                    }
                }
                else if (rotVel > 0)
                {
                    if (pv.body2.rotation < maxAng)
                    {
                        pv.body2.angularVel = rotVel;
                    }
                }
            }
        }
    }
    public function SwitchJoint_RotateSwitch()
    {
        rotVel *= -1;
    }
    public function InitJoint_RotateSwitch(cons : Array<Constraint>)
    {
        rotVel = 5;
        CopyJointDataToGO(cons);
        switchFunction = SwitchJoint_RotateSwitch;
        updateFunction = UpdateJoint_RotateSwitch;
        visible = false;
    }
    
    public function UpdateJoint_RotateSwitch_StopGo()
    {
        dir += rotVel;
        
        var m : Matrix = new Matrix();
        var p : Point = new Point(jointObjBody_xoff, jointObjBody_yoff);
        m.rotate(rotVel);
        p = m.transformPoint(p);
        jointObjBody_xoff = p.x;
        jointObjBody_yoff = p.y;
        
        var dt : Float = 1 / 60;
        
        jointObjBody.setVelocityFromTarget(new Vec2((xpos + p.x), (ypos + p.y)), dir, dt);
    }
    
    public function SwitchJoint_RotateSwitch_StopGo()
    {
        switchFlag = (switchFlag == false);
        if (switchFlag == false)
        {
            rotVel = 0.02;
        }
        else
        {
            rotVel = 0;
        }
    }
    
    public var jointObjBody : Body;
    public var jointObjBody_xoff : Float;
    public var jointObjBody_yoff : Float;
    public function InitJoint_RotateSwitch_StopGo(cons : Array<Constraint>)
    {
        name = "poocock2";
        rotVel = 0.02;
        CopyJointDataToGO(cons);
        switchFunction = SwitchJoint_RotateSwitch_StopGo;
        updateFunction = UpdateJoint_RotateSwitch_StopGo;
        visible = false;
        switchFlag = false;
        
        for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(jointController_joints) type: null */ in jointController_joints)
        {
            if (Std.is(c, PivotJoint))
            {
                var pv : PivotJoint = try cast(c, PivotJoint) catch(e:Dynamic) null;
                
                pv.body2.angularVel = rotVel;
                pv.body2.type = BodyType.KINEMATIC;
                jointObjBody = pv.body2;
                dir = jointObjBody.rotation;
                jointObjBody_xoff = jointObjBody.position.x - pv.anchor1.x;
                jointObjBody_yoff = jointObjBody.position.y - pv.anchor1.y;
                
                xpos = pv.anchor1.x;
                ypos = pv.anchor1.y;
            }
        }
        
        for (j/* AS3HX WARNING could not determine type for var: j exp: EIdent(jointController_joints) type: null */ in jointController_joints)
        {
            if (PhysicsBase.GetNapeSpace().constraints.has(j))
            {
                PhysicsBase.GetNapeSpace().constraints.remove(j);
            }
        }
    }
    
    
    
    
    
    
    public function CopyJointDataToGO(cons : Array<Constraint>)
    {
        jointController_joints = [];
        for (c in cons)
        {
            jointController_joints.push(c);
        }
    }
    public function InitJoint_Render(cons : Array<Constraint>)
    {
        CopyJointDataToGO(cons);
        renderFunction = RenderJointRenderer;
    }
    public function JointObject_JointRemoved(j : Constraint)
    {
        for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(jointController_joints) type: null */ in jointController_joints)
        {
            if (c == j)
            {
                var aaa : Int = 0;
                RemoveObject();
            }
        }
    }
    
    
    
    
    public function GameObj_UpdateHelpText() : Void
    {
        if (state == 0)
        {
            if (logicLink0 != null)
            {
                state = 3;
            }
            
            visible = false;
            timer--;
            if (timer <= 0)
            {
                state = 1;
                visible = true;
                timer = timerMax = Defs.fps * 2;
            }
        }
        else if (state == 1)
        {
            SFX_OneShot("sfx_text_appear");
            
            PlayAnimation();
            visible = true;
            scale = 0;
            state = 2;
            timer = timerMax = Defs.fps * 2;
        }
        else if (state == 2)
        {
            var f : Float = Utils.ScaleTo(1, 0, 0, timerMax, timer);
            f = Ease.Spring_Out(f);
            scale = f * 1;
            if (scale < 0)
            {
                scale = 0;
            }
            
            timer--;
            if (timer <= 0)
            {
                timer = 0;
            }
        }
        else if (state == 3)
        {
        }
    }
    
    public function GameObj_RenderHelpText_WithMarker() : Void
    {
        GameObj_RenderHelpText();
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        var dob : DisplayObj = GraphicObjects.GetDisplayObjByName("walkthroughMarker");
        dob.RenderAt(0, bd, xp - 25, yp - 10);
    }
    public function GameObj_RenderHelpText() : Void
    {
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        TextRenderer.RenderAt(bd, xp, yp, textMessage, dir, scale, TextRenderer.JUSTIFY_CENTRE, ct);
    }
    
    public function OnSwitch_HelpText() : Void
    {
        if (state == 3)
        {
            state = 0;
            logicLink0 = null;
        }
    }
    
    public function GameObj_InitHelpTextW_WithMarker() : Void
    {
        GameObj_InitHelpTextW();
        renderFunction = GameObj_RenderHelpText_WithMarker;
    }
    public function GameObj_InitHelpTextW() : Void
    {
        updateInWalkthrough = true;
        name = "walkthrough";
        Utils.GetParams(initParams);
        
        textMessage = Utils.GetParamString("helptext_text", "helptxt");
        timer = as3hx.Compat.parseInt(Utils.GetParamNumber("helptext_initialdelay", 0) * Defs.fps);
        var c : String = Utils.GetParamString("helptext_color");
        ct = Utils.HexStringToColorTransform(c);
        updateFunction = GameObj_UpdateHelpText;
        renderFunction = GameObj_RenderHelpText;
        zpos = -10000;
        frame = 0;
        state = 3;
        scale = 1;
        
        if (Game.doWalkthrough == false)
        {
            RemoveObject();
            visible = false;
        }
    }
    public function GameObj_InitHelpText() : Void
    {
        name = "text";
        Utils.GetParams(initParams);
        
        textMessage = Utils.GetParamString("helptext_text", "helptxt");
        timer = as3hx.Compat.parseInt(Utils.GetParamNumber("helptext_initialdelay", 0) * Defs.fps);
        var c : String = Utils.GetParamString("helptext_color");
        ct = Utils.HexStringToColorTransform(c);
        updateFunction = GameObj_UpdateHelpText;
        renderFunction = GameObj_RenderHelpText;
        zpos = -10000;
        frame = 0;
        state = 0;
        
        switchFunction = OnSwitch_HelpText;
        visible = false;
        scale = 0;
        
        if (Game.doWalkthrough == true)
        {
            RemoveObject();
            visible = false;
        }
    }
    
    
    public function GameObj_UpdateHelpObject() : Void
    {
        if (state == 0)
        {
            visible = false;
            timer--;
            if (timer <= 0)
            {
                state = 1;
                visible = true;
            }
        }
        else if (state == 1)
        {
            PlayAnimation();
            visible = true;
            state = 2;
        }
        else if (state == 2)
        {
            PlayAnimation();
        }
        else if (state == 3)
        {
        }
    }
    
    public function GameObj_InitHelpObject() : Void
    {
        name = "text";
        Utils.GetParams(initParams);
        
        timer = as3hx.Compat.parseInt(Utils.GetParamNumber("helptext_initialdelay", 0) * Defs.fps);
        updateFunction = GameObj_UpdateHelpObject;
        zpos = -10000;
        frame = 0;
        state = 0;
        
        switchName = Game.GetSwitchJointName(id);
        
        if (switchName != "")
        {
            state = 3;
            switchFunction = OnSwitch_HelpText;
        }
        visible = false;
    }
    
    
    
    
    
    public function GameObj_UpdateHelpObjectAppear() : Void
    {
        if (state == 0)
        {
            visible = false;
            timer--;
            if (timer <= 0)
            {
                state = 1;
                visible = true;
            }
        }
        else if (state == 1)
        {
            CycleAnimation();
            visible = true;
            state = 2;
        }
        else if (state == 2)
        {
            CycleAnimation();
        }
        else if (state == 3)
        {
        }
    }
    
    public function GameObj_InitHelpObjectAppear() : Void
    {
        name = "text";
        Utils.GetParams(initParams);
        
        timer = as3hx.Compat.parseInt(Utils.GetParamNumber("helptext_initialdelay", 0) * Defs.fps);
        updateFunction = GameObj_UpdateHelpObjectAppear;
        zpos = -10000;
        frame = 0;
        state = 0;
        
        switchName = Game.GetSwitchJointName(id);
        
        if (switchName != "")
        {
            state = 3;
            switchFunction = OnSwitch_HelpText;
        }
        visible = false;
    }
    
    
    
    public function GameObj_RenderHelpText_Walkthrough() : Void
    {
        if (Game.doWalkthrough == false)
        {
            return;
        }
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        (untyped dobj.origMC).helpClip.help.text = Std.string(textMessage);
        dobj.RenderAtRotScaled_Vector(Std.int(frame), bd, xp, yp, 1, 0, null, false, xflip);
    }
    
    public function UpdateWalkthroughObject() : Void
    {
        if (state == 0)
        {
            visible = false;
            timer--;
            if (timer <= 0)
            {
                state = 1;
                visible = true;
                timer = timerMax = Defs.fps * 2;
            }
        }
        else if (state == 1)
        {
        }
    }
    public function InitWalkthroughObject() : Void
    {
        updateInWalkthrough = true;
        name = "walkthrough";
        updateFunction = UpdateWalkthroughObject;
        timer = as3hx.Compat.parseInt(Utils.GetParamNumber("helptext_initialdelay", 0) * Defs.fps);
        
        state = 0;
        if (Game.doWalkthrough == false)
        {
            RemoveObject();
            visible = false;
        }
    }
    
    
    
    
    
    public function RenderRain()
    {
        for (i in 0...20)
        {
            var x : Float = Utils.RandBetweenFloat(0, Defs.displayarea_w);
            var y : Float = Utils.RandBetweenFloat(0, Defs.displayarea_h);
            frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
            dobj.RenderAt(Std.int(frame), bd, x, y);
        }
    }
    public function UpdateRain()
    {
    }
    public function InitRain()
    {
        renderFunction = RenderRain;
        updateFunction = UpdateRain;
    }
    
    
    
    
    public function RenderWidescreen()
    {
        if (false)
        {
            return;
        }
        var r : Rectangle = new Rectangle(0, 0, Defs.displayarea_w, 0);
        r.height = ypos;
        bd.fillRect(r, 0xff000000);
        r.height = ypos;
        r.y = Defs.displayarea_h - ypos;
        bd.fillRect(r, 0xff000000);
    }
    public function UpdateWidescreen()
    {
        if (state == 0)
        {
            timer++;
            var t : Float = Utils.ScaleTo(0, 1, 0, timerMax, timer);
            t = Ease.Power_In(t, 2);
            ypos = Utils.ScaleTo(0, 100, 0, 1, t);
            
            if (timer >= timerMax)
            {
                timer = timerMax;
                state = 1;
                timer = as3hx.Compat.parseInt(Defs.fps * 7);
            }
        }
        else if (state == 1)
        {
            timer--;
            if (timer <= 0)
            {
                timer = timerMax;
                state = 2;
            }
        }
        else if (state == 2)
        {
            timer--;
            var t : Float = Utils.ScaleTo(0, 1, 0, timerMax, timer);
            t = Ease.Power_In(t, 2);
            ypos = Utils.ScaleTo(0, 100, 0, 1, t);
            if (timer <= 0)
            {
                timer = 0;
                state = 3;
            }
        }
    }
    public function InitWidescreen()
    {
        renderFunction = RenderWidescreen;
        updateFunction = UpdateWidescreen;
        state = 0;
        timer = 0;
        timerMax = 30;
    }
    
    
    
    
    
    
    
    
    
    public function MiniGamePickup_Collected()
    {
        state = 1;
        
        MiniGame.score += 10;
        
        dobj = GraphicObjects.GetDisplayObjByName("collectPickup");
        frame = 0;
        SFX_OneShot("sfx_pickup_gold");
    }
    public function UpdateMiniGamePickup()
    {
        if (state == 0)
        {
            timer1 += 0.1;
            timer2 += 0.05;
            xpos = startx + Math.cos(timer1) * 3;
            ypos = starty + Math.cos(timer2) * 3;
            
            
            timer--;
            if (timer <= 0)
            {
                RemoveObject();
            }
        }
        else if (state == 1)
        {
            if (PlayAnimation())
            {
                RemoveObject();
            }
        }
    }
    public function InitMiniGamePickup()
    {
        name = "pickup";
        updateFunction = UpdateMiniGamePickup;
        xpos = Utils.RandBetweenInt(50, Defs.displayarea_w - 50);
        ypos = Utils.RandBetweenInt(100, 150);
        var r : Int = Utils.RandBetweenInt(1, 8);
        var s : String = "Animal" + r + "_gold";
        dobj = GraphicObjects.GetDisplayObjByName(s);
        timer = as3hx.Compat.parseInt(Defs.fps * 5);
        startx = xpos;
        starty = ypos;
        timer1 = Utils.RandBetweenFloat(0, 100);
        timer2 = Utils.RandBetweenFloat(0, 100);
    }
    
    
    
    
    
    
    public function UpdatePlaybackCursor()
    {
    }
    public function InitPlaybackCursor()
    {
        updateFunction = UpdatePlaybackCursor;
        dobj = GraphicObjects.GetDisplayObjByName("Cursor_Walkthrough_Pointer");
        frame = 0;
    }
    
    public function UpdatePlaybackClick()
    {
        if (PlayAnimation())
        {
            RemoveObject();
        }
    }
    public function InitPlaybackClick()
    {
        updateFunction = UpdatePlaybackClick;
        dobj = GraphicObjects.GetDisplayObjByName("Walkthrough_click");
        frame = 0;
    }
    
    
    
    
    
    public function OnHitCannon(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        
        var cando : Bool = false;
        if (goHitter.name == "football")
        {
            cando = true;
        }
        else if (goHitter.name == "spikyball")
        {
            cando = true;
        }
        
        if (cando == false)
        {
            return;
        }
        
        if (state == 0)
        {
            state = 1;
            timer = GameVars.cannonHoldTime;
            goHitter.Football_InitHoldInCannon(this);
            SFX_OneShot("sfx_enter_cannon");
        }
    }
    public function Cannon_Fired()
    {
        state = 2;
        timer = timerMax = Defs.fps;
    }
    public function RenderCannon()
    {
        RenderDispObjNormally();
        RenderDispObjAt(xpos, ypos, dobj1, 0, null, 0, 1, true);
        if (dobj2 != null)
        {
            RenderDispObjAt(xpos, ypos, dobj2, Std.int(frame2), null, dir, 1, true);
        }
    }
    public function UpdateCannon()
    {
        if (updateFunction1 != null)
        {
            updateFunction1();
        }
        if (state == 0)
        {
            frame = 0;
        }
        else if (state == 1)
        {
        }
        else if (state == 2)
        {
            var p : Point = new Point(0, -25);
            var m : Matrix = new Matrix();
            m.rotate(dir);
            p = m.transformPoint(p);
            
            var xp : Float = xpos + p.x;
            var yp : Float = ypos + p.y;
            
            
            state = 3;
            PlayAnimation();
            SFX_OneShot("sfx_cannon_fire");
            
            dobj2 = GraphicObjects.GetDisplayObjByName("cannonSmoke");
            frame2 = 0;
            frameVel2 = 0.5;
        }
        else if (state == 3)
        {
            if (dobj2 != null)
            {
                if (PlayAnimation2())
                {
                    dobj2 = null;
                }
            }
            
            PlayAnimation();
            timer--;
            if (timer <= 0)
            {
                state = 0;
            }
        }
    }
    public function InitFixedCannon()
    {
        updateFunction = UpdateCannon;
        onHitFunction = OnHitCannon;
        renderFunction = RenderCannon;
        dobj1 = GraphicObjects.GetDisplayObjByName("cannon_base");
        dobj2 = null;
        frame2 = 0;
    }
    
    
    
    
    
    public var ballLaunch_vec : Vec;
    public var ballLaunch_dist : Float;
    
    public var football_CannonObj : GameObj = null;
    public function Football_InitHoldInCannon(goCannon : GameObj)
    {
        football_CannonObj = goCannon;
        state = 200;
        timer = GameVars.cannonHoldTime;
    }
    
    public function Football_CanSnapToPlayer(_go : GameObj) : Bool
    {
        if (state == 200)
        {
            return false;
        }
        if (state == 1)
        {
            return false;
        }
        if (state == 4)
        {
            return false;
        }
        if (state == 2)
        {
            if (footballHitSomthing)
            {
                return true;
            }
            if (football_lastPlayerToHaveBall == _go)
            {
                if (ballTimer < Defs.fps)
                {
                    return false;
                }
            }
            return true;
        }
        return true;
    }
    
    public function Football_SnapToPlayer(_go : GameObj)
    {
        football_playerGO = _go;
        football_playerGO.Player_SetHasFootball(this);
        state = 1;
        xpos = football_playerGO.xpos;
        ypos = football_playerGO.ypos + GameVars.football_footOffsetY;
        SetBodyXForm_Immediate(0, xpos, ypos, 0);
        SetBodyAngularVelocity(0, 0);
        SetBodyLinearVelocity(0, 0, 0);
        PhysicsSetStationary();
    }
    public function Football_DribbleWithPlayer()
    {
        state = 1;
        xpos = football_playerGO.xpos;
        ypos = football_playerGO.ypos + GameVars.football_footOffsetY;
        SetBodyXForm_Immediate(0, xpos, ypos, 0);
        SetBodyAngularVelocity(0, 0);
        SetBodyLinearVelocity(0, 0, 0);
        PhysicsSetStationary();
    }
    
    
    public function Football_MoveToPlayer(_go : GameObj)
    {
        SFX_OneShot("sfx_ball_return");
        SetBodyCollisionMask(-1, 0);
        SetBodySensorMask(-1, 0);
        
        football_playerGO = _go;
        state = 4;
        SetBodyXForm_Immediate(0, xpos, ypos, 0);
        SetBodyAngularVelocity(0, 0);
        SetBodyLinearVelocity(0, 0, 0);
        toPosX = football_playerGO.xpos;
        toPosY = football_playerGO.ypos + GameVars.football_footOffsetY;
        startx = xpos;
        starty = ypos;
        timer = timerMax = Defs.fps / 2;
        PhysicsSetStationary();
    }
    
    public function Football_Launch(_v : Vec)
    {
        PhysicsSetMovable();
        SetBodyAngularVelocity(0, 0);
        SetBodyLinearVelocity(0, 0, 0);
        ballLaunch_vec.Set(_v.rot, _v.speed);
        ApplyImpulse(ballLaunch_vec.X(), ballLaunch_vec.Y());
        state = 2;
        stillTimer = 0;
        ballTimer = 0;
        footballHitSomthing = false;
        // capture the kick (ball pos + resulting launch velocity) for the bounce debugger / replay
        if (nape_bodies != null && nape_bodies.length > 0 && nape_bodies[0] != null)
            BounceDebug.RecordKick(nape_bodies[0].position.x, nape_bodies[0].position.y, nape_bodies[0].velocity.x, nape_bodies[0].velocity.y);
    }
    public var football_lastPlayerToHaveBall : GameObj;
    public var football_playerGO : GameObj;
    public var previousVel : Vec2;
    public function Football_GenerateSmokePuff()
    {
        var go : GameObj = GameObjects.AddObj(xpos, ypos, zpos - 10);
        go.InitSmokePuff();
        
        var go : GameObj = GameObjects.AddObj(xpos, ypos - 10, -10000);
        go.InitPlusOnePopup();
        if (go.xpos > Game.boundingRectangle.right - 10)
        {
            go.xpos -= 80;
        }
        if (go.xpos < Game.boundingRectangle.left + 10)
        {
            go.xpos += 80;
        }
        if (go.ypos < Game.boundingRectangle.top + 10)
        {
            go.ypos += 80;
        }
    }
    
    public function UpdateFootball()
    {
        previousVel = GetBodyLinearVelocity(0).copy();
        if (state == 0)
        {
            var go : GameObj = GameObjects.GetNearestGameObjByName("player", xpos, ypos);
            if (go != null)
            {
                Football_SnapToPlayer(go);
            }
        }
        else if (state == 1)
        {
            GameVars.doingFastForward = false;
            if (football_playerGO.xflip == false)
            {
                xpos = football_playerGO.xpos + GameVars.football_footOffsetX;
            }
            else
            {
                xpos = football_playerGO.xpos - GameVars.football_footOffsetX;
            }
            SetBodyXForm_Immediate(0, xpos, ypos, 0);
            SetBodyLinearVelocity(0, 0, 0);
            SetBodyAngularVelocity(0, 0);
            
            
            if (GameVars.numKicks >= GameVars.maxKicks)
            {
                GameVars.numKicks = GameVars.maxKicks;
                Game.levelSuccessFlag = false;
                Audio.OneShot("sfx_levelfailed");
                Game.InitLevelState(Game.levelState_Complete);
                state = 999;
                football_playerGO.state = 999;
            }
        }
        else if (state == 2)
        {
            if (Game.levelState == Game.levelState_Play)
            {
                ballTimer++;
                
                if (ballTimer >= GameVars.ballTimerShowTimerMax)
                {
                    if ((ballTimer % 20) == 0)
                    {
                        SFX_OneShot("sfx_tick", 0.5);
                    }
                }
                if (ballTimer >= GameVars.ballTimerMax)
                {
                    GameVars.numKicks++;
                    state = 3;
                    PhysicsSetStationary();
                }
            }
            
            if (Game.boundingRectangle.contains(xpos, ypos) == false)
            {
                GameVars.numKicks++;
                state = 3;
                PhysicsSetStationary();
            }
        }
        else if (state == 3)
        {
            Football_GenerateSmokePuff();
            Football_MoveToPlayer(football_playerGO);
        }
        else if (state == 4)
        {
            timer--;
            if (timer <= 0)
            {
                timer = 0;
                football_playerGO.Player_SetHasFootball(this);
                state = 1;
                
                SetBodyCollisionMask(-1, origCollisionMask);
                SetBodySensorMask(-1, origSensorMask);
            }
            var v : Float = Utils.ScaleTo(0, 1, timerMax, 0, timer);
            v = Ease.Power_InOut(v);
            xpos = Utils.ScaleTo(startx, toPosX, 0, 1, v);
            ypos = Utils.ScaleTo(starty, toPosY, 0, 1, v);
            SetBodyXForm_Immediate(0, xpos, ypos, 0);
            SetBodyAngularVelocity(0, 0);
            SetBodyLinearVelocity(0, 0, 0);
        }
        else if (state == 200)
        {
            visible = true;
            xpos = football_CannonObj.xpos;
            ypos = football_CannonObj.ypos;
            PhysicsSetStationary();
            timer--;
            if (timer <= 0)
            {
                updateFromPhysicsFunction = null;
                
                
                ballLaunch_vec.SetAng(football_CannonObj.dir - (Math.PI / 2));
                ballLaunch_vec.speed = Vars.GetVarAsNumber("cannonLaunchForce");
                
                ballLaunch_vec.speed *= GetBodyMass(0);
                
                timer = timerMax = Defs.fps * 3;
                
                
                football_CannonObj.Cannon_Fired();
                visible = true;
                
                Football_Launch(ballLaunch_vec);
            }
        }
        
        if (GameVars.useFeature4)
        {
            FootballGenerateSparkle();
        }
    }
    
    public var footballHitSomthing : Bool;
    public function OnHit_Football(hitterGO : GameObj)
    {
        if (hitterGO == null)
        {
            return;
        }
        
        if (hitterGO.name == "spikyball")
        {
            if (state == 2)
            {
                var go : GameObj = GameObjects.AddObj(xpos, ypos, -10000);
                go.InitPopPopup();
                
                
                Football_MoveToPlayer(football_lastPlayerToHaveBall);
            }
        }
        if (hitterGO.name != "player" && hitterGO.name != "pickup" && hitterGO.name != "invisible_switch")
        {
            footballHitSomthing = true;
        }
    }
    public function RenderFootball()
    {
        RenderDispObjNormally();
    }
    public var ballTimer : Int = 0;
    public function InitFootball_Beachball()
    {
        InitFootball();
        collisionType = "beachball";
    }
    
    public var origSensorMask : Int = 0;
    public var origCollisionMask : Int = 0;
    
    public function InitFootball()
    {
        origCollisionMask = GetBodyCollisionMask();
        origSensorMask = GetBodySensorMask();
        
        
        collisionType = "football";
        name = "football";
        renderFunction = RenderFootball;
        updateFunction = UpdateFootball;
        onHitFunction = OnHit_Football;
        state = 0;
        
        
        ballLaunch_vec = new Vec();
        ballTimer = 0;
        dobj1 = GraphicObjects.GetDisplayObjByName("generalTimer");
        
        var go : GameObj = GameObjects.AddObj(xpos, ypos, -10000);
        go.InitFootballOverlayObject();
        go.parentObj = this;
        
        if (GameVars.useFeature4)
        {
            dobj = GraphicObjects.GetDisplayObjByName("football_gold");
        }
    }
    
    
    public function RenderFootballOverlayObject()
    {
        if (Game.controlMode == 0)
        {
            if (parentObj.state == 1)
            {
                Game.RenderBallPath(bd, parentObj.xpos - Game.camera.x, parentObj.ypos - Game.camera.y, Game.ballpath_dx, Game.ballpath_dy);
            }
        }
        else if (parentObj.state == 1 && Game.scrollMode == 2)
        {
            Game.RenderBallPath(bd, parentObj.xpos - Game.camera.x, parentObj.ypos - Game.camera.y, Game.ballpath_dx, Game.ballpath_dy);
        }
        
        var renderArrow : Bool = false;
        if (false)
        {
            if (Game.scrollMode == 2)
            {
                renderArrow = true;
            }
        }
        else if (parentObj.football_playerGO != null)
        {
            if (parentObj.football_playerGO.state == 1)
            {
                renderArrow = true;
            }
        }
        
        if (renderArrow)
        {
            var r : Float = parentObj.football_playerGO.ballLaunch_vec.rot + (Math.PI / 2);
            var dob : DisplayObj = GraphicObjects.GetDisplayObjByName("powerArrow");
            var p : Point = new Point(0, -10);
            var m : Matrix = new Matrix();
            m.rotate(r);
            p = m.transformPoint(p);
            
            var xp : Float = parentObj.xpos - Game.camera.x;
            var yp : Float = parentObj.ypos - Game.camera.y;
            
            var kick_dist0 : Float = Vars.GetVarAsNumber("kick_dist0");
            var kick_dist1 : Float = Vars.GetVarAsNumber("kick_dist1");
            
            if (false)
            {
                kick_dist0 = 30;
                kick_dist1 = Defs.displayarea_h2 * 0.4;
            }
            
            var scl : Float = Utils.ScaleToPreLimit(0.5, 1, kick_dist0, kick_dist1, parentObj.football_playerGO.ballLaunch_dist);
            dob.RenderAtRotScaled(0, bd, xp + p.x, yp + p.y, scl, r, null, true);
        }
        
        
        if (parentObj.state == 2 && parentObj.ballTimer > GameVars.ballTimerShowTimerMax)
        {
            var xp : Float = Math.round(parentObj.xpos) - Math.round(Game.camera.x);
            var yp : Float = Math.round(parentObj.ypos) - Math.round(Game.camera.y);
            var f : Float = Utils.ScaleTo(0, parentObj.dobj1.GetNumFrames() - 1, 0, GameVars.ballTimerMax, parentObj.ballTimer);
            parentObj.dobj1.RenderAt(Std.int(f), bd, xp, yp - 20);
        }
    }
    public function InitFootballOverlayObject()
    {
        renderFunction = RenderFootballOverlayObject;
    }
    
    
    public function OnHitPlayer(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (Game.levelState == Game.levelState_Complete)
        {
            return;
        }
        if (goHitter.name == "football")
        {
            if (goHitter.Football_CanSnapToPlayer(this))
            {
                goHitter.Football_SnapToPlayer(this);
            }
        }
    }
    
    public function PlayerFaceToBall()
    {
        var ballGO : GameObj = GameVars.footballGO;
        xflip = false;
        if (ballGO.xpos < xpos)
        {
            xflip = true;
        }
    }
    public function Player_InitRunToMarker(_x : Float)
    {
        state = 10;
        SetAnimRangeSingle("run1");
        toPosX = _x;
        xvel = 3;
    }
    public function UpdatePlayer()
    {
        var ballGO : GameObj = GameVars.footballGO;
        
        
        var runMarkerA : GameObj = null;
        var runMarkerB : GameObj = null;
        for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameVars),runMarkers) type: null */ in GameVars.runMarkers)
        {
            if (go.logicLink1 == this)
            {
                if (runMarkerA == null)
                {
                    runMarkerA = go;
                }
                else
                {
                    runMarkerB = go;
                }
            }
        }
        
        
        
        if (state == 0)
        {
            PlayerFaceToBall();
            player_currentFootball = null;
            PlayerUpdateIdleAnim();
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
        }
        else if (state == 1)
        {
            if (Game.controlMode == 0)
            {
                Game.scrollMode = 1;
            }
            
            // The raw pointer-down click-kick. Suppress it for mobile schemes B/C — they route kicks
            // through their own tap handler (MobileControls / MobileAimPad -> Game.doKick on tap-UP), so
            // without this guard a scheme-C tap fires twice (this raw down-kick + the aim-pad up-kick).
            // Mirrors the same guard on MouseClickHandler (Game.hx).
            if (Game.controlMode != 0 || (Settings.mobileControlScheme != Settings.SCHEME_B && Settings.mobileControlScheme != Settings.SCHEME_C))
            {
                if (MouseControl.buttonPressed)
                {
                    if (MouseControl.y < 487)
                    {
                        Game.doKick = true;
                        MouseControl.buttonPressed = false;
                    }
                }
            }
            
            
            var mx : Float = Game.mouse_x + Game.camera.x;
            var my : Float = Game.mouse_y + Game.camera.y;
            
            var marker : Int = 0;
            var doaiming : Bool = true;
            if (runMarkerB != null)
            {
                if (Utils.DistBetweenPoints(mx, my, runMarkerB.xpos, runMarkerB.ypos) < 60)
                {
                    marker = 1;
                    doaiming = false;
                }
            }
            if (runMarkerA != null)
            {
                if (Utils.DistBetweenPoints(mx, my, runMarkerA.xpos, runMarkerA.ypos) < 60)
                {
                    marker = 0;
                    doaiming = false;
                }
            }
            
            if (doaiming == false)
            {
                Game.ballpath_doit = false;
                if (Game.doKick)
                {
                    Game.doKick = false;
                    if (marker == 0)
                    {
                        Player_InitRunToMarker(runMarkerA.xpos);
                    }
                    if (marker == 1)
                    {
                        Player_InitRunToMarker(runMarkerB.xpos);
                    }
                }
            }
            else
            {
                Game.ballpath_doit = true;
                
                if (false == false)
                {
                    xflip = false;
                    if ((mx) < xpos)
                    {
                        xflip = true;
                    }
                }
                else
                {
                    xflip = false;
                    if ((mx) > xpos)
                    {
                        xflip = true;
                    }
                }
                PlayerUpdateIdleAnim();
                
                
                var dx : Float = Math.NaN;                var dy : Float = Math.NaN;                if (Game.controlMode == 0)
                {
                    dx = (mx) - ballGO.xpos;
                    dy = (my) - ballGO.ypos;
                }
                else
                {
                    var cx : Float = Defs.displayarea_w / 2;
                    var cy : Float = Defs.displayarea_h / 2;
                    
                    dx = cx - Game.mouse_x;
                    dy = cy - Game.mouse_y;
                }
                
                
                var kick_dist0 : Float = Vars.GetVarAsNumber("kick_dist0");
                var kick_dist1 : Float = Vars.GetVarAsNumber("kick_dist1");
                var kick_power0 : Float = Vars.GetVarAsNumber("kick_power0");
                var kick_power1 : Float = Vars.GetVarAsNumber("kick_power1");
                if (ballGO.collisionType == "beachball")
                {
                    kick_power0 = Vars.GetVarAsNumber("kick_power0_beachball");
                    kick_power1 = Vars.GetVarAsNumber("kick_power1_beachball");
                }
                
                if (false)
                {
                    kick_dist0 = 30;
                    kick_dist1 = Defs.displayarea_h2 * 0.4;
                }
                
                
                var dist : Float = Utils.DistBetweenPoints(0, 0, dx, dy);
                ballLaunch_dist = dist;
                var spd : Float = Utils.ScaleToPreLimit(kick_power0, kick_power1, kick_dist0, kick_dist1, dist);
                
                ballLaunch_vec.SetFromDxDy(dx, dy);
                ballLaunch_vec.speed = spd;
                
                
                var path_vec : Vec = new Vec();
                path_vec.SetFromDxDy(dx, dy);
                path_vec.speed = Utils.ScaleToPreLimit(Vars.GetVarAsNumber("kick_power0"), Vars.GetVarAsNumber("kick_power1"), kick_dist0, kick_dist1, dist);
                
                Game.ballpath_dx = ballLaunch_vec.X();
                Game.ballpath_dy = ballLaunch_vec.Y();
                Game.ballpath_mass = ballGO.GetBodyMass(0);
                
                
                DoBallLine(ballGO.xpos, ballGO.ypos, Game.ballpath_dx, Game.ballpath_dy, ballGO);
                
                
                PlayerHeadFollowPoint(Game.mouse_x + Game.camera.x, Game.mouse_y + Game.camera.y);
                
                var doKick : Bool = false;
                
                if (Game.doKick)
                {
                    doKick = true;
                    Game.doKick = false;
                }
                
                if (doKick)
                {
                    SetAnimRangeSingle("kick3");
                    state = 2;
                    
                    if (Game.controlMode == 0)
                    {
                        Game.scrollMode = 0;
                    }
                }
            }
        }
        else if (state == 2)
        {
            var done : Bool = PlayAnimationEx();
            if (player_currentFootball != null)
            {
                if (dobj.GetLabelAtThisFrame(Std.int(frame)) == "release_ball")
                {
                    var rand : Int = Utils.RandBetweenInt(1, 2);
                    SFX_OneShot("sfx_kick_football" + rand);
                    
                    
                    player_currentFootball.Football_Launch(ballLaunch_vec);
                    player_currentFootball.football_lastPlayerToHaveBall = this;
                    
                    player_currentFootball = null;
                    GameVars.numKicks++;
                }
            }
            if (done)
            {
                PlayerUpdateIdleAnim();
                state = 3;
            }
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
        }
        else if (state == 3)
        {
            PlayerFaceToBall();
            PlayerUpdateIdleAnim();
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
        }
        else if (state == 10)
        {
            var highestY : Float = 99999;
            
            var r : Ray = new Ray(new Vec2(xpos, ypos - 50), new Vec2(0, 1));
            r.maxDistance = 100;
            
            var filter : InteractionFilter = new InteractionFilter(1, 1, 0, 0, 0, 0);
            
            var rr : RayResult = PhysicsBase.GetNapeSpace().rayCast(r, false, filter);
            if (rr != null)
            {
                var p : Vec2 = r.at(rr.distance);
                highestY = p.y;
                ypos = highestY;
            }
            
            var xv : Float = xvel;
            
            
            if (xpos < toPosX)
            {
                xflip = false;
                xpos += xv;
                if (xpos >= toPosX)
                {
                    xpos = toPosX;
                    state = 1;
                    PlayerStartIdleAnim();
                }
            }
            else
            {
                xflip = true;
                xpos -= xv;
                if (xpos <= toPosX)
                {
                    xpos = toPosX;
                    state = 1;
                    PlayerStartIdleAnim();
                }
            }
            
            SetBodyXForm(0, xpos, ypos, 0);
            CycleAnimationEx();
            
            if (player_currentFootball != null)
            {
                player_currentFootball.Football_DribbleWithPlayer();
            }
        }
        else if (state == 20)
        {
            if (PlayAnimationEx())
            {
                if (player_currentFootball == null)
                {
                    state = 3;
                    PlayerStartIdleAnim();
                }
                else
                {
                    state = 1;
                    PlayerStartIdleAnim();
                }
            }
        }
        playerHeadAngle = playerHeadToAngle;
    }
    
    public function PlayerStartCelebration()
    {
        SetAnimRangeSingle("goal" + Utils.RandBetweenInt(1, 1));
        state = 20;
    }
    public var idleTimer : Int = 0;
    public var idleState : Int = 0;
    public function PlayerStartIdleAnim()
    {
        idleTimer = 0;
        idleState = 0;
        SetAnimRangeSingle("idle" + Utils.RandBetweenInt(1, 3));
    }
    public function PlayerUpdateIdleAnim()
    {
        if (idleState == 0)
        {
            if (PlayAnimationEx())
            {
                idleState = 1;
            }
        }
        else
        {
            idleTimer--;
            if (idleTimer <= 0)
            {
                SetAnimRangeSingle("idle" + Utils.RandBetweenInt(1, 3));
                idleTimer = Utils.RandBetweenInt(Std.int(Defs.fps), Std.int(Defs.fps * 2));
                idleState = 0;
            }
        }
    }
    
    public function PlayerHeadFollowPoint(x : Float, y : Float)
    {
        var head_dx : Float = (x) - xpos;
        var head_dy : Float = (y) - (ypos - 70);
        
        
        if (xflip)
        {
            playerHeadToAngle = Utils.RadToDeg(Math.atan2(head_dy, head_dx));
            playerHeadToAngle = 180 - playerHeadToAngle;
            if (playerHeadToAngle > 180)
            {
                if (playerHeadToAngle < 360 - 45)
                {
                    playerHeadToAngle = 360 - 45;
                }
            }
            else if (playerHeadToAngle > 45)
            {
                playerHeadToAngle = 45;
            }
        }
        else
        {
            playerHeadToAngle = Utils.RadToDeg(Math.atan2(head_dy, head_dx));
            if (playerHeadToAngle < -45)
            {
                playerHeadToAngle = -45;
            }
            if (playerHeadToAngle > 45)
            {
                playerHeadToAngle = 45;
            }
        }
    }
    
    
    public function Player_SetHasFootball(go : GameObj)
    {
        PlayerStartIdleAnim();
        state = 1;
        player_currentFootball = go;
    }
    public var player_currentFootball : GameObj;
    public function RenderRef()
    {
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        var oldRot : Float = animHierarchy.Frame_SetPartRot("head", Std.int(frame), playerHeadAngle);
        animHierarchy.RenderAt(bd, xp, yp, frame, scale, dir, xflip);
        animHierarchy.Frame_SetPartRot("head", Std.int(frame), oldRot);
    }
    public function RenderPlayer()
    {
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        var oldRot : Float = animHierarchy.Frame_SetPartRot("head", Std.int(frame), playerHeadAngle);
        animHierarchy.RenderAt(bd, xp, yp, frame, scale, dir, xflip);
        animHierarchy.Frame_SetPartRot("head", Std.int(frame), oldRot);
        
        if (GameVars.numKicks == (GameVars.maxKicks - 1) && state == 1)
        {
            var dob : DisplayObj = GraphicObjects.GetDisplayObjByName("popup_lastkick");
            var x : Float = xp;
            var y : Float = yp - 120;
            var s : Float = Math.cos(Game.levelTimer * 0.1) * 0.1;
            s += 1;
            dob.RenderAtRotScaled(0, bd, x, y, s);
        }
    }
    
    
    
    public var team : TeamDef;
    
    public var playerHeadToAngle : Float;
    public var playerHeadAngle : Float;
    public function InitPlayer()
    {
        playerHeadToAngle = playerHeadAngle = 0;
        
        name = "player";
        renderFunction = RenderPlayer;
        updateFunction = UpdatePlayer;
        onHitFunction = OnHitPlayer;
        player_currentFootball = null;
        PhysicsSetStationary();
        PlayerStartIdleAnim();
        ballLaunch_vec = new Vec();
        frameVel = 0.5;
        
        team = GameVars.GetTeam(GameVars.playerTeam);
        
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        
        AddHierarchy_Player(ct0, ct1, ct2, ct3, team.kitStyle);
        scale = 1;
    }
    
    
    
    public function Opponent_KickBall(ok : OppoKick)
    {
        var ballGO : GameObj = GameVars.footballGO;
        var dx : Float = ballGO.xpos - xpos;
        var dy : Float = ballGO.ypos - ypos;
        movementVec.SetFromDxDy(dx, dy);
        movementVec.speed = 150;
        ballGO.ApplyImpulse(movementVec.X(), movementVec.Y());
    }
    public function Opponent_InitKick()
    {
        SetAnimRangeSingle("kick1");
        state = 1;
    }
    
    public function Opponent_InitHeader()
    {
        SetAnimRangeSingle("jump_start");
        state = 20;
    }
    
    public function OpponentStartCommiseration()
    {
        if (state == 0)
        {
            SetAnimRangeSingle("conceed");
            state = 30;
        }
    }
    
    public function RenderOpponent()
    {
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        var oldRot : Float = animHierarchy.Frame_SetPartRot("head", Std.int(frame), playerHeadAngle);
        animHierarchy.RenderAt(bd, xp, yp, frame, scale, dir, xflip);
        animHierarchy.Frame_SetPartRot("head", Std.int(frame), oldRot);
        
        if (oppo_canJumpWhenNear)
        {
            RenderDispObjAt(xpos, ypos - 93, dobj1, Std.int(frame1));
        }
    }
    
    
    public function UpdateOpponent()
    {
        var ballGO : GameObj = GameVars.footballGO;
        var distToBall : Float = Utils.DistBetweenPoints(xpos, ypos, ballGO.xpos, ballGO.ypos);
        if (state == 0)
        {
            PlayerFaceToBall();
            PlayerUpdateIdleAnim();
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
            playerHeadAngle = playerHeadToAngle;
            
            
            if (oppo_canJumpWhenNear)
            {
                CycleAnimation1();
                if (ballGO.ypos < ypos - 80)
                {
                    var distHeadToBall : Float = Utils.DistBetweenPoints(xpos, ypos - 80, ballGO.xpos, ballGO.ypos);
                    if (distHeadToBall < 100)
                    {
                        Opponent_InitHeader();
                    }
                }
            }
            
            if (oppo_canKickWhenNear)
            {
            }
        }
        else if (state == 1)
        {
            if (PlayAnimationEx())
            {
                PlayerStartIdleAnim();
                state = 0;
            }
            
            for (ok/* AS3HX WARNING could not determine type for var: ok exp: EField(EIdent(GameVars),oppo_kick_table) type: null */ in GameVars.oppo_kick_table)
            {
                if (as3hx.Compat.parseInt(frame) == ok.frame)
                {
                    var x : Float = xpos + ok.xoff;
                    if (xflip)
                    {
                        x = xpos - ok.xoff;
                    }
                    var d : Float = Utils.DistBetweenPoints(x, ypos + ok.yoff, ballGO.xpos, ballGO.ypos);
                    if (d < 15)
                    {
                        Utils.print("kick ball");
                        Opponent_KickBall(ok);
                        state = 2;
                    }
                }
            }
        }
        else if (state == 2)
        {
            if (PlayAnimationEx())
            {
                PlayerStartIdleAnim();
                state = 0;
            }
        }
        else if (state == 10)
        {
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
            playerHeadAngle = playerHeadToAngle;
            
            frameVel = 0.4;
            if (PlayAnimationEx())
            {
                frameVel = 0.5;
                PlayerStartIdleAnim();
                state = 0;
            }
        }
        else if (state == 20)
        {
            CycleAnimation1();
            if (PlayAnimationEx())
            {
                SFX_OneShot("sfx_jump");
                
                SetAnimRangeSingle("jumped");
                state = 21;
                yvel = -7;
            }
        }
        else if (state == 21)
        {
            CycleAnimation1();
            PlayAnimationEx();
            ypos += yvel;
            yvel += GameVars.gravity_GO;
            if (ypos >= starty)
            {
                ypos = starty;
                SetBodyXForm(0, xpos, ypos, 0);
                yvel = 0;
                
                
                SetAnimRangeSingle("landing");
                state = 22;
            }
            else
            {
                SetBodyXForm(0, xpos, ypos, 0);
            }
        }
        else if (state == 22)
        {
            CycleAnimation1();
            if (PlayAnimationEx())
            {
                PlayerStartIdleAnim();
                state = 0;
            }
        }
        else if (state == 30)
        {
            if (PlayAnimationEx())
            {
                state = 31;
                SetAnimRangeSingle("conceed_loop");
                timer = Utils.RandBetweenInt(Std.int(Defs.fps * 1), Std.int(Defs.fps * 2));
            }
        }
        else if (state == 31)
        {
            CycleAnimationEx();
            timer--;
            if (timer <= 0)
            {
                PlayerStartIdleAnim();
                state = 0;
            }
        }
        
        if (state == 100)
        {
            for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameVars),jumpMarkers) type: null */ in GameVars.jumpMarkers)
            {
                if (Utils.DistBetweenPoints(xpos, ypos, go.xpos, go.ypos) < 20)
                {
                    var v : Vec = new Vec();
                    v.Set(go.dir, 1);
                    
                    var doit : Bool = false;
                    if (xflip == false)
                    {
                        if (v.X() > 0)
                        {
                            doit = true;
                        }
                    }
                    else if (v.X() < 0)
                    {
                        doit = true;
                    }
                    
                    if (doit)
                    {
                        state = 101;
                        movementVec.Set(go.dir, 5);
                        movementVec.speed *= go.scale;
                        xvel = movementVec.X();
                        yvel = movementVec.Y();
                    }
                }
            }
            
            
            CycleAnimationEx();
            
            
            var ox : Float = xpos;
            xpos += xvel;
            
            
            for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameVars),patrolMarkers) type: null */ in GameVars.patrolMarkers)
            {
                if (Math.abs(go.ypos - ypos) < 20)
                {
                    if (xvel > 0)
                    {
                        if (xpos >= go.xpos && ox < go.xpos)
                        {
                            xpos = go.xpos;
                            xvel = -xvel;
                            xflip = (xflip == false);
                        }
                    }
                    else if (xpos <= go.xpos && ox > go.xpos)
                    {
                        xpos = go.xpos;
                        xvel = -xvel;
                        xflip = (xflip == false);
                    }
                }
            }
            if (RaycastBelow(true) == false)
            {
                state = 101;
                yvel = 0;
            }
        }
        else if (state == 101)
        {
            xpos += xvel;
            ypos += yvel;
            yvel += GameVars.gravity_GO;
            if (yvel > 0)
            {
                if (RaycastBelow(false))
                {
                    state = 100;
                    xvel = 2;
                    if (xflip)
                    {
                        xvel *= -1;
                    }
                }
            }
        }
        
        SetBodyXForm(0, xpos, ypos, 0);
    }
    public function OnHitOpponent(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (goHitter.collisionType == "football" || goHitter.collisionType == "beachball")
        {
            if (state == 0)
            {
                Opponent_InitHitByFootball(goHitter);
            }
        }
    }
    public function Opponent_InitHitByFootball(goHitter : GameObj)
    {
        var dy : Float = ypos - goHitter.ypos;
        
        if (dy < 20)
        {
            SetAnimRangeSingle("hitLow");
        }
        else if (dy < 55)
        {
            SetAnimRangeSingle("hitMid");
        }
        else
        {
            SetAnimRangeSingle("hitHigh");
        }
        state = 10;
    }
    public function InitOpponent()
    {
        oppo_canJumpWhenNear = false;
        oppo_canKickWhenNear = false;
        dobj = GraphicObjects.GetDisplayObjByName("player");
        playerHeadToAngle = playerHeadAngle = 0;
        
        name = "opponent";
        renderFunction = RenderOpponent;
        state = 0;
        updateFunction = UpdateOpponent;
        onHitFunction = OnHitOpponent;
        PlayerStartIdleAnim();
        
        
        team = GameVars.GetTeam(GameVars.opponentTeam);
        
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        AddHierarchy_Player(ct0, ct1, ct0, ct1, team.kitStyle);
        scale = 1;
        
        starty = ypos;
    }
    
    
    public var keeperActionIndex : Int = 0;
    public var keeperActionName : String;
    
    public function KeeperNextAction()
    {
        keeperActionIndex = GameVars.KeeperNextAction(keeperActionName, keeperActionIndex);
    }
    public function KeeperStartAction()
    {
        var p : Point = GameVars.GetKeeperAction(keeperActionName, keeperActionIndex);
        if (p.x == 0)
        {
            timer = as3hx.Compat.parseInt(p.y * Defs.fps);
            if (p.y < 0)
            {
                timer = 9999999;
            }
            timerMax = timer;
            state = 0;
        }
        else if (p.x == 1)
        {
            SetAnimRangeSingle("jump");
            state = 20;
        }
        else if (p.x == 2)
        {
            SetAnimRangeSingle("duck");
            timer = Utils.RandBetweenInt(100, 100);
            timerMax = timer;
            state = 10;
            
            
            SetBodyShapeCollisionMask(0, 2, 0);
            SetBodyShapeCollisionMask(0, 3, 0);
        }
    }
    
    
    public function RenderKeeper()
    {
        var xp : Float = Math.round(xpos) - Math.round(Game.camera.x);
        var yp : Float = Math.round(ypos) - Math.round(Game.camera.y);
        
        var oldRot : Float = animHierarchy.Frame_SetPartRot("head", Std.int(frame), playerHeadAngle);
        animHierarchy.RenderAt(bd, xp, yp, frame, scale, dir, xflip);
        animHierarchy.Frame_SetPartRot("head", Std.int(frame), oldRot);
        
        if (showTimer)
        {
            var f : Float = Utils.ScaleTo(0, dobj1.GetNumFrames() - 1, 0, timerMax, timer);
            dobj1.RenderAt(Std.int(f), bd, xp, yp - 60);
        }
    }
    
    public var showTimer : Bool;
    public function UpdateKeeper()
    {
        var ballGO : GameObj = GameVars.footballGO;
        var distToBall : Float = Utils.DistBetweenPoints(xpos, ypos, ballGO.xpos, ballGO.ypos);
        
        showTimer = false;
        
        if (state == 0)
        {
            starty = ypos;
            PlayerFaceToBall();
            PlayerUpdateIdleAnim();
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
            playerHeadAngle = playerHeadToAngle;
            
            showTimer = true;
            timer--;
            if (timer <= 0)
            {
                KeeperNextAction();
                KeeperStartAction();
            }
        }
        else if (state == 1)
        {
            if (PlayAnimationEx())
            {
                PlayerStartIdleAnim();
                state = 0;
            }
            
            for (ok/* AS3HX WARNING could not determine type for var: ok exp: EField(EIdent(GameVars),oppo_kick_table) type: null */ in GameVars.oppo_kick_table)
            {
                if (as3hx.Compat.parseInt(frame) == ok.frame)
                {
                    var x : Float = xpos + ok.xoff;
                    if (xflip)
                    {
                        x = xpos - ok.xoff;
                    }
                    var d : Float = Utils.DistBetweenPoints(x, ypos + ok.yoff, ballGO.xpos, ballGO.ypos);
                    if (d < 15)
                    {
                        Utils.print("kick ball");
                        Opponent_KickBall(ok);
                        state = 2;
                    }
                }
            }
        }
        else if (state == 2)
        {
            if (PlayAnimationEx())
            {
                PlayerStartIdleAnim();
                state = 0;
            }
        }
        else if (state == 10)
        {
            PlayAnimationEx();
            timer--;
            if (timer <= 0)
            {
                state = 11;
                timer = as3hx.Compat.parseInt(Defs.fps * 2);
                SetAnimRangeSingle("duck_loop");
            }
        }
        else if (state == 11)
        {
            CycleAnimationEx();
            timer--;
            if (timer <= 0)
            {
                state = 12;
                SetAnimRangeSingle("unduck");
            }
        }
        else if (state == 12)
        {
            if (PlayAnimationEx())
            {
                state = 0;
                PlayerStartIdleAnim();
                SetBodyShapeCollisionMask(0, 0, 14);
                SetBodyShapeCollisionMask(0, 1, 14);
                SetBodyShapeCollisionMask(0, 2, 14);
                SetBodyShapeCollisionMask(0, 3, 14);
                KeeperNextAction();
                KeeperStartAction();
            }
        }
        else if (state == 20)
        {
            PlayAnimationEx();
            if (dobj.GetLabelAtThisFrame(Std.int(frame)) == "air")
            {
                SFX_OneShot("sfx_jump");
                
                state = 21;
                yvel = -7;
            }
        }
        else if (state == 21)
        {
            PlayAnimationEx();
            ypos += yvel;
            yvel += GameVars.gravity_GO;
            if (ypos >= starty)
            {
                ypos = starty;
                SetBodyXForm(0, xpos, ypos, 0);
                state = 0;
                yvel = 0;
                PlayerStartIdleAnim();
                var body : Body = nape_bodies[0];
                
                KeeperNextAction();
                KeeperStartAction();
            }
            else
            {
                SetBodyXForm(0, xpos, ypos, 0);
            }
        }
    }
    
    
    public function InitKeeper()
    {
        showTimer = false;
        playerHeadToAngle = playerHeadAngle = 0;
        
        
        
        Utils.GetParams(initParams);
        keeperActionName = Utils.GetParamString("keeper_action", "stationary");
        keeperActionIndex = 0;
        KeeperStartAction();
        
        dobj1 = GraphicObjects.GetDisplayObjByName("generalTimer");
        
        name = "opponent_keeper";
        renderFunction = RenderKeeper;
        updateFunction = UpdateKeeper;
        
        PlayerStartIdleAnim();
        
        PhysicsSetStationary();
        
        team = GameVars.GetTeam(GameVars.opponentTeam);
        
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        AddHierarchy_Keeper(ct0, ct1, ct0, ct1, team.kitStyle);
        scale = 1;
    }
    
    
    
    
    public var patrol_x0 : Float;
    public var patrol_x1 : Float;
    
    public function RaycastBelow(snap : Bool) : Bool
    {
        var highestY : Float = 99999;
        
        var r : Ray = new Ray(new Vec2(xpos, ypos - 50), new Vec2(0, 1));
        r.maxDistance = 100;
        if (snap == false)
        {
            r.maxDistance = 50;
        }
        
        var filter : InteractionFilter = new InteractionFilter(1, 1, 0, 0, 0, 0);
        
        var rr : RayResult = PhysicsBase.GetNapeSpace().rayCast(r, false, filter);
        if (rr != null)
        {
            var p : Vec2 = r.at(rr.distance);
            highestY = p.y;
            ypos = highestY;
            return true;
        }
        return false;
    }
    
    public var oppo_canJumpWhenNear : Bool;
    public var oppo_canKickWhenNear : Bool;
    public function InitOpponent_JumpWhenNear()
    {
        InitOpponent();
        state = 0;
        PhysicsSetStationary();
        oppo_canJumpWhenNear = true;
        oppo_canKickWhenNear = true;
        dobj1 = GraphicObjects.GetDisplayObjByName("jump_mark");
        frame1 = 0;
        frameVel1 = 0.1;
    }
    
    
    public function InitOpponent_Patrol()
    {
        InitOpponent();
        state = 100;
        
        
        onHitFunction = null;
        frameVel = 0.3;
        SetAnimRangeSingle("run1");
        
        patrol_x0 = 0;
        patrol_x1 = 0;
        toPosX = patrol_x1;
        xvel = 2;
    }
    
    
    
    public var player_Race : Int = 0;
    public var player_Head : Int = 0;
    
    public var ct_shirt : ColorTransform;
    public var ct_shorts : ColorTransform;
    public var ct_socks : ColorTransform;
    public var ct_pattern : ColorTransform;
    public var kitStyle : Int = 0;
    
    public function AddHierarchy_Player(_ct_shirt : ColorTransform, _ct_shorts : ColorTransform, _ct_socks : ColorTransform, _ct_pattern : ColorTransform, _style : Int)
    {
        ct_shirt = _ct_shirt;
        ct_shorts = _ct_shorts;
        ct_socks = _ct_socks;
        ct_pattern = _ct_pattern;
        kitStyle = _style;
        
        player_Race = Utils.RandBetweenInt(0, 1);
        
        
        player_Head = Utils.RandBetweenInt(0, 7);
        if (player_Race == 1)
        {
            player_Head = Utils.RandBetweenInt(8, 15);
        }
        
        animHierarchy = GameVars.hierarchy_player.Clone();
        
        animHierarchy.SetPartColourTransform("body.tint", ct_shirt);
        animHierarchy.SetPartColourTransform("body.tint_hoops", ct_pattern);
        animHierarchy.SetPartColourTransform("body.tint_stripes", ct_pattern);
        animHierarchy.SetPartColourTransform("upperArmRight.tint", ct_shirt);
        animHierarchy.SetPartColourTransform("upperArmLeft.tint", ct_shirt);
        animHierarchy.SetPartColourTransform("upperLegRight.tint", ct_shorts);
        animHierarchy.SetPartColourTransform("upperLegLeft.tint", ct_shorts);
        animHierarchy.SetPartColourTransform("footLeft.tint", ct_socks);
        animHierarchy.SetPartColourTransform("footRight.tint", ct_socks);
        
        animHierarchy.SetPartVisible("body.tint", true);
        
        if (kitStyle == 0)
        {
            animHierarchy.SetPartVisible("body.tint_hoops", false);
            animHierarchy.SetPartVisible("body.tint_stripes", false);
        }
        if (kitStyle == 1)
        {
            animHierarchy.SetPartVisible("body.tint_hoops", true);
            animHierarchy.SetPartVisible("body.tint_stripes", false);
        }
        if (kitStyle == 2)
        {
            animHierarchy.SetPartVisible("body.tint_hoops", false);
            animHierarchy.SetPartVisible("body.tint_stripes", true);
        }
        
        
        if (player_Race == 1)
        {
            animHierarchy.SetPartFrame("upperArmRight", 1);
            animHierarchy.SetPartFrame("lowerArmRight", 1);
            animHierarchy.SetPartFrame("upperLegRight", 1);
            animHierarchy.SetPartFrame("footRight", 1);
            animHierarchy.SetPartFrame("upperLegLeft", 1);
            animHierarchy.SetPartFrame("footLeft", 1);
            animHierarchy.SetPartFrame("upperArmLeft", 1);
            animHierarchy.SetPartFrame("lowerArmLeft", 1);
        }
        if (GameVars.useFeature1)
        {
            animHierarchy.SetPartDobjName("head", "player_headBig");
        }
        if (GameVars.useFeature2)
        {
            player_Head = 16;
        }
        animHierarchy.SetPartFrame("head", player_Head);
        animHierarchy.SetPartInterpolate("head", false);
    }
    
    public function AddHierarchy_Keeper(_ct_shirt : ColorTransform, _ct_shorts : ColorTransform, _ct_socks : ColorTransform, _ct_pattern : ColorTransform, _style : Int)
    {
        ct_shirt = _ct_shirt;
        ct_shorts = _ct_shorts;
        ct_socks = _ct_socks;
        ct_pattern = _ct_pattern;
        kitStyle = _style;
        
        player_Race = Utils.RandBetweenInt(-3, 1);
        if (player_Race < 0)
        {
            player_Race = 0;
        }
        
        
        player_Head = Utils.RandBetweenInt(0, 5);
        if (player_Race == 1)
        {
            player_Head = Utils.RandBetweenInt(6, 8);
        }
        
        animHierarchy = GameVars.hierarchy_keeper.Clone();
    }
    
    
    
    
    
    
    
    
    
    
    
    public function OnHitRef(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (state != 0 && state != 100 && state != 101)
        {
            return;
        }
        if (goHitter.collisionType == "football")
        {
            Ref_HitByFootball();
        }
    }
    
    public function Ref_HitByFootball()
    {
        state = 1;
        SetAnimRangeSingle("redcard");
        GameVars.numRefsHit++;
        animHierarchy.SetPartFrame("lowerArmLeft", 2);
        animHierarchy.SetPartFrame("lowerArmRight", 1);
        
        var r : Int = Utils.RandBetweenInt(1, 3);
        SFX_OneShot("sfx_refgroan" + r);
        
        SFX_OneShot("sfx_ref_whistle", true, 0.1);
        
        var go : GameObj = GameObjects.AddObj(xpos, ypos - 120, zpos - 1000);
        go.InitRedcardPopup();
        
        Game.AddScore(100);
    }
    public function UpdateRefPiece()
    {
        xpos += xvel;
        ypos += yvel;
        yvel += GameVars.gravity_GO;
        dir += rotVel;
        timer--;
        if (timer <= 0)
        {
            RemoveObject();
        }
    }
    public function InitRefPiece()
    {
        updateFunction = UpdateRefPiece;
        timer = 300;
        xvel = Utils.RandBetweenFloat(-5, 5);
        yvel = Utils.RandBetweenFloat(-10, -5);
        rotVel = Utils.RandBetweenFloat(0.1, 0.3);
        if (Utils.RandBool())
        {
            rotVel = -rotVel;
        }
    }
    
    public function UpdateRef()
    {
        var ballGO : GameObj = GameVars.footballGO;
        
        if (state == 0)
        {
            PlayerFaceToBall();
            PlayerHeadFollowPoint(ballGO.xpos, ballGO.ypos);
            PlayerUpdateIdleAnim();
        }
        else if (state == 1)
        {
            if (GameVars.useFeature3)
            {
                var goList : Array<Dynamic> = animHierarchy.CreateSeparates(xpos, ypos, frame, scale, dir, xflip);
                for (go in goList)
                {
                    go.InitRefPiece();
                }
                state = 3;
                RemoveObject(RemovePhysObj);
            }
            else
            {
                playerHeadToAngle = 0;
                if (PlayAnimationEx())
                {
                    SetAnimRangeSingle("die");
                    RemovePhysObj();
                    state = 2;
                    yvel = -4;
                    timer = as3hx.Compat.parseInt(Defs.fps * 3);
                }
            }
        }
        else if (state == 2)
        {
            zpos = -10000;
            yvel += GameVars.gravity_GO;
            ypos += yvel;
            timer--;
            if (timer <= 0)
            {
                RemoveObject();
            }
            CycleAnimationEx();
        }
        
        
        if (state == 100)
        {
            for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameVars),jumpMarkers) type: null */ in GameVars.jumpMarkers)
            {
                if (Utils.DistBetweenPoints(xpos, ypos, go.xpos, go.ypos) < 20)
                {
                    var v : Vec = new Vec();
                    v.Set(go.dir, 1);
                    
                    var doit : Bool = false;
                    if (xflip == false)
                    {
                        if (v.X() > 0)
                        {
                            doit = true;
                        }
                    }
                    else if (v.X() < 0)
                    {
                        doit = true;
                    }
                    
                    if (doit)
                    {
                        state = 101;
                        movementVec.Set(go.dir, 5);
                        movementVec.speed *= go.scale;
                        xvel = movementVec.X();
                        yvel = movementVec.Y();
                    }
                }
            }
            
            
            CycleAnimationEx();
            
            
            var ox : Float = xpos;
            xpos += xvel;
            
            
            for (go/* AS3HX WARNING could not determine type for var: go exp: EField(EIdent(GameVars),patrolMarkers) type: null */ in GameVars.patrolMarkers)
            {
                if (Math.abs(go.ypos - ypos) < 20)
                {
                    if (xvel > 0)
                    {
                        if (xpos >= go.xpos && ox < go.xpos)
                        {
                            xpos = go.xpos;
                            xvel = -xvel;
                            xflip = (xflip == false);
                        }
                    }
                    else if (xpos <= go.xpos && ox > go.xpos)
                    {
                        xpos = go.xpos;
                        xvel = -xvel;
                        xflip = (xflip == false);
                    }
                }
            }
            if (RaycastBelow(true) == false)
            {
                state = 101;
                yvel = 0;
            }
        }
        else if (state == 101)
        {
            xpos += xvel;
            ypos += yvel;
            yvel += GameVars.gravity_GO;
            if (yvel > 0)
            {
                if (RaycastBelow(false))
                {
                    state = 100;
                    xvel = 2;
                    if (xflip)
                    {
                        xvel *= -1;
                    }
                }
            }
        }
        
        if (nape_bodies.length != 0)
        {
            if (nape_bodies[0] != null)
            {
                SetBodyXForm(0, xpos, ypos, 0);
            }
        }
        
        
        playerHeadAngle = playerHeadToAngle;
    }
    
    
    public function RefStartIdleAnim()
    {
        idleTimer = 0;
        idleState = 0;
        SetAnimRangeSingle("idle" + Utils.RandBetweenInt(1, 3));
    }
    public function RefUpdateIdleAnim()
    {
        if (idleState == 0)
        {
            if (PlayAnimationEx())
            {
                idleState = 1;
            }
        }
        else
        {
            idleTimer--;
            if (idleTimer <= 0)
            {
                SetAnimRangeSingle("idle" + Utils.RandBetweenInt(1, 3));
                idleTimer = Utils.RandBetweenInt(Std.int(Defs.fps), Std.int(Defs.fps * 2));
                idleState = 0;
            }
        }
    }
    
    
    public function UpdateRefLoose()
    {
        var ballGO : GameObj = GameVars.footballGO;
        
        playerHeadToAngle = 0;
        if (state == 0)
        {
            PlayerUpdateIdleAnim();
        }
        else if (state == 1)
        {
            playerHeadToAngle = 0;
            if (PlayAnimationEx())
            {
                SetAnimRangeSingle("die");
                RemovePhysObj();
                state = 2;
                yvel = -4;
                timer = as3hx.Compat.parseInt(Defs.fps * 3);
            }
        }
        else if (state == 2)
        {
            zpos = -10000;
            yvel += GameVars.gravity_GO;
            ypos += yvel;
            timer--;
            if (timer <= 0)
            {
                RemoveObject();
            }
            CycleAnimationEx();
        }
    }
    public function InitRef_Loose()
    {
        InitRef();
        PhysicsSetMovable();
        updateFunction = UpdateRefLoose;
    }
    public function InitRef()
    {
        playerHeadToAngle = playerHeadAngle = 0;
        
        
        name = "ref";
        renderFunction = RenderRef;
        updateFunction = UpdateRef;
        onHitFunction = OnHitRef;
        
        RefStartIdleAnim();
        
        GameVars.totalRefs++;
        
        AddHierarchy_Ref();
        frameVel = 0.5;
    }
    
    public function InitRef_Patrol()
    {
        InitRef();
        state = 100;
        frameVel = 0.3;
        SetAnimRangeSingle("run1");
        
        patrol_x0 = 0;
        patrol_x1 = 0;
        toPosX = patrol_x1;
        xvel = 2;
    }
    
    
    
    
    
    public function AddHierarchy_Ref()
    {
        player_Head = Utils.RandBetweenInt(0, 2);
        
        animHierarchy = GameVars.hierarchy_ref.Clone();
        
        animHierarchy.SetPartFrame("head", player_Head);
    }
    
    
    
    
    
    
    public function UpdateGoalPopup()
    {
        timer--;
        if (timer <= 0)
        {
            RemoveObject();
        }
        var f : Float = Utils.ScaleTo(1, 0, 0, timerMax, timer);
        f = Ease.Spring_Out(f);
        scale = f * scaleMax;
        dir += 0.1;
    }
    public function RenderGoalPopup()
    {
        RenderDispObjAt(xpos, ypos, dobj, 0, null, dir, scale * 0.8);
        RenderDispObjAt(xpos, ypos, dobj1, 0, null, 0, scale);
    }
    public function InitGoalPopup()
    {
        updateFunction = UpdateGoalPopup;
        renderFunction = RenderGoalPopup;
        dobj = GraphicObjects.GetDisplayObjByName("popup_rays");
        dobj1 = GraphicObjects.GetDisplayObjByName("popup_goal");
        timerMax = timer = as3hx.Compat.parseInt(Defs.fps * 2);
        scaleMax = 1.5;
    }
    public function InitRedcardPopup()
    {
        updateFunction = UpdateGoalPopup;
        renderFunction = RenderGoalPopup;
        dobj = GraphicObjects.GetDisplayObjByName("popup_rays");
        dobj1 = GraphicObjects.GetDisplayObjByName("popup_redcard");
        timerMax = timer = as3hx.Compat.parseInt(Defs.fps * 2);
        scaleMax = 1;
    }
    public function InitTrophyPopup()
    {
        updateFunction = UpdateGoalPopup;
        renderFunction = RenderGoalPopup;
        dobj = GraphicObjects.GetDisplayObjByName("popup_rays");
        dobj1 = GraphicObjects.GetDisplayObjByName("popup_trophy");
        timerMax = timer = as3hx.Compat.parseInt(Defs.fps * 2);
        scaleMax = 1;
    }
    
    public function UpdatePopPopup()
    {
        timer--;
        if (timer <= 0)
        {
            RemoveObject();
        }
        var f : Float = Utils.ScaleTo(1, 0, 0, timerMax, timer);
        f = Ease.Spring_Out(f);
        scale = f * scaleMax;
    }
    public function InitPopPopup()
    {
        updateFunction = UpdatePopPopup;
        dobj = GraphicObjects.GetDisplayObjByName("popup_pop");
        timerMax = timer = as3hx.Compat.parseInt(Defs.fps * 0.5);
        scaleMax = 1;
    }
    
    public function InitPlusOnePopup()
    {
        updateFunction = UpdatePopPopup;
        dobj = GraphicObjects.GetDisplayObjByName("plusOneShot");
        timerMax = timer = as3hx.Compat.parseInt(Defs.fps * 1);
        scaleMax = 1;
    }
    
    public function OnHitGoal(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (state != 0)
        {
            return;
        }
        
        
        if (hitInteractionCallback_Nape != null)
        {
            var arbiterList : ArbiterList = hitInteractionCallback_Nape.arbiters;
            for (i in 0...arbiterList.length)
            {
                var arbiter : Arbiter = arbiterList.at(i);
                if (arbiter.isSensorArbiter())
                {
                    if (goHitter.collisionType == "football")
                    {
                        state = 1;
                        frame += 2;
                        GameVars.numGoalsScored++;
                        
                        var go : GameObj = GameObjects.AddObj(xpos, ypos - 60, zpos - 1000);
                        go.InitGoalPopup();
                        
                        var a : Array<Dynamic> = GameObjects.GetGameObjListByName("player");
                        for (go in a)
                        {
                            go.PlayerStartCelebration();
                        }
                        var a : Array<Dynamic> = GameObjects.GetGameObjListByName("opponent");
                        for (go in a)
                        {
                            go.OpponentStartCommiseration();
                        }
                        
                        Game.AddScore(200);
                        SFX_OneShot("sfx_goal");
                        return;
                    }
                }
                else
                {
                    SFX_OneShot("sfx_hit_metal");
                }
            }
        }
    }
    public function InitGoal()
    {
        GameVars.totalGoals++;
        
        onHitFunction = OnHitGoal;
    }
    
    
    
    
    public function PhysicsUpdateNull(b : Body)
    {
        b.position.x = xpos;
        b.position.y = ypos;
    }
    
    public function PhysicsSetStationary()
    {
        updateFromPhysicsFunction = PhysicsUpdateNull;
    }
    public function PhysicsSetMovable()
    {
        updateFromPhysicsFunction = null;
    }
    
    
    
    
    
    public function UpdateSpikyBall()
    {
        if (state == 0)
        {
            if (Game.boundingRectangle.contains(xpos, ypos) == false)
            {
                RemoveObject(RemovePhysObj);
            }
        }
        else if (state == 200)
        {
            visible = true;
            xpos = football_CannonObj.xpos;
            ypos = football_CannonObj.ypos;
            PhysicsSetStationary();
            timer--;
            if (timer <= 0)
            {
                updateFromPhysicsFunction = null;
                
                ballLaunch_vec.SetAng(football_CannonObj.dir - (Math.PI / 2));
                ballLaunch_vec.speed = Vars.GetVarAsNumber("cannonLaunchForce");
                
                ballLaunch_vec.speed *= GetBodyMass(0);
                
                
                timer = timerMax = Defs.fps * 3;
                
                
                football_CannonObj.Cannon_Fired();
                visible = true;
                
                Football_Launch(ballLaunch_vec);
            }
        }
    }
    public function InitSpikyBall()
    {
        ballLaunch_vec = new Vec();
        
        updateFunction = UpdateSpikyBall;
        name = "spikyball";
    }
    
    
    
    
    public function OnHitBurstableBall(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (goHitter.name == "spikyball")
        {
            var go : GameObj = GameObjects.AddObj(xpos, ypos, -10000);
            go.InitPopPopup();
            
            var area : Float = 0;
            var b : Body = nape_bodies[0];
            for (s in 0...b.shapes.length)
            {
                var shape : nape.shape.Shape = b.shapes.at(s);
                area += shape.area;
            }
            
            var force : Float = Utils.ScaleToPreLimit(5, 30, 100, 12000, area);
            
            Utils.print("force " + force);
            
            GOHelpers.DoExplosion(this, xpos, ypos, 200, force);
            
            SFX_OneShot("sfx_pop");
            
            RemoveObject(RemovePhysObj);
        }
    }
    public function InitBurstableBall()
    {
        collisionType = "football";
        name = "burstable";
        onHitFunction = OnHitBurstableBall;
    }
    
    
    
    
    
    public function InitRunMarker()
    {
        name = "run_marker";
        visible = false;
        if (Game.usedebug)
        {
            visible = true;
        }
    }
    
    public function InitPatrolMarker()
    {
        name = "patrol_marker";
        visible = false;
        if (Game.usedebug)
        {
            visible = true;
        }
    }
    
    public function InitJumpMarker()
    {
        name = "jump_marker";
        visible = false;
        if (Game.usedebug)
        {
            visible = true;
        }
    }
    
    
    
    
    public function UpdateCloud()
    {
        var fov : Float = 100;
        
        var fl : Float = 1.0;
        
        var z1 : Float = zpos;
        var sc : Float = fl / (fl + z1);
        sc *= fov;
        
        var cx : Float = (Game.boundingRectangle.left + Game.boundingRectangle.right) / 2;
        var cy : Float = (Game.boundingRectangle.top + Game.boundingRectangle.bottom) / 2;
        
        
        cx -= (Game.camera.x + Defs.displayarea_w2);
        cy -= (Game.camera.y + Defs.displayarea_h2);
        
        
        xpos = 320 - ((xpos1 - cx) * sc);
        ypos = 240 - ((ypos1 - cy) * sc);
        
        scale = 0.5 + sc;
        
        xpos1 += xvel;
        
        if (xpos1 > xpos3)
        {
            xpos1 = xpos2;
        }
    }
    public function RenderCloud()
    {
        RenderDispObjNormally(false);
    }
    public function InitCloud()
    {
        updateFunction = UpdateCloud;
        renderFunction = RenderCloud;
        dobj = GraphicObjects.GetDisplayObjByName("cloud");
        frame = dobj.GetRandomFrame();
        
        var cx : Float = (Game.boundingRectangle.left + Game.boundingRectangle.right) / 2;
        var cy : Float = (Game.boundingRectangle.top + Game.boundingRectangle.bottom) / 2;
        
        
        xpos1 = Utils.RandBetweenFloat(Game.boundingRectangle.left, Game.boundingRectangle.right);
        ypos1 = Utils.RandBetweenFloat(Game.boundingRectangle.top, Game.boundingRectangle.bottom);
        
        xpos1 = xpos1 - cx;
        ypos1 = ypos1 - cy;
        
        
        zpos = Utils.RandBetweenFloat(300, 1000);
        
        var fov : Float = 100;
        var fl : Float = 1.0;
        var z1 : Float = zpos;
        var sc : Float = fl / (fl + z1);
        sc *= fov;
        
        xpos1 *= 1 / sc;
        ypos1 *= 1 / sc;
        
        xpos2 = ((Game.boundingRectangle.left - 100) - cx) * 1 / sc;
        xpos3 = ((Game.boundingRectangle.right + 100) - cy) * 1 / sc;
        
        xvel = Utils.RandBetweenFloat(1, 2);
    }
    
    
    
    
    public function SwitchedCog()
    {
        if (state == 0)
        {
            state = 1;
        }
        else
        {
            state = 0;
        }
    }
    public function UpdateCog()
    {
        if (state == 0)
        {
            dir += 0.1;
            if (dir >= 6)
            {
                dir = 6;
            }
        }
        else if (state == 1)
        {
            dir -= 0.1;
            if (dir < 0)
            {
                dir = 0;
            }
        }
    }
    public function InitCog()
    {
        updateFunction = UpdateCog;
        switchFunction = SwitchedCog;
        switchFlag = false;
        state = 1;
    }
    
    
    
    
    
    
    public function OnHitFlyingBird(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (state != 1)
        {
            return;
        }
        if (goHitter.collisionType == "football" || goHitter.collisionType == "beachball")
        {
            if (goHitter.parentObj.colFlag_isPlayer)
            {
            }
            
            timer = Utils.RandBetweenInt(100, 300);
            visible = false;
            SetBodySensorMask(-1, 0);
            state = 0;
            BirdGenerateFeathers();
        }
    }
    
    
    public function UpdateFlyingBird()
    {
        if (state == 0)
        {
            timer--;
            if (timer <= 0)
            {
                xpos = Grass.minX;
                xvel = Utils.RandBetweenFloat(6, 9) / 4;
                xflip = false;
                if (Utils.RandBool())
                {
                    xpos = Grass.maxX;
                    xvel = -xvel;
                    xflip = true;
                }
                state = 1;
                visible = true;
                SetBodySensorMask(-1, 8);
                timer3 = Utils.RandBetweenFloat(0.05, 0.1) / 4;
                timer2 = Utils.RandBetweenFloat(5, 30);
                timer1 = Utils.RandBetweenInt(0, 1000);
            }
        }
        else if (state == 1)
        {
            timer1++;
            ypos = starty + ((Math.sin(timer1 * timer3)) * timer2);
            xpos += xvel;
            CycleAnimation();
            if (xpos > Grass.maxX || xpos < Grass.minX)
            {
                timer = Utils.RandBetweenInt(100, 200);
                visible = false;
                SetBodySensorMask(-1, 0);
                state = 0;
            }
            SetBodyXForm_Immediate(0, xpos, ypos, 0);
        }
    }
    public function InitFlyingBird()
    {
        useMultiplePhysicsUpdates = true;
        onHitFunction = OnHitFlyingBird;
        updateFunction = UpdateFlyingBird;
        updateFromPhysicsFunction = UpdatePhysicsNull;
        visible = false;
        SetBodySensorMask(-1, 0);
        state = 0;
        timer = Utils.RandBetweenInt(50, 100);
        timer2 = Utils.RandBetweenFloat(5, 10);
        starty = ypos;
        frameVel = 0.25;
    }
    
    
    
    
    public function FootballGenerateSparkle()
    {
        for (i in 0...1)
        {
            var p : Particle = Particles.Add(xpos, ypos);
            p.InitFeather("fx_sparkles_gold", i);
        }
    }
    public function BirdGenerateFeathers()
    {
        for (i in 0...6)
        {
            var p : Particle = Particles.Add(xpos, ypos);
            p.InitFeather("feathers", i);
        }
    }
    
    public function OnHitBird(goHitter : GameObj)
    {
        if (goHitter == null)
        {
            return;
        }
        if (goHitter.collisionType == "football" || goHitter.collisionType == "beachball")
        {
            RemoveObject(RemovePhysObj);
            BirdGenerateFeathers();
        }
    }
    public function UpdateBird()
    {
        if (state == 0 || state == 1)
        {
            SetBodyXForm_Immediate(0, xpos, ypos, 0);
            PlayAnimationEx();
            var d2 : Float = birdWatchDist2;
            timer1++;
            if (timer1 >= 4)
            {
                timer1 = 0;
            }
            
            
            var ballGO : GameObj = GameVars.footballGO;
            if (ballGO != null)
            {
                if (Utils.Dist2BetweenPoints(xpos, ypos, ballGO.xpos, ballGO.ypos) < d2)
                {
                    state = 10;
                    dobj = GraphicObjects.GetDisplayObjByName("parrotFly");
                    frame = 0;
                    yvel = Utils.RandBetweenFloat(-1, -3) / 4;
                    xvel = 0;
                    xacc = Utils.RandBetweenFloat(0.2, 0.4) / 16;
                    timer = as3hx.Compat.parseInt(300 * 4);
                    if (Utils.RandBool())
                    {
                        SFX_OneShot("sfx_bird_squalk");
                    }
                    else
                    {
                        SFX_OneShot("sfx_bird_flyoff");
                    }
                }
            }
            timer--;
            if (timer <= 0)
            {
                state = Utils.RandBetweenInt(0, 1);
                SetAnimRangeSingle("flap" + as3hx.Compat.parseInt(state + 1));
                timer = as3hx.Compat.parseInt(Utils.RandBetweenInt(10, 50) * 4);
            }
        }
        else if (state == 10)
        {
            CycleAnimation();
            ypos += yvel;
            xpos += xvel;
            xvel += xacc;
            yvel -= 0.1 / 16;
            timer--;
            if (timer <= 0)
            {
                RemoveObject(RemovePhysObj);
            }
            SetBodyXForm_Immediate(0, xpos, ypos, 0);
        }
    }
    public function UpdatePhysicsNull(b : Body)
    {
    }
    public var birdWatchDist2 : Float;
    public function InitBird()
    {
        useMultiplePhysicsUpdates = true;
        onHitFunction = OnHitBird;
        updateFunction = UpdateBird;
        updateFromPhysicsFunction = UpdatePhysicsNull;
        timer = Utils.RandBetweenInt(30, 50);
        state = Utils.RandBetweenInt(0, 1);
        timer1 = 0;
        SetAnimRangeSingle("flap1");
        birdWatchDist2 = Utils.RandBetweenFloat(100, 100);
        birdWatchDist2 *= birdWatchDist2;
        frameVel = 0.25;
    }
    
    
    
    
    public function UpdateSmokePuff()
    {
        yvel = -0.3;
        
        ypos += yvel;
        scale -= 0.02;
        if (scale <= 0.1)
        {
            RemoveObject();
        }
    }
    public function InitSmokePuff()
    {
        updateFunction = UpdateSmokePuff;
        timer = Defs.fps;
        dobj = GraphicObjects.GetDisplayObjByName("fx_smoke");
        frame = 0;
    }
    
    
    
    
    
    
    
    
    public function RenderFastForward()
    {
        if (GameVars.doingFastForward)
        {
            GameVars.fastforwardoffset -= 1;
            if (GameVars.fastforwardoffset < 0)
            {
                GameVars.fastforwardoffset = 50;
            }
            var dobj : DisplayObj = GraphicObjects.GetDisplayObjByName("FastForwardLines");
            var numf : Int = dobj.GetNumFrames();
            var i : Int = 0;            i = 50;
            while (i < 500)
            {
                var f : Int = Utils.RandBetweenInt(0, numf - 1);
                var x : Float = Utils.RandBetweenInt(0, Defs.displayarea_w);
                dobj.RenderAt(f, bd, x, i + GameVars.fastforwardoffset);
                i += 80;
            }
        }
    }
    public function InitFastForward()
    {
        renderFunction = RenderFastForward;
    }
    
    
    public function OnHitBallboy(goHitter : GameObj)
    {
        if (goHitter.name == "football")
        {
            goHitter.Football_MoveToPlayer(goHitter.football_playerGO);
        }
    }
    public function InitBallboy()
    {
        dobj = GraphicObjects.GetDisplayObjByName("player");
        playerHeadToAngle = playerHeadAngle = 0;
        
        name = "ballboy";
        renderFunction = RenderOpponent;
        state = 0;
        
        onHitFunction = OnHitBallboy;
        PlayerStartIdleAnim();
        
        
        team = GameVars.GetTeam(GameVars.opponentTeam);
        
        var a : Array<Dynamic> = null;        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShirt);
        var ct0 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorShorts);
        var ct1 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorSocks);
        var ct2 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        a = GameVars.GetKitColorRGBArrayByIndex(team.kitColorPattern);
        var ct3 : ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + a[0], -255 + a[1], -255 + a[2], 0);
        
        AddHierarchy_Player(ct0, ct1, ct0, ct1, team.kitStyle);
        scale = 0.7;
    }
    
    
    
    
    
    
    
    public function UpdateAnimatedWhenMoving()
    {
        CycleAnimation();
        var v : Float = GetBodyLinearVelocity(0).length;
        
        frameVel = Utils.ScaleToPreLimit(0, 2, 0, 100, v);
    }
    public function InitAnimatedWhenMoving()
    {
        updateFunction = UpdateAnimatedWhenMoving;
        frameVel = 0;
    }
    
    
    
    public function AddDummyBall()
    {
    }
    
    public function DoBallLine(x : Float, y : Float, dx : Float, dy : Float, ballGO : GameObj)
    {  /*
			PhysicsBase.SetCurrentSpace(1);
			var b:Body = new Body();

			var body:PhysObjBody = ballGO.physobj.bodies[0];

			for each(var shape:PhysObjShape in (body.shapes : Array<Dynamic>))
			{
				var physMaterial:PhysObjMaterial = Game.GetPhysMaterialByName(shape.materialName);
				if (shape.type == PhysObjShape.Type_Circle)
				{
					var circle_pos:Vec2 = new Vec2(shape.circle_pos.x * scale, shape.circle_pos.y * scale);
					var nape_circle:Circle = new Circle(shape.circle_radius, circle_pos);


					nape_circle.material = physMaterial.MakeNapeMaterial();
					var interactionFilter:InteractionFilter = new InteractionFilter(4,0,4,0,4,0);

					nape_circle.filter = interactionFilter;

					nape_circle.sensorEnabled = false;
					b.shapes.add(nape_circle);
				}
			}

			b.type = BodyType.DYNAMIC;
			b.angularVel = 0;
			b.velocity.setxy(0, 0);
			b.position.setxy(x, y);
			b.applyImpulse(new Vec2(dx, dy));

			PhysicsBase.GetNapeSpace().bodies.add(b);


			for (var i:int = 0; i < 120; i++)
			{
				PhysicsBase.TimeStep();
				var p:Point = new Point(b.position.x, b.position.y);


			}


			PhysicsBase.GetNapeSpace().bodies.remove(b);
			PhysicsBase.SetCurrentSpace(0);
			*/  
        
    }

    public function new()
    {
        super();
    }
}




