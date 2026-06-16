// Faithful replacement for AS3 Array.sortOn(field, Array.NUMERIC | Array.DESCENDING):
// sort in place by a numeric object field, largest first. Used for z-order draw sorting.
class Sort {
	public static function numericDesc(arr:Array<Dynamic>, field:String):Array<Dynamic> {
		arr.sort(function(a, b) {
			var av:Float = Reflect.field(a, field);
			var bv:Float = Reflect.field(b, field);
			return (av > bv) ? -1 : (av < bv ? 1 : 0);
		});
		return arr;
	}
}
