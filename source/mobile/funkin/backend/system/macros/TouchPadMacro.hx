package mobile.funkin.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.xml.Parser;
import sys.io.File;
import sys.FileSystem;

class TouchPadMacro
{
	public static final GRAPHICS_IGNORE:Array<String> = ['bg'];
	static final IMAGE_EXTS:Array<String> = ["png", "jpg", "jpeg", "astc", "dds"];

	public static macro function build():Array<Field>
	{
		final pos:Position = Context.currentPos();
		final fields:Array<Field> = Context.getBuildFields();
		final newFields:Array<Field> = [];

		for (graphic in getGraphicsList())
		{
			if (GRAPHICS_IGNORE.contains(graphic))
				continue;

			var typePath:TypePath = {
				name: 'TouchButton',
				pack: ['mobile', 'objects']
			};

			var args:Array<Expr> = [
				Context.makeExpr(0, pos),
				Context.makeExpr(0, pos),
				Context.makeExpr([graphic], pos)
			];

			var expr:Expr = {
				expr: ENew(typePath, args),
				pos: pos
			};

			newFields.push({
				name: formatGraphicToButtonName(graphic),
				access: [APublic],
				kind: FVar(macro :mobile.objects.TouchButton, expr),
				pos: pos,
			});
		}

		return fields.concat(newFields);
	}

	private static function getGraphicsList():Array<String>
	{
		#if ios
		final graphicsPath:String = "../../../../../assets/mobile/images/touchpad/";
		#else
		final graphicsPath:String = "assets/mobile/images/touchpad/";
		#end

		if (!FileSystem.exists(graphicsPath))
			Context.error("ERROR: Directory '" + graphicsPath + "' not found but it's required.", Context.currentPos());

		var files:Array<String> = FileSystem.readDirectory(graphicsPath);
		var graphics:Array<String> = [];

		for (file in files)
		{
			var ext = file.split('.').pop();
			if (IMAGE_EXTS.indexOf(ext) != -1)
			{
				graphics.push(file.split('.')[0]);
			}
		}

		return graphics;
	}

	private static function formatGraphicToButtonName(name:String):String
	{
		name = name.toLowerCase();
		name = name.charAt(0).toUpperCase() + name.substr(1);
		return 'button$name';
	}
}
#end
