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

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.media.Sound;
import flash.net.FileReference;
import flash.utils.ByteArray;
import flash.utils.Endian;

/**
	 * Dispatched when the MP3 data is loaded
	* @eventType org.audiofx.mp3.MP3SoundEvent.COMPLETE 
	* 
	*/
@:meta(Event(name="complete",type="org.audiofx.mp3.MP3SoundEvent"))

/**
	 * Class for loading MP3 files from a FileReference
	 * @author spender
	 * @see flash.net.FileReference
	 */
class MP3FileReferenceLoader extends EventDispatcher
{
    private var mp3Parser : MP3Parser;
    
    /**
		 * Constructs an new MP3FileReferenceLoader instance 
		 * 
		 */
    public function new()
    {
        super();
        mp3Parser = new MP3Parser();
        mp3Parser.addEventListener(Event.COMPLETE, parserCompleteHandler);
    }
    /**
		 * Once a FileReference instance has been obtained, and the user has browsed to a file, call getSound to start loading the MP3 data.
		 * When the data is ready, an <code>MP3SoundEvent.COMPLETE</code> event is emitted.
		 * @param fr A reference to a local file.
		 * @see MP3SoundEvent
		 */
    public function getSound(fr : FileReference) : Void
    {
        mp3Parser.loadFileRef(fr);
    }
    private function parserCompleteHandler(ev : Event) : Void
    {
        var parser : MP3Parser = try cast(ev.currentTarget, MP3Parser) catch(e:Dynamic) null;
        generateSound(parser);
    }
    private function generateSound(mp3Source : MP3Parser) : Bool
    {
        var swfBytes : ByteArray = new ByteArray();
        swfBytes.endian = Endian.LITTLE_ENDIAN;
        for (i in 0...SoundClassSwfByteCode.soundClassSwfBytes1.length)
        {
            swfBytes.writeByte(SoundClassSwfByteCode.soundClassSwfBytes1[i]);
        }
        var swfSizePosition : Int = swfBytes.position;
        swfBytes.writeInt(0);  //swf size will go here  
        for (i in 0...SoundClassSwfByteCode.soundClassSwfBytes2.length)
        {
            swfBytes.writeByte(SoundClassSwfByteCode.soundClassSwfBytes2[i]);
        }
        var audioSizePosition : Int = swfBytes.position;
        swfBytes.writeInt(0);  //audiodatasize+7 to go here  
        swfBytes.writeByte(1);
        swfBytes.writeByte(0);
        mp3Source.writeSwfFormatByte(swfBytes);
        
        var sampleSizePosition : Int = swfBytes.position;
        swfBytes.writeInt(0);  //number of samples goes here  
        
        swfBytes.writeByte(0);  //seeksamples  
        swfBytes.writeByte(0);
        
        var frameCount : Int = 0;
        
        var byteCount : Int = 0;  //this includes the seeksamples written earlier  
        
        while (true)
        {
            var seg : ByteArraySegment = mp3Source.getNextFrame();
            if (seg == null)
            {
                break;
            }
            swfBytes.writeBytes(seg.byteArray, seg.start, seg.length);
            byteCount += seg.length;
            frameCount++;
        }
        if (byteCount == 0)
        {
            return false;
        }
        byteCount += 2;
        
        var currentPos : Int = swfBytes.position;
        swfBytes.position = audioSizePosition;
        swfBytes.writeInt(byteCount + 7);
        swfBytes.position = sampleSizePosition;
        swfBytes.writeInt(frameCount * 1152);
        swfBytes.position = currentPos;
        for (i in 0...SoundClassSwfByteCode.soundClassSwfBytes3.length)
        {
            swfBytes.writeByte(SoundClassSwfByteCode.soundClassSwfBytes3[i]);
        }
        swfBytes.position = swfSizePosition;
        swfBytes.writeInt(swfBytes.length);
        swfBytes.position = 0;
        var swfBytesLoader : Loader = new Loader();
        swfBytesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, swfCreated);
        swfBytesLoader.loadBytes(swfBytes);
        return true;
    }
    private function swfCreated(ev : Event) : Void
    {
        var loaderInfo : LoaderInfo = try cast(ev.currentTarget, LoaderInfo) catch(e:Dynamic) null;
        var soundClass : Class<Dynamic> = Type.getClass(loaderInfo.applicationDomain.getDefinition("SoundClass"));
        var sound : Sound = Type.createInstance(soundClass, []);
        dispatchEvent(new MP3SoundEvent(MP3SoundEvent.COMPLETE, sound));
    }
}
