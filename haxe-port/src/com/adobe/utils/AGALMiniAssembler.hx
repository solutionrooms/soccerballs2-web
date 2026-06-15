/*
Copyright (c) 2011, Adobe Systems Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Adobe Systems Incorporated nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.adobe.utils;

import flash.utils.*;

class AGALMiniAssembler
{
    public var error(get, never) : String;
    public var agalcode(get, never) : ByteArray;

    
    
    
    
    public var _agalcode : ByteArray = null;
    public var _error : String = "";
    
    public var debugEnabled : Bool = false;
    
    public static var initialized : Bool = false;
    
    
    
    
    public function get_error() : String
    {
        return _error;
    }
    public function get_agalcode() : ByteArray
    {
        return _agalcode;
    }
    
    
    
    
    public function new(debugging : Bool = false)
    {
        debugEnabled = debugging;
        if (!initialized)
        {
            init();
        }
    }
    
    
    
    public function assemble(mode : String, source : String, verbose : Bool = false) : ByteArray
    {
        var start : Int = Math.round(haxe.Timer.stamp() * 1000);
        
        _agalcode = new ByteArray();
        _error = "";
        
        var isFrag : Bool = false;
        
        if (mode == FRAGMENT)
        {
            isFrag = true;
        }
        else if (mode != VERTEX)
        {
            _error = "ERROR: mode needs to be \"" + FRAGMENT + "\" or \"" + VERTEX + "\" but is \"" + mode + "\".";
        }
        
        agalcode.endian = Endian.LITTLE_ENDIAN;
        agalcode.writeByte(0xa0);
        agalcode.writeUnsignedInt(0x1);
        agalcode.writeByte(0xa1);
        agalcode.writeByte((isFrag) ? 1 : 0);
        
        var lines : Array<Dynamic> = new as3hx.Compat.Regex('[\\f\\n\\r\\v]+', "g").replace(source, "\n").split("\n");
        var nest : Int = 0;
        var nops : Int = 0;
        var i : Int = 0;        var lng : Int = lines.length;
        
        i = 0;
        while (i < lng && _error == "")
        {
            var line : String = new Std.string(lines[i]);
            
            
            var startcomment : Int = line.search("//");
            if (startcomment != -1)
            {
                line = line.substring(0, startcomment);
            }
            
            
            var optsi : Int = line.search(new as3hx.Compat.Regex('<.*>', "g"));
            var opts : Array<Dynamic> = null;            if (optsi != -1)
            {
                opts = line.substring(optsi).match(new as3hx.Compat.Regex('([\\w\\.\\-\\+]+)', "gi"));
                line = line.substring(0, optsi);
            }
            
            
            var opCode : Array<Dynamic> = line.match(new as3hx.Compat.Regex('^\\w{3}', "ig"));
            var opFound : OpCode = Reflect.field(OPMAP, Std.string(opCode[0]));
            
            
            if (debugEnabled)
            {
                trace(opFound);
            }
            
            if (opFound == null)
            {
                if (line.length >= 3)
                {
                    trace("warning: bad line " + i + ": " + lines[i]);
                }
                {i++;continue;
                }
            }
            
            line = line.substring(line.search(opFound.name) + opFound.name.length);
            
            
            if ((opFound.flags & OP_DEC_NEST) != 0)
            {
                nest--;
                if (nest < 0)
                {
                    _error = "error: conditional closes without open.";
                    break;
                }
            }
            if ((opFound.flags & OP_INC_NEST) != 0)
            {
                nest++;
                if (nest > MAX_NESTING)
                {
                    _error = "error: nesting to deep, maximum allowed is " + MAX_NESTING + ".";
                    break;
                }
            }
            if (((opFound.flags & OP_FRAG_ONLY) != 0) && !isFrag)
            {
                _error = "error: opcode is only allowed in fragment programs.";
                break;
            }
            if (verbose)
            {
                trace("emit opcode=" + opFound);
            }
            
            agalcode.writeUnsignedInt(opFound.emitCode);
            nops++;
            
            if (nops > MAX_OPCODES)
            {
                _error = "error: too many opcodes. maximum is " + MAX_OPCODES + ".";
                break;
            }
            
            
            var regs : Array<Dynamic> = line.match(new as3hx.Compat.Regex('vc\\[([vof][actps]?)(\\d*)?(\\.[xyzw](\\+\\d{1,3})?)?\\](\\.[xyzw]{1,4})?|([vof][actps]?)(\\d*)?(\\.[xyzw]{1,4})?', "gi"));
            if (regs.length != opFound.numRegister)
            {
                _error = "error: wrong number of operands. found " + regs.length + " but expected " + opFound.numRegister + ".";
                break;
            }
            
            var badreg : Bool = false;
            var pad : Int = as3hx.Compat.parseInt(64 + 64 + 32);
            var regLength : Int = regs.length;
            
            for (j in 0...regLength)
            {
                var isRelative : Bool = false;
                var relreg : Array<Dynamic> = regs[j].match(new as3hx.Compat.Regex('\\[.*\\]', "ig"));
                if (relreg.length > 0)
                {
                    regs[j] = regs[j].replace(relreg[0], "0");
                    
                    if (verbose)
                    {
                        trace("IS REL");
                    }
                    isRelative = true;
                }
                
                var res : Array<Dynamic> = regs[j].match(new as3hx.Compat.Regex('^\\b[A-Za-z]{1,2}', "ig"));
                var regFound : Register = Reflect.field(REGMAP, Std.string(res[0]));
                
                
                if (debugEnabled)
                {
                    trace(regFound);
                }
                
                if (regFound == null)
                {
                    _error = "error: could not parse operand " + j + " (" + regs[j] + ").";
                    badreg = true;
                    break;
                }
                
                if (isFrag)
                {
                    if ((regFound.flags & REG_FRAG) == 0)
                    {
                        _error = "error: register operand " + j + " (" + regs[j] + ") only allowed in vertex programs.";
                        badreg = true;
                        break;
                    }
                    if (isRelative)
                    {
                        _error = "error: register operand " + j + " (" + regs[j] + ") relative adressing not allowed in fragment programs.";
                        badreg = true;
                        break;
                    }
                }
                else if ((regFound.flags & REG_VERT) == 0)
                {
                    _error = "error: register operand " + j + " (" + regs[j] + ") only allowed in fragment programs.";
                    badreg = true;
                    break;
                }
                
                regs[j] = regs[j].slice(regs[j].search(regFound.name) + regFound.name.length);
                
                var idxmatch : Array<Dynamic> = (isRelative) ? relreg[0].match(new as3hx.Compat.Regex('\\d+', "")) : regs[j].match(new as3hx.Compat.Regex('\\d+', ""));
                var regidx : Int = 0;
                
                if (idxmatch != null)
                {
                    regidx = as3hx.Compat.parseInt(idxmatch[0]);
                }
                
                if (regFound.range < regidx)
                {
                    _error = "error: register operand " + j + " (" + regs[j] + ") index exceeds limit of " + (regFound.range + 1) + ".";
                    badreg = true;
                    break;
                }
                
                var regmask : Int = 0;
                var maskmatch : Array<Dynamic> = regs[j].match(new as3hx.Compat.Regex('(\\.[xyzw]{1,4})', ""));
                var isDest : Bool = (j == 0 && !(opFound.flags & OP_NO_DEST));
                var isSampler : Bool = (j == 2 && (opFound.flags & OP_SPECIAL_TEX));
                var reltype : Int = 0;
                var relsel : Int = 0;
                var reloffset : Int = 0;
                
                if (isDest && isRelative)
                {
                    _error = "error: relative can not be destination";
                    badreg = true;
                    break;
                }
                
                if (maskmatch != null)
                {
                    regmask = 0;
                    var cv : Int = 0;                    var maskLength : Int = maskmatch[0].length;
                    for (k in 1...maskLength)
                    {
                        cv = as3hx.Compat.parseInt(maskmatch[0].charCodeAt(k) - "x".charCodeAt(0));
                        if (cv > 2)
                        {
                            cv = 3;
                        }
                        if (isDest)
                        {
                            regmask = regmask | as3hx.Compat.parseInt(1 << cv);
                        }
                        else
                        {
                            regmask = regmask | as3hx.Compat.parseInt(cv << ((k - 1) << 1));
                        }
                    }
                    if (!isDest)
                    {
                        while (k <= 4)
                        {
                            regmask = regmask | as3hx.Compat.parseInt(cv << ((k - 1) << 1));
                            k++;
                        }
                    }
                }
                else
                {
                    regmask = (isDest) ? 0xf : 0xe4;
                }
                
                if (isRelative)
                {
                    var relname : Array<Dynamic> = relreg[0].match(new as3hx.Compat.Regex('[A-Za-z]{1,2}', "ig"));
                    var regFoundRel : Register = Reflect.field(REGMAP, Std.string(relname[0]));
                    if (regFoundRel == null)
                    {
                        _error = "error: bad index register";
                        badreg = true;
                        break;
                    }
                    reltype = regFoundRel.emitCode;
                    var selmatch : Array<Dynamic> = relreg[0].match(new as3hx.Compat.Regex('(\\.[xyzw]{1,1})', ""));
                    if (selmatch.length == 0)
                    {
                        _error = "error: bad index register select";
                        badreg = true;
                        break;
                    }
                    relsel = as3hx.Compat.parseInt(selmatch[0].charCodeAt(1) - "x".charCodeAt(0));
                    if (relsel > 2)
                    {
                        relsel = 3;
                    }
                    var relofs : Array<Dynamic> = relreg[0].match(new as3hx.Compat.Regex('\\+\\d{1,3}', "ig"));
                    if (relofs.length > 0)
                    {
                        reloffset = relofs[0];
                    }
                    if (reloffset < 0 || reloffset > 255)
                    {
                        _error = "error: index offset " + reloffset + " out of bounds. [0..255]";
                        badreg = true;
                        break;
                    }
                    if (verbose)
                    {
                        trace("RELATIVE: type=" + reltype + "==" + relname[0] + " sel=" + relsel + "==" + selmatch[0] + " idx=" + regidx + " offset=" + reloffset);
                    }
                }
                
                if (verbose)
                {
                    trace("  emit argcode=" + regFound + "[" + regidx + "][" + regmask + "]");
                }
                if (isDest)
                {
                    agalcode.writeShort(regidx);
                    agalcode.writeByte(regmask);
                    agalcode.writeByte(regFound.emitCode);
                    pad -= 32;
                }
                else if (isSampler)
                {
                    if (verbose)
                    {
                        trace("  emit sampler");
                    }
                    var samplerbits : Int = 5;
                    var optsLength : Int = opts.length;
                    var bias : Float = 0;
                    for (k in 0...optsLength)
                    {
                        if (verbose)
                        {
                            trace("    opt: " + opts[k]);
                        }
                        var optfound : Sampler = Reflect.field(SAMPLEMAP, Std.string(opts[k]));
                        if (optfound == null)
                        {
                            bias = as3hx.Compat.parseFloat(opts[k]);
                            if (verbose)
                            {
                                trace("    bias: " + bias);
                            }
                        }
                        else
                        {
                            if (optfound.flag != SAMPLER_SPECIAL_SHIFT)
                            {
                                samplerbits = samplerbits & as3hx.Compat.parseInt(~(0xf << optfound.flag));
                            }
                            samplerbits = samplerbits | as3hx.Compat.parseInt(as3hx.Compat.parseInt(optfound.mask) << as3hx.Compat.parseInt(optfound.flag));
                        }
                    }
                    agalcode.writeShort(regidx);
                    agalcode.writeByte(as3hx.Compat.parseInt(bias * 8.0));
                    agalcode.writeByte(0);
                    agalcode.writeUnsignedInt(samplerbits);
                    
                    if (verbose)
                    {
                        trace("    bits: " + (samplerbits - 5));
                    }
                    pad -= 64;
                }
                else
                {
                    if (j == 0)
                    {
                        agalcode.writeUnsignedInt(0);
                        pad -= 32;
                    }
                    agalcode.writeShort(regidx);
                    agalcode.writeByte(reloffset);
                    agalcode.writeByte(regmask);
                    agalcode.writeByte(regFound.emitCode);
                    agalcode.writeByte(reltype);
                    agalcode.writeShort((isRelative) ? (relsel | (1 << 15)) : 0);
                    
                    pad -= 64;
                }
            }
            
            
            j = 0;
            while (j < pad)
            {
                agalcode.writeByte(0);
                j += 8;
            }
            
            if (badreg)
            {
                break;
            }
            i++;
        }
        
        if (_error != "")
        {
            _error += "\n  at line " + i + " " + lines[i];
            agalcode.length = 0;
            trace(_error);
        }
        
        
        if (debugEnabled)
        {
            var dbgLine : String = "generated bytecode:";
            var agalLength : Int = agalcode.length;
            for (index in 0...agalLength)
            {
                if (!(index % 16))
                {
                    dbgLine += "\n";
                }
                if (!(index % 4))
                {
                    dbgLine += " ";
                }
                
                var byteStr : String = Std.string(agalcode[index]);
                if (byteStr.length < 2)
                {
                    byteStr = "0" + byteStr;
                }
                
                dbgLine += byteStr;
            }
            trace(dbgLine);
        }
        
        if (verbose)
        {
            trace("AGALMiniAssembler.assemble time: " + ((Math.round(haxe.Timer.stamp() * 1000) - start) / 1000) + "s");
        }
        
        return agalcode;
    }
    
    public static function init() : Void
    {
        initialized = true;
        
        
        OPMAP[MOV] = new OpCode(MOV, 2, 0x00, 0);
        OPMAP[ADD] = new OpCode(ADD, 3, 0x01, 0);
        OPMAP[SUB] = new OpCode(SUB, 3, 0x02, 0);
        OPMAP[MUL] = new OpCode(MUL, 3, 0x03, 0);
        OPMAP[DIV] = new OpCode(DIV, 3, 0x04, 0);
        OPMAP[RCP] = new OpCode(RCP, 2, 0x05, 0);
        OPMAP[MIN] = new OpCode(MIN, 3, 0x06, 0);
        OPMAP[MAX] = new OpCode(MAX, 3, 0x07, 0);
        OPMAP[FRC] = new OpCode(FRC, 2, 0x08, 0);
        OPMAP[SQT] = new OpCode(SQT, 2, 0x09, 0);
        OPMAP[RSQ] = new OpCode(RSQ, 2, 0x0a, 0);
        OPMAP[POW] = new OpCode(POW, 3, 0x0b, 0);
        OPMAP[LOG] = new OpCode(LOG, 2, 0x0c, 0);
        OPMAP[EXP] = new OpCode(EXP, 2, 0x0d, 0);
        OPMAP[NRM] = new OpCode(NRM, 2, 0x0e, 0);
        OPMAP[SIN] = new OpCode(SIN, 2, 0x0f, 0);
        OPMAP[COS] = new OpCode(COS, 2, 0x10, 0);
        OPMAP[CRS] = new OpCode(CRS, 3, 0x11, 0);
        OPMAP[DP3] = new OpCode(DP3, 3, 0x12, 0);
        OPMAP[DP4] = new OpCode(DP4, 3, 0x13, 0);
        OPMAP[ABS] = new OpCode(ABS, 2, 0x14, 0);
        OPMAP[NEG] = new OpCode(NEG, 2, 0x15, 0);
        OPMAP[SAT] = new OpCode(SAT, 2, 0x16, 0);
        OPMAP[M33] = new OpCode(M33, 3, 0x17, OP_SPECIAL_MATRIX);
        OPMAP[M44] = new OpCode(M44, 3, 0x18, OP_SPECIAL_MATRIX);
        OPMAP[M34] = new OpCode(M34, 3, 0x19, OP_SPECIAL_MATRIX);
        OPMAP[IFZ] = new OpCode(IFZ, 1, 0x1a, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[INZ] = new OpCode(INZ, 1, 0x1b, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[IFE] = new OpCode(IFE, 2, 0x1c, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[INE] = new OpCode(INE, 2, 0x1d, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[IFG] = new OpCode(IFG, 2, 0x1e, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[IFL] = new OpCode(IFL, 2, 0x1f, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[IEG] = new OpCode(IEG, 2, 0x20, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[IEL] = new OpCode(IEL, 2, 0x21, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[ELS] = new OpCode(ELS, 0, 0x22, OP_NO_DEST | OP_INC_NEST | OP_DEC_NEST);
        OPMAP[EIF] = new OpCode(EIF, 0, 0x23, OP_NO_DEST | OP_DEC_NEST);
        OPMAP[REP] = new OpCode(REP, 1, 0x24, OP_NO_DEST | OP_INC_NEST | OP_SCALAR);
        OPMAP[ERP] = new OpCode(ERP, 0, 0x25, OP_NO_DEST | OP_DEC_NEST);
        OPMAP[BRK] = new OpCode(BRK, 0, 0x26, OP_NO_DEST);
        OPMAP[KIL] = new OpCode(KIL, 1, 0x27, OP_NO_DEST | OP_FRAG_ONLY);
        OPMAP[TEX] = new OpCode(TEX, 3, 0x28, OP_FRAG_ONLY | OP_SPECIAL_TEX);
        OPMAP[SGE] = new OpCode(SGE, 3, 0x29, 0);
        OPMAP[SLT] = new OpCode(SLT, 3, 0x2a, 0);
        OPMAP[SGN] = new OpCode(SGN, 2, 0x2b, 0);
        
        REGMAP[VA] = new Register(VA, "vertex attribute", 0x0, 7, REG_VERT | REG_READ);
        REGMAP[VC] = new Register(VC, "vertex constant", 0x1, 127, REG_VERT | REG_READ);
        REGMAP[VT] = new Register(VT, "vertex temporary", 0x2, 7, REG_VERT | REG_WRITE | REG_READ);
        REGMAP[OP] = new Register(OP, "vertex output", 0x3, 0, REG_VERT | REG_WRITE);
        REGMAP[V] = new Register(V, "varying", 0x4, 7, REG_VERT | REG_FRAG | REG_READ | REG_WRITE);
        REGMAP[FC] = new Register(FC, "fragment constant", 0x1, 27, REG_FRAG | REG_READ);
        REGMAP[FT] = new Register(FT, "fragment temporary", 0x2, 7, REG_FRAG | REG_WRITE | REG_READ);
        REGMAP[FS] = new Register(FS, "texture sampler", 0x5, 7, REG_FRAG | REG_READ);
        REGMAP[OC] = new Register(OC, "fragment output", 0x3, 0, REG_FRAG | REG_WRITE);
        
        SAMPLEMAP[D2] = new Sampler(D2, SAMPLER_DIM_SHIFT, 0);
        SAMPLEMAP[D3] = new Sampler(D3, SAMPLER_DIM_SHIFT, 2);
        SAMPLEMAP[CUBE] = new Sampler(CUBE, SAMPLER_DIM_SHIFT, 1);
        SAMPLEMAP[MIPNEAREST] = new Sampler(MIPNEAREST, SAMPLER_MIPMAP_SHIFT, 1);
        SAMPLEMAP[MIPLINEAR] = new Sampler(MIPLINEAR, SAMPLER_MIPMAP_SHIFT, 2);
        SAMPLEMAP[MIPNONE] = new Sampler(MIPNONE, SAMPLER_MIPMAP_SHIFT, 0);
        SAMPLEMAP[NOMIP] = new Sampler(NOMIP, SAMPLER_MIPMAP_SHIFT, 0);
        SAMPLEMAP[NEAREST] = new Sampler(NEAREST, SAMPLER_FILTER_SHIFT, 0);
        SAMPLEMAP[LINEAR] = new Sampler(LINEAR, SAMPLER_FILTER_SHIFT, 1);
        SAMPLEMAP[CENTROID] = new Sampler(CENTROID, SAMPLER_SPECIAL_SHIFT, 1 << 0);
        SAMPLEMAP[SINGLE] = new Sampler(SINGLE, SAMPLER_SPECIAL_SHIFT, 1 << 1);
        SAMPLEMAP[DEPTH] = new Sampler(DEPTH, SAMPLER_SPECIAL_SHIFT, 1 << 2);
        SAMPLEMAP[REPEAT] = new Sampler(REPEAT, SAMPLER_REPEAT_SHIFT, 1);
        SAMPLEMAP[WRAP] = new Sampler(WRAP, SAMPLER_REPEAT_SHIFT, 1);
        SAMPLEMAP[CLAMP] = new Sampler(CLAMP, SAMPLER_REPEAT_SHIFT, 0);
    }
    
    
    
    
    public static var OPMAP : Dictionary<Dynamic, Dynamic> = new Dictionary<Dynamic, Dynamic>();
    public static var REGMAP : Dictionary<Dynamic, Dynamic> = new Dictionary<Dynamic, Dynamic>();
    public static var SAMPLEMAP : Dictionary<Dynamic, Dynamic> = new Dictionary<Dynamic, Dynamic>();
    
    public static inline var MAX_NESTING : Int = 4;
    public static inline var MAX_OPCODES : Int = 256;
    
    public static inline var FRAGMENT : String = "fragment";
    public static inline var VERTEX : String = "vertex";
    
    
    public static inline var SAMPLER_DIM_SHIFT : Int = 12;
    public static inline var SAMPLER_SPECIAL_SHIFT : Int = 16;
    public static inline var SAMPLER_REPEAT_SHIFT : Int = 20;
    public static inline var SAMPLER_MIPMAP_SHIFT : Int = 24;
    public static inline var SAMPLER_FILTER_SHIFT : Int = 28;
    
    
    public static inline var REG_WRITE : Int = 0x1;
    public static inline var REG_READ : Int = 0x2;
    public static inline var REG_FRAG : Int = 0x20;
    public static inline var REG_VERT : Int = 0x40;
    
    
    public static inline var OP_SCALAR : Int = 0x1;
    public static inline var OP_INC_NEST : Int = 0x2;
    public static inline var OP_DEC_NEST : Int = 0x4;
    public static inline var OP_SPECIAL_TEX : Int = 0x8;
    public static inline var OP_SPECIAL_MATRIX : Int = 0x10;
    public static inline var OP_FRAG_ONLY : Int = 0x20;
    public static inline var OP_VERT_ONLY : Int = 0x40;
    public static inline var OP_NO_DEST : Int = 0x80;
    
    
    public static inline var MOV : String = "mov";
    public static inline var ADD : String = "add";
    public static inline var SUB : String = "sub";
    public static inline var MUL : String = "mul";
    public static inline var DIV : String = "div";
    public static inline var RCP : String = "rcp";
    public static inline var MIN : String = "min";
    public static inline var MAX : String = "max";
    public static inline var FRC : String = "frc";
    public static inline var SQT : String = "sqt";
    public static inline var RSQ : String = "rsq";
    public static inline var POW : String = "pow";
    public static inline var LOG : String = "log";
    public static inline var EXP : String = "exp";
    public static inline var NRM : String = "nrm";
    public static inline var SIN : String = "sin";
    public static inline var COS : String = "cos";
    public static inline var CRS : String = "crs";
    public static inline var DP3 : String = "dp3";
    public static inline var DP4 : String = "dp4";
    public static inline var ABS : String = "abs";
    public static inline var NEG : String = "neg";
    public static inline var SAT : String = "sat";
    public static inline var M33 : String = "m33";
    public static inline var M44 : String = "m44";
    public static inline var M34 : String = "m34";
    public static inline var IFZ : String = "ifz";
    public static inline var INZ : String = "inz";
    public static inline var IFE : String = "ife";
    public static inline var INE : String = "ine";
    public static inline var IFG : String = "ifg";
    public static inline var IFL : String = "ifl";
    public static inline var IEG : String = "ieg";
    public static inline var IEL : String = "iel";
    public static inline var ELS : String = "els";
    public static inline var EIF : String = "eif";
    public static inline var REP : String = "rep";
    public static inline var ERP : String = "erp";
    public static inline var BRK : String = "brk";
    public static inline var KIL : String = "kil";
    public static inline var TEX : String = "tex";
    public static inline var SGE : String = "sge";
    public static inline var SLT : String = "slt";
    public static inline var SGN : String = "sgn";
    
    
    public static inline var VA : String = "va";
    public static inline var VC : String = "vc";
    public static inline var VT : String = "vt";
    public static inline var OP : String = "op";
    public static inline var V : String = "v";
    public static inline var FC : String = "fc";
    public static inline var FT : String = "ft";
    public static inline var FS : String = "fs";
    public static inline var OC : String = "oc";
    
    
    public static inline var D2 : String = "2d";
    public static inline var D3 : String = "3d";
    public static inline var CUBE : String = "cube";
    public static inline var MIPNEAREST : String = "mipnearest";
    public static inline var MIPLINEAR : String = "miplinear";
    public static inline var MIPNONE : String = "mipnone";
    public static inline var NOMIP : String = "nomip";
    public static inline var NEAREST : String = "nearest";
    public static inline var LINEAR : String = "linear";
    public static inline var CENTROID : String = "centroid";
    public static inline var SINGLE : String = "single";
    public static inline var DEPTH : String = "depth";
    public static inline var REPEAT : String = "repeat";
    public static inline var WRAP : String = "wrap";
    public static inline var CLAMP : String = "clamp";
}









class OpCode
{
    public var emitCode(get, never) : Int;
    public var flags(get, never) : Int;
    public var name(get, never) : String;
    public var numRegister(get, never) : Int;

    
    
    
    public var _emitCode : Int;
    public var _flags : Int;
    public var _name : String;
    public var _numRegister : Int;
    
    
    
    
    public function get_emitCode() : Int
    {
        return _emitCode;
    }
    public function get_flags() : Int
    {
        return _flags;
    }
    public function get_name() : String
    {
        return _name;
    }
    public function get_numRegister() : Int
    {
        return _numRegister;
    }
    
    
    
    
    public function new(name : String, numRegister : Int, emitCode : Int, flags : Int)
    {
        _name = name;
        _numRegister = numRegister;
        _emitCode = emitCode;
        _flags = flags;
    }
    
    
    
    
    public function toString() : String
    {
        return "[OpCode name=\"" + _name + "\", numRegister=" + _numRegister + ", emitCode=" + _emitCode + ", flags=" + _flags + "]";
    }
}




class Register
{
    public var emitCode(get, never) : Int;
    public var longName(get, never) : String;
    public var name(get, never) : String;
    public var flags(get, never) : Int;
    public var range(get, never) : Int;

    
    
    
    public var _emitCode : Int;
    public var _name : String;
    public var _longName : String;
    public var _flags : Int;
    public var _range : Int;
    
    
    
    
    public function get_emitCode() : Int
    {
        return _emitCode;
    }
    public function get_longName() : String
    {
        return _longName;
    }
    public function get_name() : String
    {
        return _name;
    }
    public function get_flags() : Int
    {
        return _flags;
    }
    public function get_range() : Int
    {
        return _range;
    }
    
    
    
    
    public function new(name : String, longName : String, emitCode : Int, range : Int, flags : Int)
    {
        _name = name;
        _longName = longName;
        _emitCode = emitCode;
        _range = range;
        _flags = flags;
    }
    
    
    
    
    public function toString() : String
    {
        return "[Register name=\"" + _name + "\", longName=\"" + _longName + "\", emitCode=" + _emitCode + ", range=" + _range + ", flags=" + _flags + "]";
    }
}




class Sampler
{
    public var flag(get, never) : Int;
    public var mask(get, never) : Int;
    public var name(get, never) : String;

    
    
    
    public var _flag : Int;
    public var _mask : Int;
    public var _name : String;
    
    
    
    
    public function get_flag() : Int
    {
        return _flag;
    }
    public function get_mask() : Int
    {
        return _mask;
    }
    public function get_name() : String
    {
        return _name;
    }
    
    
    
    
    public function new(name : String, flag : Int, mask : Int)
    {
        _name = name;
        _flag = flag;
        _mask = mask;
    }
    
    
    
    
    public function toString() : String
    {
        return "[Sampler name=\"" + _name + "\", flag=\"" + _flag + "\", mask=" + mask + "]";
    }
}

