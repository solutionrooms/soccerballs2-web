package audioPackage;

import flash.events.Event;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import org.flashdevelop.utils.FlashConnect;

class PitchControl
{
    public var rate(get, set) : Float;

    public var BLOCK_SIZE(default, never) : Int = 2048;
    
    public var _mp3 : Sound;
    public var _sound : Sound;
    
    public var _target : ByteArray;
    public var _position : Float;
    public var _rate : Float;
    
    public var active : Bool = false;
    
    public function new(soundName : String)
    {
        firstTime = true;
        
        active = false;
        
        _target = new ByteArray();
        
        var classRef : Class<Dynamic> = Type.getClass(Type.resolveClass(soundName));
        _mp3 = try cast(Type.createInstance(classRef, []), Sound) catch(e:Dynamic) null;
        
        
        
        var ba1 : ByteArray = new ByteArray();
        ba = new ByteArray();
        _mp3.extract(ba, _mp3.length * 44.1, 0);
        _mp3.extract(ba1, _mp3.length * 44.1, 0);
        
        var i : Int;
        ba1.position = 0;
        ba.position = ba.length;
        for (i in 0..._mp3.length * 44.1)
        {
            ba.writeByte(ba1.readByte());
        }
        
        volume = 0;
        
        
        
        
        
        
        
        
        mp3length = _mp3.length * 44.1;
        
        
        
        
        
        
        
        
        
        
        
        _position = 0.0;
        _rate = 1.0;
        
        _sound = new Sound();
        _sound.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData, false, 0, true);
        
        
        
        _sound.play();
    }
    
    
    
    public function StartAgain()
    {
        if (active == false)
        {
            return;
        }
        _sound = new Sound();
        _sound.addEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
        _sound.play();
    }
    public function Stop()
    {
        _sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, sampleData);
        
        
        
        _target = null;
        _mp3 = null;
        _sound = null;
        active = false;
    }
    
    public var firstTime : Bool;
    public var mp3length : Int;
    public var ba : ByteArray;
    
    public var volume : Float;
    
    public function get_rate() : Float
    {
        return _rate;
    }
    
    public function set_rate(value : Float) : Float
    {
        if (value < 0.0)
        {
            value = 0;
        }
        
        _rate = value;
        return value;
    }
    
    public function complete(event : Event) : Void
    {
        _position = 0;
    }
    
    public function sampleData(event : SampleDataEvent) : Void
    {
        _target.position = 0;
        
        
        var data : ByteArray = event.data;
        
        var scaledBlockSize : Float = BLOCK_SIZE * _rate;
        var positionInt : Int = as3hx.Compat.parseInt(_position);
        
        
        var alpha : Float = _position - positionInt;
        
        var positionTargetNum : Float = alpha;
        var positionTargetInt : Int = -1;
        
        
        var need : Int = as3hx.Compat.parseInt(Math.ceil(scaledBlockSize) + 2);
        
        
        
        
        var read : Int = need;
        
        var i : Int;
        _target.position = 0;
        ba.position = positionInt * 8;
        for (i in 0...need)
        {
            _target.writeFloat(ba.readFloat());
            _target.writeFloat(ba.readFloat());
        }
        
        
        
        var n : Int = (read == need) ? BLOCK_SIZE : Std.int(read / _rate);
        
        var l0 : Float;
        var r0 : Float;
        var l1 : Float;
        var r1 : Float;
        
        n -= 32;
        
        var v : Float = volume;
        if (Audio.IsMuteSFX())
        {
            v = 0;
        }
        
        
        
        for (i in 0...n)
        {
            if (as3hx.Compat.parseInt(positionTargetNum) != positionTargetInt)
            {
                positionTargetInt = as3hx.Compat.parseInt(positionTargetNum);
                
                
                _target.position = positionTargetInt << 3;
                
                
                l0 = _target.readFloat();
                r0 = _target.readFloat();
                
                l1 = _target.readFloat();
                r1 = _target.readFloat();
            }
            
            
            data.writeFloat(l0 * v);
            data.writeFloat(l1 * v);
            
            
            
            
            
            
            positionTargetNum += _rate;
            
            
            alpha += _rate;
            while (alpha >= 1.0)
            {
                --alpha;
            }
        }
        
        
        if (i < BLOCK_SIZE)
        {
            while (i < BLOCK_SIZE)
            {
                data.writeFloat(0.0);
                data.writeFloat(0.0);
                
                ++i;
            }
        }
        
        
        _position += scaledBlockSize;
        if (_position >= mp3length)
        {
            _position = 0;
        }
    }
}

