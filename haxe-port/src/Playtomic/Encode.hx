  //  This file is part of the official Playtomic API for ActionScript 3 games.    //  Playtomic is a real time analytics platform for casual games    //  and services that go in casual games.  If you haven't used it    //  before check it out:    //  http://playtomic.com/    //    //  Created by ben at the above domain on 2/25/11.    //  Copyright 2011 Playtomic LLC. All rights reserved.    //    //  Documentation is available at:    //  http://playtomic.com/api/as3    //    // PLEASE NOTE:    // You may modify this SDK if you wish but be kind to our servers.  Be    // careful about modifying the analytics stuff as it may give you    // borked reports.    //    // If you make any awesome improvements feel free to let us know!    //    // -------------------------------------------------------------------------    // THIS SOFTWARE IS PROVIDED BY PLAYTOMIC, LLC "AS IS" AND ANY    // EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    // IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR    // PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR    // CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,    // EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,    // PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    // PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    // LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING    // NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS    // SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  package playtomic;

import flash.display.BitmapData;
import flash.utils.ByteArray;

@:final class Encode
{  // ----------------------------------------------------------------------------    // Base64 encoding    // ----------------------------------------------------------------------------    // http://dynamicflash.com/goodies/base64/    //    // Copyright (c) 2006 Steve Webster    // Permission is hereby granted, free of charge, to any person obtaining a copy of    // this software and associated documentation files (the "Software"), to deal in    // the Software without restriction, including without limitation the rights to    // use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of    // the Software, and to permit persons to whom the Software is furnished to do so,    // subject to the following conditions:    // The above copyright notice and this permission notice shall be included in all    // copies or substantial portions of the Software.  private static inline var BASE64_CHARS : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";@:allow(playtomic)
    private static function Base64(data : ByteArray) : String
    {
        var output : String = "";var dataBuffer : Array<Dynamic>;var outputBuffer : Array<Dynamic> = new Array<Dynamic>(4);var i : Int;var j : Int;var k : Int;data.position = 0;while (data.bytesAvailable > 0)
        {
            dataBuffer = new Array<Dynamic>();i = 0;
            while (i < 3 && data.bytesAvailable > 0)
            {
                dataBuffer[i] = data.readUnsignedByte();
                i++;
            }outputBuffer[0] = (dataBuffer[0] & 0xfc) >> 2;outputBuffer[1] = ((dataBuffer[0] & 0x03) << 4) | ((dataBuffer[1]) >> 4);outputBuffer[2] = ((dataBuffer[1] & 0x0f) << 2) | ((dataBuffer[2]) >> 6);outputBuffer[3] = dataBuffer[2] & 0x3f;for (j in dataBuffer.length...3)
            {
                outputBuffer[j + 1] = 64;
            }for (k in 0...outputBuffer.length)
            {
                output += BASE64_CHARS.charAt(outputBuffer[k]);
            }
        }return output;
    }  // BASE 64 decoding via http://www.foxarc.com/blog/article/60.htm  private static var decodeChars : Array<Dynamic> = [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1, -1, -1, -1, -1];@:allow(playtomic)
    private static function Base64Decode(str : String) : ByteArray
    {
        var c1 : Int;var c2 : Int;var c3 : Int;var c4 : Int;var i : Int;var len : Int;var out : ByteArray;len = str.length;i = 0;out = new ByteArray();while (i < len)
        
        // c1{
            do
            {
                c1 = decodeChars[str.charCodeAt(i++) & 0xff];
            }
            while ((i < len && c1 == -1));if (c1 == -1)
            {
                break;
            }  // c2  do
            {
                c2 = decodeChars[str.charCodeAt(i++) & 0xff];
            }
            while ((i < len && c2 == -1));if (c2 == -1)
            {
                break;
            }out.writeByte((c1 << 2) | ((c2 & 0x30) >> 4));  // c3  do
            {
                c3 = str.charCodeAt(i++) & 0xff;if (c3 == 61)
                {
                    return out;
                }c3 = decodeChars[c3];
            }
            while ((i < len && c3 == -1));if (c3 == -1)
            {
                break;
            }out.writeByte(((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2));  // c4  do
            {
                c4 = str.charCodeAt(i++) & 0xff;if (c4 == 61)
                {
                    return out;
                }c4 = decodeChars[c4];
            }
            while ((i < len && c4 == -1));if (c4 == -1)
            {
                break;
            }out.writeByte(((c3 & 0x03) << 6) | c4);
        }return out;
    }  // ----------------------------------------------------------------------------    // PNG encoding    // ----------------------------------------------------------------------------    // http://code.google.com/p/as3corelib/source/browse/trunk/src/com/adobe/images/PNGEncoder.as    //    // Copyright (c) 2008, Adobe Systems Incorporated    // All rights reserved.  @:allow(playtomic)
    private static function PNG(img : BitmapData) : ByteArray
    // Create output byte array
    {
        var png : ByteArray = new ByteArray();png.writeUnsignedInt(0x89504e47);png.writeUnsignedInt(0x0D0A1A0A);var IHDR : ByteArray = new ByteArray();IHDR.writeInt(img.width);IHDR.writeInt(img.height);IHDR.writeUnsignedInt(0x08060000);  // 32bit RGBA  IHDR.writeByte(0);writeChunk(png, 0x49484452, IHDR);var IDAT : ByteArray = new ByteArray();var p : Int;var j : Int;for (i in 0...img.height)
        
        // no filter{
            IDAT.writeByte(0);if (!img.transparent)
            {
                for (j in 0...img.width)
                {
                    p = img.getPixel(j, i);IDAT.writeUnsignedInt(as3hx.Compat.parseInt(((p & 0xFFFFFF) << 8) | 0xFF));
                }
            }
            else
            {
                for (j in 0...img.width)
                {
                    p = img.getPixel32(j, i);IDAT.writeUnsignedInt(as3hx.Compat.parseInt(((p & 0xFFFFFF) << 8) | (p >>> 24)));
                }
            }
        }IDAT.compress();writeChunk(png, 0x49444154, IDAT);writeChunk(png, 0x49454E44, null);return png;
    }private static var crcTable : Array<Dynamic>;private static var crcTableComputed : Bool = false;private static function writeChunk(png : ByteArray, type : Int, data : ByteArray) : Void
    {
        if (!crcTableComputed)
        {
            crcTableComputed = true;crcTable = [];var c : Int;for (n in 0...256)
            {
                c = n;for (k in 0...8)
                {
                    if ((c & 1) != 0)
                    {
                        c = as3hx.Compat.parseInt(0xedb88320 ^ as3hx.Compat.parseInt(c >>> 1));
                    }
                    else
                    {
                        c = as3hx.Compat.parseInt(c >>> 1);
                    }
                }crcTable[n] = c;
            }
        }var len : Int = 0;if (data != null)
        {
            len = data.length;
        }png.writeUnsignedInt(len);var p : Int = png.position;png.writeUnsignedInt(type);if (data != null)
        {
            png.writeBytes(data);
        }var e : Int = png.position;png.position = p;c = 0xffffffff;for (i in 0...(e - p))
        {
            c = as3hx.Compat.parseInt(crcTable[as3hx.Compat.parseInt(c ^ png.readUnsignedByte()) & 0xff] ^ as3hx.Compat.parseInt(c >>> 8));
        }c = as3hx.Compat.parseInt(c ^ 0xffffffff);png.position = e;png.writeUnsignedInt(c);
    }  // ------------------------------------------------------------------------------    // MD5 stuff    // ------------------------------------------------------------------------------    // A JavaScript implementation of the RSA Data Security, Inc. MD5 Message    // Digest Algorithm, as defined in RFC 1321.    // Copyright (C) Paul Johnston 1999 - 2000.    // Updated by Greg Holt 2000 - 2001.    // See http://pajhome.org.uk/site/legal.html for details.    // Updated by Ger Hobbelt 2001 (Flash 5) - works for totally buggered MAC Flash player and, of course, Windows / Linux as well.    // Updated by Ger Hobbelt 2008 (Flash 9 / AS3) - quick fix.  private static var hex_chr : String = "0123456789abcdef";private static function bitOR(a : Float, b : Float) : Float
    {
        var lsb : Float = (as3hx.Compat.parseInt(a) & 0x1) | (as3hx.Compat.parseInt(b) & 0x1);var msb31 : Float = (a >>> 1) | (b >>> 1);return (msb31 << 1) | lsb;
    }private static function bitXOR(a : Float, b : Float) : Float
    {
        var lsb : Float = (as3hx.Compat.parseInt(a) & 0x1) ^ (as3hx.Compat.parseInt(b) & 0x1);var msb31 : Float = (a >>> 1) ^ (b >>> 1);return (msb31 << 1) | lsb;
    }private static function bitAND(a : Float, b : Float) : Float
    {
        var lsb : Float = as3hx.Compat.parseInt(as3hx.Compat.parseInt(a) & 0x1) & as3hx.Compat.parseInt(as3hx.Compat.parseInt(b) & 0x1);var msb31 : Float = as3hx.Compat.parseInt(a >>> 1) & as3hx.Compat.parseInt(b >>> 1);return (msb31 << 1) | lsb;
    }private static function addme(x : Float, y : Float) : Float
    {
        var lsw : Float = (as3hx.Compat.parseInt(x) & 0xFFFF) + (as3hx.Compat.parseInt(y) & 0xFFFF);var msw : Float = (x >> 16) + (y >> 16) + (lsw >> 16);return (msw << 16) | (as3hx.Compat.parseInt(lsw) & 0xFFFF);
    }private static function rhex(num : Float) : String
    {
        var str : String = "";var j : Int;for (j in 0...3)
        {
            str += hex_chr.charAt(as3hx.Compat.parseInt(num >> (j * 8 + 4)) & 0x0F) + hex_chr.charAt(as3hx.Compat.parseInt(num >> (j * 8)) & 0x0F);
        }return str;
    }private static function str2blks_MD5(str : String) : Array<Dynamic>
    {
        var nblk : Float = ((str.length + 8) >> 6) + 1;var blks : Array<Dynamic> = new Array<Dynamic>(nblk * 16);var i : Int;for (i in 0...nblk * 16)
        {
            blks[i] = 0;
        }for (i in 0...str.length)
        {
            blks[i >> 2] = blks[i >> 2] | str.charCodeAt(i) << (((str.length * 8 + i) % 4) * 8);
        }blks[i >> 2] = blks[i >> 2] | 0x80 << (((str.length * 8 + i) % 4) * 8);var l : Int = as3hx.Compat.parseInt(str.length * 8);blks[nblk * 16 - 2] = (l & 0xFF);blks[nblk * 16 - 2] = blks[nblk * 16 - 2] | (as3hx.Compat.parseInt(l >>> 8) & 0xFF) << 8;blks[nblk * 16 - 2] = blks[nblk * 16 - 2] | (as3hx.Compat.parseInt(l >>> 16) & 0xFF) << 16;blks[nblk * 16 - 2] = blks[nblk * 16 - 2] | (as3hx.Compat.parseInt(l >>> 24) & 0xFF) << 24;return blks;
    }private static function rol(num : Float, cnt : Float) : Float
    {
        return (num << cnt) | (num >>> (32 - cnt));
    }private static function cmn(q : Float, a : Float, b : Float, x : Float, s : Float, t : Float) : Float
    {
        return addme(rol(addme(addme(a, q), addme(x, t)), s), b);
    }private static function ff(a : Float, b : Float, c : Float, d : Float, x : Float, s : Float, t : Float) : Float
    {
        return cmn(bitOR(bitAND(b, c), bitAND(~b, d)), a, b, x, s, t);
    }private static function gg(a : Float, b : Float, c : Float, d : Float, x : Float, s : Float, t : Float) : Float
    {
        return cmn(bitOR(bitAND(b, d), bitAND(c, ~d)), a, b, x, s, t);
    }private static function hh(a : Float, b : Float, c : Float, d : Float, x : Float, s : Float, t : Float) : Float
    {
        return cmn(bitXOR(bitXOR(b, c), d), a, b, x, s, t);
    }private static function ii(a : Float, b : Float, c : Float, d : Float, x : Float, s : Float, t : Float) : Float
    {
        return cmn(bitXOR(c, bitOR(b, ~d)), a, b, x, s, t);
    }@:allow(playtomic)
    private static function MD5(str : String) : String
    {
        var x : Array<Dynamic> = str2blks_MD5(str);var a : Float = 1732584193;var b : Float = -271733879;var c : Float = -1732584194;var d : Float = 271733878;var i : Int;i = 0;
        while (i < x.length)
        {
            var olda : Float = a;var oldb : Float = b;var oldc : Float = c;var oldd : Float = d;a = ff(a, b, c, d, x[i + 0], 7, -680876936);d = ff(d, a, b, c, x[i + 1], 12, -389564586);c = ff(c, d, a, b, x[i + 2], 17, 606105819);b = ff(b, c, d, a, x[i + 3], 22, -1044525330);a = ff(a, b, c, d, x[i + 4], 7, -176418897);d = ff(d, a, b, c, x[i + 5], 12, 1200080426);c = ff(c, d, a, b, x[i + 6], 17, -1473231341);b = ff(b, c, d, a, x[i + 7], 22, -45705983);a = ff(a, b, c, d, x[i + 8], 7, 1770035416);d = ff(d, a, b, c, x[i + 9], 12, -1958414417);c = ff(c, d, a, b, x[i + 10], 17, -42063);b = ff(b, c, d, a, x[i + 11], 22, -1990404162);a = ff(a, b, c, d, x[i + 12], 7, 1804603682);d = ff(d, a, b, c, x[i + 13], 12, -40341101);c = ff(c, d, a, b, x[i + 14], 17, -1502002290);b = ff(b, c, d, a, x[i + 15], 22, 1236535329);a = gg(a, b, c, d, x[i + 1], 5, -165796510);d = gg(d, a, b, c, x[i + 6], 9, -1069501632);c = gg(c, d, a, b, x[i + 11], 14, 643717713);b = gg(b, c, d, a, x[i + 0], 20, -373897302);a = gg(a, b, c, d, x[i + 5], 5, -701558691);d = gg(d, a, b, c, x[i + 10], 9, 38016083);c = gg(c, d, a, b, x[i + 15], 14, -660478335);b = gg(b, c, d, a, x[i + 4], 20, -405537848);a = gg(a, b, c, d, x[i + 9], 5, 568446438);d = gg(d, a, b, c, x[i + 14], 9, -1019803690);c = gg(c, d, a, b, x[i + 3], 14, -187363961);b = gg(b, c, d, a, x[i + 8], 20, 1163531501);a = gg(a, b, c, d, x[i + 13], 5, -1444681467);d = gg(d, a, b, c, x[i + 2], 9, -51403784);c = gg(c, d, a, b, x[i + 7], 14, 1735328473);b = gg(b, c, d, a, x[i + 12], 20, -1926607734);a = hh(a, b, c, d, x[i + 5], 4, -378558);d = hh(d, a, b, c, x[i + 8], 11, -2022574463);c = hh(c, d, a, b, x[i + 11], 16, 1839030562);b = hh(b, c, d, a, x[i + 14], 23, -35309556);a = hh(a, b, c, d, x[i + 1], 4, -1530992060);d = hh(d, a, b, c, x[i + 4], 11, 1272893353);c = hh(c, d, a, b, x[i + 7], 16, -155497632);b = hh(b, c, d, a, x[i + 10], 23, -1094730640);a = hh(a, b, c, d, x[i + 13], 4, 681279174);d = hh(d, a, b, c, x[i + 0], 11, -358537222);c = hh(c, d, a, b, x[i + 3], 16, -722521979);b = hh(b, c, d, a, x[i + 6], 23, 76029189);a = hh(a, b, c, d, x[i + 9], 4, -640364487);d = hh(d, a, b, c, x[i + 12], 11, -421815835);c = hh(c, d, a, b, x[i + 15], 16, 530742520);b = hh(b, c, d, a, x[i + 2], 23, -995338651);a = ii(a, b, c, d, x[i + 0], 6, -198630844);d = ii(d, a, b, c, x[i + 7], 10, 1126891415);c = ii(c, d, a, b, x[i + 14], 15, -1416354905);b = ii(b, c, d, a, x[i + 5], 21, -57434055);a = ii(a, b, c, d, x[i + 12], 6, 1700485571);d = ii(d, a, b, c, x[i + 3], 10, -1894986606);c = ii(c, d, a, b, x[i + 10], 15, -1051523);b = ii(b, c, d, a, x[i + 1], 21, -2054922799);a = ii(a, b, c, d, x[i + 8], 6, 1873313359);d = ii(d, a, b, c, x[i + 15], 10, -30611744);c = ii(c, d, a, b, x[i + 6], 15, -1560198380);b = ii(b, c, d, a, x[i + 13], 21, 1309151649);a = ii(a, b, c, d, x[i + 4], 6, -145523070);d = ii(d, a, b, c, x[i + 11], 10, -1120210379);c = ii(c, d, a, b, x[i + 2], 15, 718787259);b = ii(b, c, d, a, x[i + 9], 21, -343485551);a = addme(a, olda);b = addme(b, oldb);c = addme(c, oldc);d = addme(d, oldd);
            i += 16;
        }return rhex(a) + rhex(b) + rhex(c) + rhex(d);
    }

    @:allow(playtomic)
    private function new()
    {
    }
}