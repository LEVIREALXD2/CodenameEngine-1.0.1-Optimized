package mobile.objects;

#if TOUCH_CONTROLS
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxTileFrames;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.display.BitmapData;
import openfl.utils.Assets;

/**
 * ...
 * @author: Karim Akra and Homura Akemi (HomuHomu833)
 */
@:access(mobile.objects.TouchButton)
@:build(mobile.funkin.backend.system.macros.TouchPadMacro.build())
class TouchPad extends MobileInputManager
{
	public var buttonLeft2:TouchButton = new TouchButton(0, 0, [MobileInputID.LEFT2]);
	public var buttonUp2:TouchButton = new TouchButton(0, 0, [MobileInputID.UP2]);
	public var buttonRight2:TouchButton = new TouchButton(0, 0, [MobileInputID.RIGHT2]);
	public var buttonDown2:TouchButton = new TouchButton(0, 0, [MobileInputID.DOWN2]);

	public var instance:MobileInputManager;
	public var curDPadMode(default, null):String = "NONE";
	public var curActionMode(default, null):String = "NONE";

	/**
	 * Create a gamepad.
	 *
	 * @param   DPadMode     The D-Pad mode. `LEFT_FULL` for example.
	 * @param   ActionMode   The action buttons mode. `A_B_C` for example.
	 */
	public function new(DPad:String, Action:String)
	{
		super();

		if (DPad != "NONE")
		{
			if (!MobileData.dpadModes.exists(DPad))
				throw 'The touchPad dpadMode "$DPad" doesn\'t exist.';

			for (buttonData in MobileData.dpadModes.get(DPad).buttons)
			{
				Reflect.setField(this, buttonData.button,
					createButton(buttonData.x, buttonData.y, buttonData.graphic, getColorFromString(buttonData.color),
						Reflect.getProperty(this, buttonData.button).IDs));
				add(Reflect.field(this, buttonData.button));
			}
		}

		if (Action != "NONE")
		{
			if (!MobileData.actionModes.exists(Action))
				throw 'The touchPad actionMode "$Action" doesn\'t exist.';

			for (buttonData in MobileData.actionModes.get(Action).buttons)
			{
				Reflect.setField(this, buttonData.button,
					createButton(buttonData.x, buttonData.y, buttonData.graphic, getColorFromString(buttonData.color),
						Reflect.getProperty(this, buttonData.button).IDs));
				add(Reflect.field(this, buttonData.button));
			}
		}

		curDPadMode = DPad;
		curActionMode = Action;
		alpha = Options.touchPadAlpha;
		scrollFactor.set();
		updateTrackedButtons();

		instance = this;
	}

	override public function destroy()
	{
		super.destroy();

		for (fieldName in Reflect.fields(this))
		{
			var field = Reflect.field(this, fieldName);
			if (Std.isOfType(field, TouchButton))
				Reflect.setField(this, fieldName, FlxDestroyUtil.destroy(field));
		}
	}

	private function createButton(X:Float, Y:Float, Graphic:String, ?Color:FlxColor = 0xFFFFFF, ?IDs:Array<MobileInputID>):TouchButton
	{
		var button = new TouchButton(X, Y, IDs);
		var buttonLabelGraphicPath:String = "";
		#if MOD_SUPPORT
		final moddyFolder:String = (ModsFolder.currentModFolder != null
			&& ModsFolder.currentModFolder != "default") ? '${ModsFolder.modsPath}${ModsFolder.currentModFolder}/mobile' : '';
		#end

		if (Options.oldPadTexture)
		{
			var frames:FlxGraphic = null;
			final defaultPathBase:String = 'assets/mobile/images/virtualpad/${Graphic.toLowerCase()}';
			#if MOD_SUPPORT
			final moddyPathBase:String = '$moddyFolder/images/virtualpad/${Graphic.toLowerCase()}';
			#end

			var buttonLabelGraphicPath:String = null;

			#if MOD_SUPPORT
			for (ext in Flags.IMAGE_EXTS)
			{
				var modPath = '$moddyPathBase.$ext';
				if (FileSystem.exists(modPath))
				{
					buttonLabelGraphicPath = modPath;
					break;
				}
			}
			#end

			if (buttonLabelGraphicPath == null)
			{
				for (ext in Flags.IMAGE_EXTS)
				{
					var defaultPath = '$defaultPathBase.$ext';
					if (FileSystem.exists(defaultPath))
					{
						buttonLabelGraphicPath = defaultPath;
						break;
					}
				}
			}

			if (buttonLabelGraphicPath != null)
			{
				frames = FlxGraphic.fromBitmapData(BitmapData.fromBytes(File.getBytes(buttonLabelGraphicPath)));
			}
			else
			{
				for (ext in Flags.IMAGE_EXTS)
				{
					var defaultPath = '$defaultPathBase.$ext';
					if (Assets.exists(defaultPath))
					{
						frames = FlxGraphic.fromBitmapData(Assets.getBitmapData(defaultPath));
						break;
					}
				}
			}

			button.antialiasing = Options.antialiasing;
			button.frames = FlxTileFrames.fromGraphic(frames, FlxPoint.get(Std.int(frames.width / 2), frames.height));

			if (Color != -1)
				button.color = Color;
		}
		else
		{
			var buttonGraphicPath:String = "";
			var buttonLabelGraphicPath:String = "";
			final defaultPathBase:String = 'assets/mobile';
			#if MOD_SUPPORT
			final moddyPathBase:String = '$moddyFolder/mobile';
			#end

			for (file in ["bg", Graphic.toUpperCase()])
			{
				var found = false;

				#if MOD_SUPPORT
				for (ext in Flags.IMAGE_EXTS)
				{
					var modPath = '$moddyPathBase/images/touchpad/${file}.$ext';
					if (FileSystem.exists(modPath))
					{
						if (file == "bg")
							buttonGraphicPath = modPath;
						else
							buttonLabelGraphicPath = modPath;
						found = true;
						break;
					}
				}
				#end

				if (!found)
				{
					for (ext in Flags.IMAGE_EXTS)
					{
						var defaultPath = '$defaultPathBase/images/touchpad/${file}.$ext';
						if (Assets.exists(defaultPath))
						{
							if (file == "bg")
								buttonGraphicPath = defaultPath;
							else
								buttonLabelGraphicPath = defaultPath;
							break;
						}
					}
				}
			}

			button.label = new FlxSprite();
			button.loadGraphic(buttonGraphicPath);
			button.label.loadGraphic(buttonLabelGraphicPath);
			button.scale.set(0.243, 0.243);
			button.label.antialiasing = button.antialiasing = Options.antialiasing;
			button.color = Color;
		}

		button.updateHitbox();
		button.updateLabelPosition();

		button.bounds.makeGraphic(Std.int(button.width - 50), Std.int(button.height - 50), FlxColor.TRANSPARENT);
		button.centerBounds();

		button.immovable = true;
		button.solid = button.moves = false;
		button.tag = Graphic.toUpperCase();

		if (Options.oldPadTexture)
		{
			button.statusBrightness = [1, 0.8, 0.4];
			button.statusIndicatorType = BRIGHTNESS;
			button.indicateStatus();
			button.parentAlpha = button.alpha;
		}

		return button;
	}

	private static function getColorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	override function set_alpha(Value):Float
	{
		forEachAlive((button:TouchButton) -> button.parentAlpha = Value);
		return super.set_alpha(Value);
	}
}
#end
