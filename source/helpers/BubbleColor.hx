package helpers;

class BubbleColor
{
	static inline final BLACK = "black";
	static inline final BLUE = "blue";
	static inline final BROWN = "brown";
	static inline final GREEN = "green";
	static inline final RED = "red";
	static inline final YELLOW = "yellow";
	static inline final CYAN = "cyan"; // removed from game

	public static function get(index:Int):String
	{
		switch index
		{
			case 0:
				return BLACK;
			case 1:
				return BLUE;
			case 2:
				return BROWN;
			case 3:
				return GREEN;
			case 4:
				return RED;
			case 5:
				return YELLOW;
			default:
				return "empty spot";
		}

		// throw new haxe.Exception("Not a valid bubble index. Valid indexes are 0 - 5");
	}
}
