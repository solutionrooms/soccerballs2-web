/*
Copyright (c) 2008 Christopher Martin-Sperry (audiofx.org@gmail.com)

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
*/

package audioPackage;

import flash.errors.Error;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.FileReference;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;

@:meta(Event(name="complete",type="flash.events.Event"))

class MP3Parser extends EventDispatcher
{
    public var mp3Data : ByteArray;
    public var loader : URLLoader;
    public var currentPosition : Int;
    public var sampleRate : Int;
    public var channels : Int;
    public var version : Int;
    public static var bitRates : Array<Dynamic> = [-1, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, -1, -1, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, -1];
    public static var versions : Array<Dynamic> = [2.5, -1, 2, 1];
    public static var samplingRates : Array<Dynamic> = [44100, 48000, 32000];
    @:allow(audioPackage)
    public function new()
    {
        super();
        
        loader = new URLLoader();
        loader.dataFormat = URLLoaderDataFormat.BINARY;
        loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
    }
    @:allow(audioPackage)
    public function load(url : String) : Void
    {
        var req : URLRequest = new URLRequest(url);
        loader.load(req);
    }
    @:allow(audioPackage)
    public function loadFileRef(fileRef : FileReference) : Void
    {
        fileRef.addEventListener(Event.COMPLETE, loaderCompleteHandler);
        fileRef.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        
        fileRef.load();
    }
    public function errorHandler(ev : IOErrorEvent) : Void
    {
        trace("error\n" + ev.text);
    }
    public function loaderCompleteHandler(ev : Event) : Void
    {
        mp3Data = try cast(ev.currentTarget.data, ByteArray) catch(e:Dynamic) null;
        currentPosition = getFirstHeaderPosition();
        dispatchEvent(ev);
    }
    public function getFirstHeaderPosition() : Int
    {
        mp3Data.position = 0;
        
        
        while (mp3Data.position < mp3Data.length)
        {
            var readPosition : Int = mp3Data.position;
            var str : String = mp3Data.readMultiByte(3, "us-ascii");
            
            
            if (str == "ID3")
            {
                mp3Data.position += 3;
                var b3 : Int = as3hx.Compat.parseInt(mp3Data.readByte() & 0x7F) << 21;
                var b2 : Int = as3hx.Compat.parseInt(mp3Data.readByte() & 0x7F) << 14;
                var b1 : Int = as3hx.Compat.parseInt(mp3Data.readByte() & 0x7F) << 7;
                var b0 : Int = mp3Data.readByte() & 0x7F;
                var headerLength : Int = as3hx.Compat.parseInt(b0 + b1 + b2 + b3);
                var newPosition : Int = as3hx.Compat.parseInt(mp3Data.position + headerLength);
                trace("Found id3v2 header, length " + Std.string(headerLength) + " bytes. Moving to " + Std.string(newPosition));
                mp3Data.position = newPosition;
                readPosition = newPosition;
            }
            else
            {
                mp3Data.position = readPosition;
            }
            
            var val : Int = mp3Data.readInt();
            
            if (isValidHeader(val))
            {
                parseHeader(val);
                mp3Data.position = readPosition + getFrameSize(val);
                if (isValidHeader(mp3Data.readInt()))
                {
                    return readPosition;
                }
            }
        }
        throw (new Error("Could not locate first header. This isn't an MP3 file"));
    }
    @:allow(audioPackage)
    public function getNextFrame() : ByteArraySegment
    {
        mp3Data.position = currentPosition;
        var headerByte : Int;
        var frameSize : Int;
        while (true)
        {
            if (currentPosition > (mp3Data.length - 4))
            {
                trace("passed eof");
                return null;
            }
            headerByte = mp3Data.readInt();
            if (isValidHeader(headerByte))
            {
                frameSize = getFrameSize(headerByte);
                if (frameSize != 0xffffffff)
                {
                    break;
                }
            }
            currentPosition = mp3Data.position;
        }
        
        mp3Data.position = currentPosition;
        
        if ((currentPosition + frameSize) > mp3Data.length)
        {
            return null;
        }
        
        currentPosition += frameSize;
        return new ByteArraySegment(mp3Data, mp3Data.position, frameSize);
    }
    @:allow(audioPackage)
    public function writeSwfFormatByte(byteArray : ByteArray) : Void
    {
        var sampleRateIndex : Int = as3hx.Compat.parseInt(4 - (44100 / sampleRate));
        byteArray.writeByte((2 << 4) + (sampleRateIndex << 2) + (1 << 1) + (channels - 1));
    }
    public function parseHeader(headerBytes : Int) : Void
    {
        var channelMode : Int = getModeIndex(headerBytes);
        version = getVersionIndex(headerBytes);
        var samplingRate : Int = getFrequencyIndex(headerBytes);
        channels = ((channelMode > 2)) ? 1 : 2;
        var actualVersion : Float = versions[version];
        var samplingRates : Array<Dynamic> = [44100, 48000, 32000];
        sampleRate = samplingRates[samplingRate];
        switch (actualVersion)
        {
            case 2:
                sampleRate /= 2;
            case 2.5:
                sampleRate /= 4;
        }
    }
    public function getFrameSize(headerBytes : Int) : Int
    {
        var version : Int = getVersionIndex(headerBytes);
        var bitRate : Int = getBitrateIndex(headerBytes);
        var samplingRate : Int = getFrequencyIndex(headerBytes);
        var padding : Int = getPaddingBit(headerBytes);
        var channelMode : Int = getModeIndex(headerBytes);
        var actualVersion : Float = versions[version];
        var sampleRate : Int = samplingRates[samplingRate];
        if (sampleRate != this.sampleRate || this.version != version)
        {
            return 0xffffffff;
        }
        switch (actualVersion)
        {
            case 2:
                sampleRate /= 2;
            case 2.5:
                sampleRate /= 4;
        }
        var bitRatesYIndex : Int = as3hx.Compat.parseInt((((actualVersion == 1)) ? 0 : 1) * bitRates.length / 2);
        var actualBitRate : Int = as3hx.Compat.parseInt(bitRates[bitRatesYIndex + bitRate] * 1000);
        var frameLength : Int = as3hx.Compat.parseInt(((((actualVersion == 1) ? 144 : 72) * actualBitRate) / sampleRate) + padding);
        return frameLength;
    }
    
    public function isValidHeader(headerBits : Int) : Bool
    {
        return (((getFrameSync(headerBits) & 2047) == 2047) &&
        ((getVersionIndex(headerBits) & 3) != 1) &&
        ((getLayerIndex(headerBits) & 3) != 0) &&
        ((getBitrateIndex(headerBits) & 15) != 0) &&
        ((getBitrateIndex(headerBits) & 15) != 15) &&
        ((getFrequencyIndex(headerBits) & 3) != 3) &&
        ((getEmphasisIndex(headerBits) & 3) != 2));
    }
    
    public function getFrameSync(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 21) & 2047);
    }
    
    public function getVersionIndex(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 19) & 3);
    }
    
    public function getLayerIndex(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 17) & 3);
    }
    
    public function getBitrateIndex(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 12) & 15);
    }
    
    public function getFrequencyIndex(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 10) & 3);
    }
    
    public function getPaddingBit(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 9) & 1);
    }
    
    public function getModeIndex(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerBits >> 6) & 3);
    }
    
    public function getEmphasisIndex(headerBits : Int) : Int
    {
        return as3hx.Compat.parseInt(headerBits & 3);
    }
}

