// Haxe-4 port of as3hx's FastXML (the E4X support class the converted code relies
// on). The original used `implements Dynamic<T>` for x.node.foo / x.att.foo style
// access, which Haxe 4 forbids on non-externs; this rewrites the five accessor
// helpers as abstracts with @:op(a.b) (the same idiom haxe.xml.Access uses).
//
// Also: the constructor accepts Dynamic (an Xml, an XML string, or an embedded
// asset instance) and parses as needed, matching AS3 `new XML(data)`; and the
// `ignoreWhitespace` flag the converted code sets is honoured by stripping
// whitespace-only text nodes on parse.

private abstract NodeAccess(Xml) from Xml {
	@:op(a.b) public function resolve(name:String):FastXML {
		var x = this.elementsNamed(name).next();
		if (x == null) {
			var xname = if (this.nodeType == Xml.Document) "Document" else this.nodeName;
			throw xname + " is missing element " + name;
		}
		return new FastXML(x);
	}
}

private abstract AttribAccess(Xml) from Xml {
	@:op(a.b) public function resolve(name:String):String {
		if (this.nodeType == Xml.Document)
			throw "Cannot access document attribute " + name;
		var v = this.get(name);
		if (v == null)
			throw this.nodeName + " is missing attribute " + name;
		return v;
	}
}

private abstract HasAttribAccess(Xml) from Xml {
	@:op(a.b) public function resolve(name:String):Bool {
		if (this.nodeType == Xml.Document)
			throw "Cannot access document attribute " + name;
		return this.exists(name);
	}
}

private abstract HasNodeAccess(Xml) from Xml {
	@:op(a.b) public function resolve(name:String):Bool {
		return this.elementsNamed(name).hasNext();
	}
}

private abstract NodeListAccess(Xml) from Xml {
	@:op(a.b) public function resolve(name:String):FastXMLList {
		var l = new Array<FastXML>();
		for (x in this.elementsNamed(name))
			l.push(new FastXML(x));
		return new FastXMLList(l);
	}
}

class FastXML {
	public static var ignoreWhitespace:Bool = false;

	public var x(default, null):Xml;
	public var name(get, null):String;
	public var innerData(get, null):String;
	public var innerHTML(get, null):String;
	public var node(default, null):NodeAccess;
	public var nodes(default, null):NodeListAccess;
	public var att(default, null):AttribAccess;
	public var has(default, null):HasAttribAccess;
	public var hasNode(default, null):HasNodeAccess;
	public var elements(get, null):Iterator<FastXML>;

	// Accepts an Xml node, an XML string, or any value whose string form is XML
	// (e.g. an embedded asset instance) — mirroring AS3 `new XML(data)`.
	public function new(data:Dynamic) {
		var xx:Xml;
		if (Std.isOfType(data, Xml)) {
			xx = cast data;
		} else {
			var doc = Xml.parse(Std.string(data));
			if (ignoreWhitespace) stripWhitespace(doc);
			xx = doc.firstElement();
			if (xx == null) xx = doc;
		}
		if (xx.nodeType != Xml.Document && xx.nodeType != Xml.Element)
			throw "Invalid nodeType " + xx.nodeType;
		this.x = xx;
		node = xx;
		nodes = xx;
		att = xx;
		has = xx;
		hasNode = xx;
	}

	static function stripWhitespace(x:Xml):Void {
		var remove = [];
		for (c in x) {
			if ((c.nodeType == Xml.PCData || c.nodeType == Xml.CData) && StringTools.trim(c.nodeValue) == "")
				remove.push(c);
			else if (c.nodeType == Xml.Element)
				stripWhitespace(c);
		}
		for (c in remove) x.removeChild(c);
	}

	public function appendChild(a:Dynamic) {
		if (Std.isOfType(a, Xml)) x.addChild(a); else x.addChild(Xml.parse(a));
	}

	public function descendants(name:String = "*"):FastXMLList {
		var a = new Array<FastXML>();
		for (e in x.elements()) {
			if (e.nodeName == name || name == "*") {
				a.push(new FastXML(e));
			} else {
				var fx = new FastXML(e);
				a = a.concat(fx.descendants(name).getArray());
			}
		}
		return new FastXMLList(a);
	}

	public function getAttribute(name:String):String {
		if (x.nodeType == Xml.Document)
			throw "Cannot access document attribute " + name;
		return x.get(name);
	}

	function get_name():String {
		return if (x.nodeType == Xml.Document) "Document" else x.nodeName;
	}

	function get_innerData():String {
		var it = x.iterator();
		if (!it.hasNext())
			throw name + " does not have data";
		var v = it.next();
		var n = it.next();
		if (n != null) {
			if (v.nodeType == Xml.PCData && n.nodeType == Xml.CData && StringTools.trim(v.nodeValue) == "") {
				var n2 = it.next();
				if (n2 == null || (n2.nodeType == Xml.PCData && StringTools.trim(n2.nodeValue) == "" && it.next() == null))
					return n.nodeValue;
			}
			throw name + " does not only have data";
		}
		if (v.nodeType != Xml.PCData && v.nodeType != Xml.CData)
			throw name + " does not have data";
		return v.nodeValue;
	}

	function get_innerHTML():String {
		var s = new StringBuf();
		for (c in x) s.add(c.toString());
		return s.toString();
	}

	function get_elements():Iterator<FastXML> {
		var it = x.elements();
		return {
			hasNext: it.hasNext,
			next: function() {
				var e = it.next();
				if (e == null) return null;
				return new FastXML(e);
			}
		};
	}

	public function length():Int {
		return 1;
	}

	public function setAttribute(name:String, value:String):Void {
		if (x.nodeType == Xml.Document)
			throw "Cannot access document attribute " + name;
		x.set(name, value);
	}

	public function toString():String {
		return x.toString();
	}

	public static function parse(s:String):FastXML {
		return new FastXML(s);
	}

	public static function filterNodes(a:FastXMLList, f:FastXML->Bool):FastXMLList {
		var rv = new Array<FastXML>();
		for (i in a)
			if (f(i)) rv.push(i);
		return new FastXMLList(rv);
	}
}
