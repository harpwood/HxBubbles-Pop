package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import helpers.BubbleColor;
import helpers.Level;
import objects.Bubble;
import objects.Cannon;

using flixel.util.FlxSpriteUtil;

class PlayState extends FlxState
{
	static inline final IS_CONNECTED = "is_connected";

	/**
	 * The x of the top left bubble spot
	 */
	private final GRID_X:Int = 210;

	/**
	 * The y of the top left bubble spot
	 */
	private final GRID_Y:Int = 151;

	/**
	 * total columns of the grid
	 */
	private final COLS:Int = 7;

	/**
	 * total rows of the grid
	 */
	private final ROWS:Int = 10;

	/**
	 * Radius of the bubble
	 */
	private final R:Float = 25; // radius

	/**
	 * Diameter of bubble
	 */
	private final D:Float = 50; // diameter

	/**
	 * total colors of bubbles
	 */
	private final TOTAL_COLORS:Int = 6;

	/**
	 * the speed of the launching bubble from cannon in pixels
	 */
	private final BUBBLE_SPEED:Int = 15;

	/**
	 * the refference of an empty spot in grid
	 */
	private final EMPTY:Int = -1;

	/**
	 * The vertical distance between the center of circle from even COLS to the center of circle of odd COLS bellow
	 */
	private var V:Float;

	/**
	 * The cannon object
	 */
	private var cannon:Cannon;

	/**
	 * true if the cannon has fired a bubble
	 */
	private var hasFired:Bool = false;

	/**
	 * The bubble the cannon launched
	 */
	private var currentBubble:Bubble;

	/**
	 * the x direction of the launched bubble
	 */
	private var dirX:Float;

	/**
	 * the y direction of the launched bubble
	 */
	private var dirY:Float;

	/**
	 * The flx sprite group of landed bubbles
	 */
	private var bubbles:FlxSpriteGroup;

	/**
	 * The grid that will store the color index of each occupied spot by landed bubbles
	 */
	private var grid:Array<Array<Int>>;

	/**
	 * array to store the chained bubbles
	 */
	private var chains:Array<String>;

	// debug vars
	private var canDebug:Bool = false;
	private var statusText:FlxText;
	private var square:FlxSprite;
	private var canvas:FlxSprite;

	private var isGameOver:Bool = false;
	private var wellDone:FlxSprite;

	/**
	 * The dots that help aiming with the cannon
	 */
	private var dots:FlxSpriteGroup;

	override public function create()
	{
		super.create();

		// using this because we are drawing some shapes dynamically
		FlxG.stage.quality = flash.display.StageQuality.BEST;

		// place bg. I leave on porpose the mockup, just to see how I started
		var bg = new FlxSprite(0, 0, "assets/images/bg.png");
		// var bg = new FlxSprite(0, 0, "assets/images/mockup.png");
		add(bg);

		// add semi transparent square for status text
		square = new FlxSprite();
		square.makeGraphic(FlxG.width, 35, FlxColor.WHITE);
		square.x = 0;
		square.y = 0;
		square.alpha = .75;
		add(square);

		statusText = new FlxText(0, 0, FlxG.width, "", 12);
		statusText.color = FlxColor.RED;
		statusText.alignment = FlxTextAlign.CENTER;
		add(statusText);
		bubbles = new FlxSpriteGroup();
		add(bubbles);

		// The vertical distance between the center of circle from the row with even tiles to the center of circle of the row with odd tiles bellow
		V = R * Math.sqrt(3);

		// init game
		drawGrid();
		drawBorders();

		// aiming dots for the cannon
		dots = new FlxSpriteGroup();
		add(dots);
		for (i in 0...14)
		{
			var dot = new FlxSprite();
			dot.makeGraphic(5, 5, FlxColor.TRANSPARENT, true);
			var lineStyle:LineStyle = {color: FlxColor.RED, thickness: 0};
			var drawStyle:DrawStyle = {smoothing: false};
			dot.drawCircle(3, 3, 2, FlxColor.RED, lineStyle, drawStyle);
			dot.alpha = .5;
			dots.add(dot);
		}

		cannon = new Cannon(326, 572);
		cannon.X(362);
		cannon.Y(626);
		add(cannon);

		loadCannon();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// shows debug info when hovering the bubbles grid. Pressin "D" enables it
		if (canDebug)
		{
			if (canvas.alpha > 0)
			{
				var point:FlxPoint = FlxG.mouse.getPosition();

				var row:Int = Math.floor((point.y - GRID_Y + R) / V);
				var col:Int = Math.floor((point.x - GRID_X) / D);
				var maxCol = COLS - 2;
				if (row % 2 == 0)
				{
					col = Math.floor((point.x - GRID_X + R) / D);
					maxCol = COLS - 1;
				}

				if (row > ROWS - 1 || row < 0)
					statusText.text = "";
				else if (col > maxCol || col < 0)
					statusText.text = "";
				else
				{
					var count = 0;
					for (r in 0...ROWS)
					{
						for (c in 0...COLS)
						{
							if (grid[r][c] != -1)
								count++;
						}
					}

					statusText.text = "Landed bubbles: " + bubbles.length + " Registered bubbles: " + count;
					statusText.text += "\nrow: " + row + " col: " + col + " - " + BubbleColor.get(grid[row][col]);
				}

				if (statusText.text == "")
					square.alpha = 0;
				else
					square.alpha = .75;
			}
			else
			{
				statusText.text = "";
				square.alpha = 0;
			}
		}

		if (FlxG.keys.justPressed.R)
			FlxG.resetGame();

		// enable/disable debug info
		if (FlxG.keys.justPressed.D)
			canvas.alpha = canvas.alpha > 0 ? 0 : .15;

		// I used this to easily get the coordinates of varius sprites and elements, just by clicking on the mockup
		if (FlxG.mouse.justPressed)
		{
			trace(FlxG.mouse.getWorldPosition());
		}

		if (!isGameOver)
		{
			if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.UP)
			{
				if (!hasFired)
				{
					trace("");
					trace("------------------------ FIRE!!! ---------------------------");
					trace("");
					// get the diraction of the launched bubble, based on cannon's angle
					dirX = BUBBLE_SPEED * Math.cos(FlxAngle.asRadians(cannon.angle - 90));
					dirY = BUBBLE_SPEED * Math.sin(FlxAngle.asRadians(cannon.angle - 90));
					hasFired = true;
				}
			}

			if (hasFired)
			{
				// moving launched bubble
				currentBubble.X(currentBubble.getX() + dirX);
				currentBubble.Y(currentBubble.getY() + dirY);

				// collision with left border
				if (currentBubble.getX() < GRID_X)
				{
					currentBubble.X(GRID_X);
					dirX *= -1;
				}

				// collision with right border
				if (currentBubble.getX() > GRID_X + (COLS - 1) * D)
				{
					currentBubble.X(GRID_X + (COLS - 1) * D);
					dirX *= -1;
				}

				// collision with the ceilling
				if (currentBubble.getY() < GRID_Y)
				{
					currentBubble.Y(GRID_Y);
					landBubble();
					hasFired = false;
				}
				// collision with landed bubble
				else
				{
					var i = bubbles.length;
					while (i > 0)
					{
						i--;
						var bubble:Bubble;
						bubble = cast(bubbles.members[i], Bubble);
						// launch
						if (isCollidingWith(bubble))
						{
							// if the launched bubble lands bellow the grid then game over
							var row:Int = Math.round((currentBubble.getY() - GRID_Y) / V);
							if (row == ROWS)
							{
								isGameOver = true;
								var gameOver:FlxSprite = new FlxSprite(GRID_X + 5, (cannon.y - GRID_Y) * Math.max(Math.min(Math.random(), 1), .5),
									"assets/images/gameover.png");
								if (Math.round(Math.random()) == 0)
									gameOver.angle += Math.random() * 15;
								else
									gameOver.angle -= Math.random() * 15;
								add(gameOver);
							}
							// else land the babble
							else
								landBubble();
							break;
						}
					}
				}
			}

			// if there is no landed bubbles on grid then you win
			if (bubbles.length == 0)
			{
				isGameOver = true;

				wellDone = new FlxSprite(GRID_X + 5, (cannon.y - GRID_Y) * Math.max(Math.min(Math.random(), 1), .5), "assets/images/welldone.png");
				if (Math.round(Math.random()) == 0)
					wellDone.angle += Math.random() * 15;
				else
					wellDone.angle -= Math.random() * 15;
				add(wellDone);
			}

			// getting direction of the aiming dots, based on cannon rotation
			var dX = BUBBLE_SPEED * 1.2 * Math.cos(FlxAngle.asRadians(cannon.angle - 90));
			var dY = BUBBLE_SPEED * 1.2 * Math.sin(FlxAngle.asRadians(cannon.angle - 90));

			// allign dots on aiming path
			for (i in 0...dots.length)
			{
				dots.members[i].x = cannon.getX() + dX * (i + 4);
				dots.members[i].y = cannon.getY() + dY * (i + 4);

				// aiming path bouncing on left and right borders
				if (dots.members[i].x < GRID_X)
					dots.members[i].x = cannon.getX() + (-dX) * (i + 4) - (COLS - 1) * D;
				if (dots.members[i].x > GRID_X + (COLS - 1) * D)
					dots.members[i].x = cannon.getX() + (-dX) * (i + 4) + (COLS - 1) * D;
			}
		}
		// if game over remove the aiming dots
		else
		{
			remove(dots);
		}
	}

	/**
	 * Creates the core arrays and draws the grid (playfield)
	 */
	function drawGrid()
	{
		// the canvas that will be drawn the debug circles grid
		var color:FlxColor = FlxColor.TRANSPARENT;
		canvas = new FlxSprite();
		canvas.makeGraphic(FlxG.width, FlxG.height, color, true);
		add(canvas);

		var lineStyle:LineStyle = {color: FlxColor.BLACK, thickness: 1};
		var drawStyle:DrawStyle = {smoothing: true};

		// while drawing the debug circles grid, populate the grid array with the landed bubbles data
		grid = new Array();
		for (row in 0...ROWS)
		{
			grid[row] = new Array();
			for (col in 0...COLS)
			{
				if (row % 2 == 0)
					canvas.drawCircle(GRID_X + D * col, GRID_Y + V * row, 25, color, lineStyle, drawStyle);
				else if (col < COLS - 1)
					canvas.drawCircle(GRID_X + D * col + R, GRID_Y + V * row, 25, color, lineStyle, drawStyle);

				// get the data from premade level
				grid[row][col] = Level.ONE[row][col];

				// if the current spot is not empty, place the appropriate bubble
				if (grid[row][col] != EMPTY)
				{
					// The even rows have different numbers of cols than odd rows
					if (row % 2 == 0)
					{
						var bubble:Bubble = new Bubble(grid[row][col]);
						bubble.X(GRID_X + D * col);
						bubble.Y(GRID_Y + V * row);
						bubble.name = Std.string(row) + " " + Std.string(col);
						bubbles.add(bubble);
					}
					else if (col < COLS - 1)
					{
						var bubble:Bubble = new Bubble(grid[row][col]);
						bubble.X(GRID_X + D * col + R);
						bubble.Y(GRID_Y + V * row);
						bubble.name = Std.string(row) + " " + Std.string(col);
						bubbles.add(bubble);
					}
				}
			}
		}

		// hide the debug canvas (until "D" key pressed)
		canvas.alpha = 0;

		// now we can check the arrays for debuging
		canDebug = true;
	}

	/**
	 * Draws the left and right borders of the playfield
	 */
	function drawBorders()
	{
		var color:FlxColor = FlxColor.TRANSPARENT;
		var borders = new FlxSprite();
		borders.makeGraphic(FlxG.width, FlxG.height, color, true);
		add(borders);

		var lineStyle:LineStyle = {color: FlxColor.BLUE, thickness: 1};
		var drawStyle:DrawStyle = {smoothing: true};
		borders.drawLine(GRID_X - R, GRID_Y - R, GRID_X - R, GRID_Y + 510, lineStyle, drawStyle);
		borders.drawLine(GRID_X + (COLS - 1) * D + R, GRID_Y - R, GRID_X + (COLS - 1) * D + R, GRID_Y + 510, lineStyle, drawStyle);

		borders.alpha = .25;
	}

	/**
	 * Loads the cannon with a random bubble
	 * TODO add also the NEXT bubble
	 */
	function loadCannon()
	{
		var index = Math.floor(Math.random() * TOTAL_COLORS);

		currentBubble = new Bubble(index);
		currentBubble.index = index;
		currentBubble.X(cannon.getX());
		currentBubble.Y(cannon.getY());
		add(currentBubble);
	}

	/**
	 * positions the landed bubble, updates the grid array and checks for chains
	 */
	function landBubble()
	{
		// position the landed bubble

		// create the bubble that will be positioned (will replace the launced one)
		var bubble:Bubble = new Bubble(currentBubble.index); // get the index of the launced bubble

		// determine the row, based on launced bubble position, place it on y
		var row:Int = Math.round((currentBubble.getY() - GRID_Y) / V);
		bubble.Y(GRID_Y + row * V);

		// determine the col, based on bubble position, place it on x
		var col:Int;
		if (row % 2 == 0)
		{
			col = Math.round((currentBubble.getX() - GRID_X) / D);
			bubble.X(GRID_X + (col * D));
		}
		else
		{
			col = Math.round((currentBubble.getX() - GRID_X - R) / D);
			bubble.X(GRID_X + (col * D) + R);
		}
		trace("landed bubble positioned at row " + row + " col: " + col);
		// update its name to be able to retrieve it when needed
		bubble.name = Std.string(row) + " " + Std.string(col);

		// put it in flx sprite group
		bubbles.add(bubble);

		// update the grid data
		grid[row][col] = currentBubble.index;

		// create a chain array and check for chains
		chains = new Array();
		checkforChainAt(row, col);
		trace("chain length: " + chains.length + " -> " + chains);

		// if the chain has more than 2 bubbles
		if (chains.length > 2)
		{
			trace("chain: " + chains);
			var toDestroy:Array<Bubble> = new Array();
			for (i in 0...chains.length)
			{
				var j = bubbles.length;
				while (j > 0)
				{
					j--;
					var bubbl:Bubble = cast(bubbles.members[j], Bubble);
					if (bubbl != null)
					{
						// retrieve them with their name, remove them, queue them in array to destroy them
						if (bubbl.name == chains[i])
						{
							trace("bubble name: " + bubbl.name);
							var d:Bubble = cast(bubbles.remove(bubbl, true), Bubble);
							toDestroy.push(d);
						}
					}
					else
						trace("------------------------------the bubble at " + chains[i] + " is null!");
				}
				trace("removing bubble at " + chains[i]);

				// remove their reference in grid array
				var pos:Array<String> = chains[i].split(" ");
				grid[Std.parseInt(pos[0])][Std.parseInt(pos[1])] = EMPTY;

				// destroy the queued bubbles
				for (i in 0...toDestroy.length)
				{
					toDestroy[i].destroy();
				}
			}
		}
		// destroy the launched bubble, we do not need it anymore
		currentBubble.destroy();

		// check if there are any disconnected bubbles
		dropNotConnectedBubbles();

		// prepare for the next bubble to get ready for launch
		hasFired = false;
		loadCannon();
	}

	/**
	 * Check if launched bubble collides with the [bubble]
	 * @param bubble 
	 * @return Bool true is collides
	 */
	function isCollidingWith(bubble:Bubble):Bool
	{
		var dX:Float = bubble.getX() - currentBubble.getX(); // distanse of x
		var dY:Float = bubble.getY() - currentBubble.getY(); // distanse of j

		// loosening the collistion sensitivity by 5%. This may need tweaking
		return Math.sqrt(Math.pow(dX, 2) + Math.pow(dY, 2)) <= D * .95;
	}

	/**
	 * The fill flood algrirthm for lookng from chains at [row] and [col]
	 * @param row 
	 * @param col 
	 */
	function checkforChainAt(row:Int, col:Int)
	{
		// put the checking row and col at the chain array
		var pos:String = Std.string(row) + " " + Std.string(col);
		chains.push(pos);

		// check all the neighbor tiles for same index
		var mod:Int = row % 2;
		var index:Int = grid[row][col];
		for (r in -1...2)
		{
			for (c in -1...2)
			{
				if ((c == -1 && mod == 0) || (c == 1 && mod == 1) || r == 0 || c == 0)
				{
					// if neighbor tile with same index found chect it (fill flood)
					trace("checking row: " + Std.string(row + r) + "(" + r + ")" + " col: " + Std.string(col + c) + "(" + c + ")");
					if (isBubbleExistsInChain(index, row + r, col + c))
					{
						trace("found match at row: " + row + " col: " + col);
						checkforChainAt(row + r, col + c);
					}
					else
						trace("NOT found match at row:" + row + " col:" + col);
				}
			}
		}
	}

	/**
	 * Check if the [index] exist in grid array at [row],[col] and make sure that is not already included in chain array (infinite loop protection)
	 * @param index 
	 * @param row 
	 * @param col 
	 * @return Bool returns true if everything in description applies
	 */
	function isBubbleExistsInChain(index:Int, row:Int, col:Int):Bool
	{
		return index == getColorIndexFrom(row, col) && chains.indexOf(row + " " + col) == -1;
	}

	/**
	 * retrieve the color index at [row],[col] of grid array
	 * @param row 
	 * @param col 
	 * @return Int the color index
	 */
	function getColorIndexFrom(row:Int, col:Int):Int
	{
		if (row > ROWS - 1 || row < 0)
			return -1;

		var maxCols = COLS - 2;
		if (row % 2 == 0)
			maxCols = COLS - 1;

		if (col > maxCols || col < 0)
			return -1;

		return grid[row][col];
	}

	private var connectArray = [];

	/**
	 * Will make the disconnected bubbles to fall
	 */
	function dropNotConnectedBubbles()
	{
		// the array that will populated by disconected bubbles that will fall
		var toFall = [];
		// scan the whole playfield except the very top row
		for (row in 1...ROWS)
		{
			for (col in 0...COLS)
			{
				// if the spot has a bubble
				if (getColorIndexFrom(row, col) != EMPTY)
				{
					connectArray = new Array();
					// check for connections (fill flood)
					checkForConnectedAt(row, col);
					// if not connected add the to fall array
					if (connectArray[0] != IS_CONNECTED)
					{
						var j = bubbles.length;
						while (j > 0)
						{
							j--;
							var bubbl:Bubble = cast(bubbles.members[j], Bubble);

							var name = Std.string(row) + " " + Std.string(col);
							if (bubbl.name == name)
							{
								trace("bubble name to drop: " + bubbl.name);
								var d:Bubble = cast(bubbles.remove(bubbl, true), Bubble);
								toFall.push(d);
							}
						}
						grid[row][col] = EMPTY;
					}
				}
			}
		}

		// tween them (fall)
		for (i in 0...toFall.length)
		{
			add(toFall[i]);
			FlxTween.tween(toFall[i], {y: toFall[i].y + FlxG.width}, .7, {onComplete: killBubble.bind(_, toFall[i]), ease: FlxEase.quadIn});
		}
	}

	/**
	 * Destroy the fallen [bubble] when the [tween] is over
	 * @param tween 
	 * @param bubble 
	 */
	function killBubble(tween:FlxTween, bubble:Bubble)
	{
		bubble.destroy();
	}

	/**
	 * The fill flood algrirthm for lookng from connections at [row] and [col]
	 * @param row 
	 * @param col 
	 */
	function checkForConnectedAt(row:Int, col:Int)
	{
		// put the checking row and col at the connect array
		connectArray.push(row + " " + col);
		// check all the neighbor tiles for connections
		var odd:Int = row % 2;
		for (i in -1...2)
		{
			for (j in -1...2)
			{
				if (i == 0 || j == 0 || (j == -1 && odd == 0) || (j == 1 && odd == 1))
				{
					// if is connected mark it in connect array
					if (isBubbleConnected(row + i, col + j))
					{
						if (row + i == 0)
						{
							connectArray[0] = IS_CONNECTED;
						}
						// else keep looking (fill flood)
						else
						{
							checkForConnectedAt(row + i, col + j);
						}
					}
				}
			}
		}
	}

	/**
	 * Check if the spot grid array at [row],[col] is empty and make sure that is not already included in connect array (infinite loop protection)
	 * @param row 
	 * @param col 
	 * @return Bool returns true if everything in description applies
	 */
	private function isBubbleConnected(row:Int, col:Int):Bool
	{
		return getColorIndexFrom(row, col) != EMPTY && connectArray.indexOf(row + " " + col) == -1;
	}
}
