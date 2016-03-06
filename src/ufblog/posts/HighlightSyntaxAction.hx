package ufblog.posts;

import ufront.MVC;
import tink.CoreApi;
#if client
	import js.JQuery.JQueryHelper.*;
	import js.Lib.nativeThis as jsThis;
	import js.html.*;
	import js.Browser.*;
#end

class HighlightSyntaxAction extends UFClientAction<{}> {

	public function new() {
	}

	override public function execute( httpContext:HttpContext, ?data:{} ):Void {
		var kwds = ["abstract", "break", "case", "cast", "class", "continue", "default", "do", "dynamic", "else", "enum", "extends", "extern", "for", "function", "if", "implements", "import", "in", "inline", "interface", "macro", "new", "override", "package", "private", "public", "return", "static", "switch", "throw", "try", "typedef", "untyped", "using", "var", "while" ];
		var kwds = new EReg("\\b(" + kwds.join("|") + ")\\b", "g");

		var vals = ["null", "true", "false", "this"];
		var vals = new EReg("\\b(" + vals.join("|") + ")\\b", "g");

		for( s in J("pre code.prettyprint.haxe") ) {
			var html = s.html();

			// detect and remove identation
			var tabs = null;
			for( line in html.split("\n") )
				if( StringTools.trim(line) != "" ) {
					var r = ~/^\t*/;
					r.match(line);
					var t = r.matched(0);
					if( tabs == null || t.length < tabs.length ) tabs = t;
				}
			html = new EReg("^" + tabs, "gm").replace(html, "");
			html = StringTools.trim(html);

			html = ~/('[^']*')/g.replace(html, "<span __xlass='str'>$1</span>");
			html = kwds.replace(html, "<span class='kwd'>$1</span>");
			html = vals.replace(html, "<span class='val'>$1</span>");

			html = html.split('__xlass').join("class");

			html = ~/("[^"]*")/g.replace(html, "<span class='str'>$1</span>");
			html = ~/(\/\/[^\n]*)/g.replace(html, "<span class='cmt'>$1</span>");
			html = ~/(\/\*\*?[^*]*\*?\*\/)/g.replace(html, "<span class='cmt'>$1</span>");
			html = html.split("\t").join("    ");
			s.html(html);
		}
	}
}
