import haxe.Constraints.Function;
import flash.display.Bitmap;
import flash.geom.Point;

/**
	* ...
	* @author Default
	*/
class Particle
{
    public var active : Bool;
    public var xpos : Float;
    public var ypos : Float;
    public var xpos1 : Float;
    public var ypos1 : Float;
    public var startx : Float;
    public var starty : Float;
    public var timer : Float;
    public var xvel : Float;
    public var yvel : Float;
    public var yacc : Float;
    public var graphicID : Int = 0;
    public var frame : Float;
    public var frameVel : Float;
    public var speed : Float;
    public var dir : Float;
    public var radius : Float;
    public var dirVel : Float;
    public var alpha : Float;
    public var alphaAdd : Float;
    public var maxframe : Int = 0;
    public var counter : Int = 0;
    public var visible : Bool;
    public var updateFunction : Function;
    public var mode : Int = 0;
    public var color : Int = 0;
    public var psize : Int = 0;
    public var angle : Float;
    public var anglevel : Float;
    public var dobj : DisplayObj;
    
    
    
    
    
    
    
    public function UpdateVelsTimer()
    {
        xpos += xvel;
        ypos += yvel;
        timer--;
        if (timer <= 0)
        {
            active = false;
        }
    }
    public function UpdateAnimAndStop()
    {
        xpos += xvel;
        ypos += yvel;
        if (PlayAnimation())
        {
            active = false;
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    public function InitBloodSplat() : Void
    {
        var r : Float = Utils.RandCircle();
        var v : Float = Utils.RandBetweenFloat(4, 7);
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        var c : Int = Utils.RandBetweenInt(0, 3);
        if (c == 0)
        {
            color = 0xff700000;
        }
        if (c == 1)
        {
            color = 0xff800000;
        }
        if (c == 2)
        {
            color = 0xff900000;
        }
        if (c == 3)
        {
            color = 0xffa00000;
        }
        
        updateFunction = UpdateBloodSplat;
        timer = Utils.RandBetweenInt(30, 50);
        
        dobj = GraphicObjects.GetDisplayObjByName("bloodsplat");
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
        angle = Utils.RandCircle();
        anglevel = Utils.RandBetweenFloat(-0.1, 0.1);
        
        if (Levels.currentIndex == 40)
        {
            angle = 0;
            anglevel = 0;
        }
    }
    
    public function RenderBloodSplat(x : Int, y : Int)
    {
        var xx : Int = x;
        var yy : Int = y;
        
        var col : Int = Game.scrollScreenBD.getPixel(xx, yy);
        if (col != 0)
        {
            Game.scrollScreenBD.setPixel32(xx, yy, color);
        }
    }
    
    public function UpdateBloodSplat() : Void
    {
        yvel += GameVars.gravity_GO;
        xpos += xvel;
        ypos += yvel;
        
        angle += anglevel;
        
        var xx : Int = as3hx.Compat.parseInt(xpos - Game.boundingRectangle.left);
        var yy : Int = as3hx.Compat.parseInt(ypos - Game.boundingRectangle.top);
        
        var col : Int = Game.scrollScreenBD.getPixel(as3hx.Compat.parseInt(xx), as3hx.Compat.parseInt(yy));
        if (col != 0)
        {
            active = false;
            for (i in -4...4)
            {
                for (j in -4...4)
                {
                    var randit : Bool = false;
                    if (i < -2 || i > 2)
                    {
                        randit = true;
                    }
                    if (j < -2 || j > 2)
                    {
                        randit = true;
                    }
                    if (randit)
                    {
                        if (Utils.RandBool())
                        {
                            RenderBloodSplat(xx + i, yy + j);
                        }
                    }
                    else
                    {
                        RenderBloodSplat(xx + i, yy + j);
                    }
                }
            }
        }
        
        timer--;
        if (timer <= 0)
        {
            active = false;
            timer = 0;
        }
    }
    
    
    
    public function InitTextBloodSplat() : Void
    {
        var r : Float = Utils.RandCircle();
        var v : Float = Utils.RandBetweenFloat(1, 4);
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        updateFunction = UpdateTextBloodSplat;
        timer = Utils.RandBetweenInt(30, 50);
        
        dobj = GraphicObjects.GetDisplayObjByName("smokePuff");
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
    }
    
    public function UpdateTextBloodSplat() : Void
    {
        yvel += 0.1;
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 0)
        {
            active = false;
            timer = 0;
        }
    }
    
    
    
    
    public function InitSmoke(_name : String) : Void
    {
        var v : Float = Utils.RandBetweenFloat(0, 1);
        var r : Float = Utils.RandCircle();
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        dobj = GraphicObjects.GetDisplayObjByName(_name);
        
        updateFunction = UpdateSmoke;
        frameVel = Utils.RandBetweenFloat(0.6, 1);
        frame = 0;
        maxframe = as3hx.Compat.parseInt(dobj.GetNumFrames() - 1);
        
        
        timer = 0;
        visible = false;
    }
    
    
    public function UpdateSmoke() : Void
    {
        xvel *= 0.9;
        yvel *= 0.9;
        xpos += xvel;
        ypos += yvel;
        
        visible = false;
        timer++;
        if (timer > 1)
        {
            visible = true;
            if (PlayAnimation())
            {
                active = false;
            }
        }
    }
    
    
    
    
    public function InitDivot() : Void
    {
        var v : Float = Utils.RandBetweenFloat(3, 6);
        var r : Float = Utils.RandCircle();
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        yvel = Utils.RandBetweenFloat(-3, -6);
        
        dobj = GraphicObjects.GetDisplayObjByName("divots");
        
        updateFunction = UpdateDivot;
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
        angle = Utils.RandCircle();
        
        timer = 20;
    }
    
    
    
    public function UpdateDivot() : Void
    {
        yvel += 0.3;
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 10)
        {
            alpha = Utils.ScaleTo(0, 1, 0, 10, timer);
        }
        
        if (timer <= 0)
        {
            active = false;
        }
    }
    
    
    
    
    public function InitSandShower() : Void
    {
        var v : Float = Utils.RandBetweenFloat(3, 6);
        var r : Float = Utils.RandCircle();
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        yvel = Utils.RandBetweenFloat(-3, -6);
        
        dobj = GraphicObjects.GetDisplayObjByName("sandParticles");
        
        updateFunction = UpdateSandShower;
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
        angle = Utils.RandCircle();
        
        timer = 20;
    }
    
    
    
    public function UpdateSandShower() : Void
    {
        yvel += 0.3;
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 10)
        {
            alpha = Utils.ScaleTo(0, 1, 0, 10, timer);
        }
        
        if (timer <= 0)
        {
            active = false;
        }
    }
    
    
    
    
    public function InitCloudShower() : Void
    {
        var v : Float = Utils.RandBetweenFloat(3, 6);
        var r : Float = Utils.RandCircle();
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        yvel = Utils.RandBetweenFloat(-3, -6);
        
        dobj = GraphicObjects.GetDisplayObjByName("sandParticles");
        
        updateFunction = UpdateCloudShower;
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
        angle = Utils.RandCircle();
        
        timer = 20;
    }
    
    
    
    public function UpdateCloudShower() : Void
    {
        yvel += 0.3;
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 10)
        {
            alpha = Utils.ScaleTo(0, 1, 0, 10, timer);
        }
        
        if (timer <= 0)
        {
            active = false;
        }
    }
    
    
    
    
    public function InitStarShower() : Void
    {
        var v : Float = Utils.RandBetweenFloat(3, 6);
        var r : Float = Utils.RandCircle();
        xvel = Math.cos(r) * v;
        yvel = Math.sin(r) * v;
        
        dobj = GraphicObjects.GetDisplayObjByName("star_particle");
        
        updateFunction = UpdateStarShower;
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
        angle = Utils.RandCircle();
        
        timer = 20;
    }
    
    
    
    public function UpdateStarShower() : Void
    {
        yvel += 0.3;
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 10)
        {
            alpha = Utils.ScaleTo(0, 1, 0, 10, timer);
        }
        
        if (timer <= 0)
        {
            active = false;
        }
    }
    
    
    
    
    public function InitFeather(mcName : String, _frame : Int) : Void
    {
        xvel = Utils.RandBetweenFloat(-2, 2);
        yvel = Utils.RandBetweenFloat(-1, -2);
        
        dobj = GraphicObjects.GetDisplayObjByName(mcName);
        
        updateFunction = UpdateFeather;
        frame = _frame;
        angle = Utils.RandCircle();
        
        timer = 60;
    }
    
    
    
    public function UpdateFeather() : Void
    {
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 10)
        {
            alpha = Utils.ScaleTo(0, 1, 0, 10, timer);
        }
        
        if (timer <= 0)
        {
            active = false;
        }
    }
    
    
    
    
    public function InitSparkle(mcName : String, _frame : Int) : Void
    {
        xvel = Utils.RandBetweenFloat(-2, 2);
        yvel = Utils.RandBetweenFloat(-1, -2);
        
        dobj = GraphicObjects.GetDisplayObjByName(mcName);
        
        updateFunction = UpdateSparkle;
        frame = _frame;
        angle = Utils.RandCircle();
        
        timer = 60;
    }
    
    
    
    public function UpdateSparkle() : Void
    {
        xpos += xvel;
        ypos += yvel;
        
        timer--;
        if (timer <= 10)
        {
            alpha = Utils.ScaleTo(0, 1, 0, 10, timer);
        }
        
        if (timer <= 0)
        {
            active = false;
        }
    }
    
    
    
    public function InitBubble() : Void
    {
        psize = 2;
        dobj = GraphicObjects.GetDisplayObjByName("bubbles");
        
        yvel = -Utils.RandBetweenFloat(1, 2);
        xvel = Utils.RandBetweenFloat(-0.5, 0.5);
        
        color = 0xffff0036;
        
        updateFunction = UpdateBubble;
        frameVel = 1;
        
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    
    
    public function UpdateBubble() : Void
    {
        xpos += xvel;
        ypos += yvel;
        
        if (PlayAnimation())
        {
            active = false;
        }
    }
    
    
    
    public function InitBubble1(dir : Float) : Void
    {
        psize = 2;
        dobj = GraphicObjects.GetDisplayObjByName("bubbles1");
        
        dir += Utils.RandBetweenFloat(-0.3, 0.3);
        var spd : Float = Utils.RandBetweenFloat(1, 3);
        xvel = Math.cos(dir) * spd;
        yvel = Math.sin(dir) * spd;
        
        
        
        
        
        updateFunction = UpdateBubble1;
        frameVel = 1;
        
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    
    
    public function UpdateBubble1() : Void
    {
        xpos += xvel;
        ypos += yvel;
        
        
        if (PlayAnimation())
        {
            active = false;
        }
    }
    
    
    
    public function InitExplosion_Small() : Void
    {
        dobj = GraphicObjects.GetDisplayObjByName("explosion_2");
        updateFunction = UpdateExplosion;
        frameVel = 1;
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    public function InitExplosion_Large() : Void
    {
        dobj = GraphicObjects.GetDisplayObjByName("explosion_3");
        updateFunction = UpdateExplosion;
        frameVel = 1;
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    public function InitExplosion_Mushroom() : Void
    {
        dobj = GraphicObjects.GetDisplayObjByName("mushroomCloud");
        updateFunction = UpdateExplosion;
        frameVel = 1;
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    public function InitExplosion_Shockwave() : Void
    {
        dobj = GraphicObjects.GetDisplayObjByName("shockWave");
        updateFunction = UpdateExplosion;
        frameVel = 1;
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    public function InitExplosion_BloodPuff() : Void
    {
        dobj = GraphicObjects.GetDisplayObjByName("bloodPuff");
        updateFunction = UpdateExplosion;
        frameVel = 1;
        maxframe = dobj.GetNumFrames();
        frame = 0;
    }
    
    public function UpdateExplosion() : Void
    {
        if (PlayAnimation())
        {
            active = false;
        }
    }
    
    
    
    public function UpdateShard() : Void
    {
        xpos += xvel;
        ypos += yvel;
        yvel += 0.3;
        if (ypos > 500)
        {
            active = false;
        }
        angle += dirVel;
    }
    
    public var velmul : Float;
    public function InitShard(_type : Int, _r : Float) : Void
    {
        if (_type == 0)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem1_shards");
        }
        else if (_type == 1)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem2_shards");
        }
        else if (_type == 2)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem3_shards");
        }
        else if (_type == 3)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem4_shards");
        }
        else if (_type == 4)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem5_shards");
        }
        else if (_type == 5)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem6_shards");
        }
        else if (_type == 6)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem9_shards");
        }
        else if (_type == 7)
        {
            dobj = GraphicObjects.GetDisplayObjByName("gem8_shards");
        }
        
        updateFunction = UpdateShard;
        frameVel = 0;
        maxframe = dobj.GetNumFrames();
        frame = 0;
        frame = Utils.RandBetweenInt(0, dobj.GetNumFrames() - 1);
        
        var _d : Float = 6;
        
        var r : Float = Utils.RandCircle();
        var d : Float = _d;
        xpos += Math.cos(r) * d;
        ypos += Math.sin(r) * d;
        
        var _d : Float = 3;
        
        var d : Float = _d;
        xvel = Math.cos(r) * d;
        yvel = Math.sin(r) * d;
        
        velmul = Utils.RandBetweenFloat(0.8, 0.95);
        angle = Utils.RandCircle();
        dirVel = Utils.RandBetweenFloat(-0.4, 0.4);
    }
    
    
    
    public function UpdateSpark() : Void
    {
        xpos += xvel;
        ypos += yvel;
        
        xvel *= velmul;
        yvel *= velmul;
        if (ypos > 500)
        {
            active = false;
        }
        
        
        
        
        alpha -= 12;
        if (alpha <= 0)
        {
            alpha = 0;
            active = false;
        }
    }
    
    public function InitSpark(_type : Int, _r : Float, _d : Float) : Void
    {
        psize = 3;
        color = 0x00ffffff;
        updateFunction = UpdateSpark;
        
        
        
        var r : Float = _r;
        var d : Float = _d;
        xpos += Math.cos(r) * d;
        ypos += Math.sin(r) * d;
        
        var r : Float = _r;
        var d : Float = _d;
        xvel = Math.cos(r) * d;
        yvel = Math.sin(r) * d;
        
        velmul = 0.9;
        
        timer = 15;
        alpha = 255;
    }
    
    
    
    public function InitMultiplier() : Void
    {
        psize = 3;
        
        startx = xpos;
        starty = ypos;
        
        var d : Float = Utils.RandCircle();
        
        dir = Utils.RandCircle();
        radius = Utils.RandBetweenInt(30, 60);
        
        dirVel = Utils.RandBetweenFloat(0.05, 0.1);
        
        color = 0xffff0036;
        if (Utils.RandBetweenInt(0, 100) < 50)
        {
            color = 0xff80c0;
        }
        
        updateFunction = UpdateMultiplier;
    }
    
    
    
    public function UpdateMultiplier() : Void
    {
        var xd : Float = Math.cos(dir) * radius;
        var yd : Float = Math.sin(dir) * radius;
        xpos = startx + xd;
        ypos = starty + yd;
        
        dir += dirVel;
        radius -= 1;
        if (radius < 10)
        {
            timer = 0;
            active = false;
        }
    }
    
    
    
    
    public function InitPandaEaten() : Void
    {
        psize = Utils.RandBetweenInt(1, 3);
        
        var d : Float = Utils.RandCircle();
        
        dir = Utils.RandCircle();
        speed = Utils.RandBetweenFloat(1, 2);
        
        dirVel = Utils.RandBetweenFloat(0.1, 0.2);
        
        color = 0xfffff036;
        timer = Utils.RandBetweenInt(30, 50);
        
        updateFunction = UpdatePandaEaten;
    }
    
    
    
    public function UpdatePandaEaten() : Void
    {
        var xd : Float = Math.cos(dir) * speed;
        var yd : Float = Math.sin(dir) * speed;
        xpos += xd;
        ypos += yd;
        
        speed += 0.3;
        dir += dirVel;
        
        timer--;
        if (timer <= 0)
        {
            timer = 0;
            active = false;
        }
    }
    
    
    
    
    public function InitPandaFireTrail(_type : Int) : Void
    {
        psize = Utils.RandBetweenInt(1, 3);
        
        var d : Float = Utils.RandCircle();
        var v : Float = Math.NaN;        
        xpos += Utils.RandBetweenFloat(-6, 6);
        ypos += Utils.RandBetweenFloat(-6, 6);
        
        yacc = Utils.RandBetweenFloat(0.05, 0.2);
        yvel = Utils.RandBetweenFloat(0, 1);
        
        color = 0xffffa000;
        if (Utils.RandBetweenInt(0, 100) < 50)
        {
            color = 0xffffff00;
        }
        timer = Utils.RandBetweenInt(25, 35);
        
        updateFunction = UpdatePandaFireTrail;
    }
    
    
    
    public function UpdatePandaFireTrail() : Void
    {
        yvel += yacc;
        ypos += yvel;
        timer--;
        if (timer <= 0)
        {
            timer = 0;
            active = false;
        }
    }
    
    
    
    public function InitPandaLaunch(_angle : Float) : Void
    {
        psize = Utils.RandBetweenInt(2, 3);
        
        var d : Float = _angle + Utils.RandBetweenFloat(-0.2, 0.2);
        
        xpos += Utils.RandBetweenFloat(-6, 6);
        ypos += Utils.RandBetweenFloat(-6, 6);
        
        speed = Utils.RandBetweenFloat(3, 10);
        xvel = Math.cos(d) * speed;
        yvel = Math.sin(d) * speed;
        
        
        color = 0xffffa000;
        if (Utils.RandBetweenInt(0, 100) < 50)
        {
            color = 0xffff0036;
        }
        timer = Utils.RandBetweenInt(25, 35);
        
        updateFunction = UpdatePandaLaunch;
    }
    
    
    
    public function UpdatePandaLaunch() : Void
    {
        yvel += 0.1;
        xpos += xvel;
        ypos += yvel;
        xvel *= 0.97;
        yvel *= 0.97;
        
        timer--;
        if (timer <= 0)
        {
            timer = 0;
            active = false;
        }
    }
    
    
    
    
    public function InitAddScore(_type : Int) : Void
    {
        psize = 2;
        var d : Float = Utils.RandCircle();
        var v : Float = Math.NaN;        if (_type == 0)
        {
            v = Utils.RandBetweenFloat(2, 5);
            color = 0xffffffff;
            timer = Utils.RandBetweenInt(10, 20);
        }
        else if (_type == 1)
        {
            v = Utils.RandBetweenFloat(8, 12);
            color = 0xffff0036;
            timer = Utils.RandBetweenInt(20, 30);
        }
        
        xvel = Math.cos(d) * v;
        yvel = Math.sin(d) * v;
        updateFunction = UpdateAddScore;
    }
    
    
    
    public function UpdateAddScore() : Void
    {
        yvel += 0.1;
        xpos += xvel;
        ypos += yvel;
        xvel *= 0.95;
        yvel *= 0.95;
        timer--;
        if (timer <= 0)
        {
            timer = 0;
            active = false;
        }
    }
    
    
    
    
    
    
    public function PlayAnimation() : Bool
    {
        frame = frame + frameVel;
        if (frame >= maxframe)
        {
            frame = maxframe;
            return true;
        }
        return false;
    }
    public function CycleAnimation() : Bool
    {
        frame = frame + frameVel;
        if (frame >= maxframe)
        {
            frame = 0;
            return true;
        }
        return false;
    }

    public function new()
    {
    }
}


