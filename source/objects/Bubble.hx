package objects;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import helpers.BubbleColor;

class Bubble extends FlxSprite
{
	public var index(default, default):Int;
	public var name(default, default):String;

	public function new(_index:Int, ?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		index = _index;
		var asset:String = BubbleColor.get(index);

		loadGraphic("assets/images/" + asset + ".png", false, 50, 50);
	}

	// manages the position relatevily to an ideal pivot point (center)
	public function X(_x:Float)
	{
		x = _x - width * .5;
	}

	public function Y(_y:Float)
	{
		y = _y - height * .5;
	}

	public function getX():Float
	{
		return x + width * .5;
	}

	public function getY():Float
	{
		return y + height * .5;
	}
}
