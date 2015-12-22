package ufblog.posts;

import ufront.MVC;
import tink.CoreApi;
#if client
	import js.Lib.nativeThis as jsThis;
	import js.html.*;
	import js.Browser.*;
#end

class LoadCommentsAction extends UFClientAction<{ id:Int, uri:String }> {

	var scriptID = 'disqus-script';
	var disqusShortName:Null<String>;

	@inject("disqusShortName")
	public function new( ?disqusShortName:String ) {
		this.disqusShortName = disqusShortName;
	}

	override public function execute( httpContext:HttpContext, ?data:{ id:Int, uri:String } ):Void {
		if ( disqusShortName!=null ) {
			var protocol = window.location.protocol;
			var url = protocol + "//" + httpContext.request.hostName + data.uri;

			if ( document.getElementById(scriptID)!=null )
				disqusReload( url, ""+data.id );
			else
				disqusSetup( url, ""+data.id );
		}
	}

	function disqusSetup( url:String, id:String ):Void {
		if ( disqusShortName!=null ) {
			var win:Dynamic = window;
			win.disqus_shortname = disqusShortName;
			win.disqus_config = function () {
				jsThis.page.identifier = id;
				jsThis.page.url = url;
			};
			(function() {
				var s = document.createScriptElement();
				s.id = scriptID;
				s.src = '//${disqusShortName}.disqus.com/embed.js';
				s.setAttribute( 'data-timestamp', ""+Date.now() );
				document.body.appendChild( s );
			})();
		}
	}

	function disqusReload( url:String, id:String ):Void {
		var win:Dynamic = window;
		win.DISQUS.reset({
			reload: true,
			config: function () {
				jsThis.page.identifier = id;
				jsThis.page.url = url;
			}
		});
	}
}
