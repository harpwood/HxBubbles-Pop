package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

class Cannon extends FlxSprite
{
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);

		loadGraphic("assets/images/cannon.png", false, 72, 109);

		origin.set(width / 2, height * .6);
	}

	override public function update(elapsed:Float):Void
	{
		if (FlxG.keys.pressed.LEFT)
		{
			angle = Math.max(-60, angle - 2);
		}

		if (FlxG.keys.pressed.RIGHT)
		{
			angle = Math.min(60, angle + 2);
		}

		// dirX = BUBBLE_SPEED * Math.cos(FlxAngle.asRadians(cannon.angle - 90));
		// dirY = BUBBLE_SPEED * Math.sin(FlxAngle.asRadians(cannon.angle - 90));
	}

	// manages the position relatevily to an ideal pivot point (lower center)
	public function X(_x:Float)
	{
		x = _x - width * .5;
	}

	public function Y(_y:Float)
	{
		y = _y - height * .6;
	}

	public function getX():Float
	{
		return x + width * .5;
	}

	public function getY():Float
	{
		return y + height * .6;
	}
}
