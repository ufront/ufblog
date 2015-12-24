package ufblog;

import ufront.MVC;
import ufblog.BlogPermissions;
import ufblog.members.BlogMember;
import ufblog.posts.BlogPost;
import tink.CoreApi;
import haxe.crypto.Md5;
using ufront.web.result.CallJavascriptResult;
using StringTools;
using DateTools;

class BlogUtil {

	public static function addPermissionValues( context:HttpContext ):TemplateData return {
		isLoggedIn: context.auth.isLoggedIn(),
		canPostNew: context.auth.hasPermission( BlogPermissions.WritePost ),
		canViewDrafts: context.auth.hasPermission( BlogPermissions.ViewDraftPosts ),
		canViewUserList: context.auth.hasPermission( BlogPermissions.ViewUserList ),
		canManageTags: context.auth.hasPermission( BlogPermissions.ViewUserList ),
		username: context.currentUserID
	}

	public static function addCommentCountScript( result:ActionResult, context:HttpContext ):ActionResult {
		if ( context.injector.hasMapping(String,"disqusShortName") ) {
			var disqusShortName = context.injector.getValue( String, "disqusShortName" );
			var disqusCountScript = '//${disqusShortName}.disqus.com/count.js';
			result = result.addInlineJsToResult( 'window.DISQUSWIDGETS = undefined; window.disqus_shortname = "$disqusShortName";' );
			result = result.addJsScriptToResult( disqusCountScript );
		}
		return result;
	}

	public static function dateString( d:Date ) return (d!=null) ? d.format("%Y-%m-%d") : "";

	public static function dateTimeString( d:Date ) return (d!=null) ? d.format("%Y-%m-%d %H:%M:%S") : "";

	public static function gravatar( m:BlogMember, size:Int, cssClass:String ) {
		if (m!=null) {
			var hash = Md5.encode( m.email.toLowerCase().trim() );
			var url = 'http://www.gravatar.com/avatar/$hash?s=$size&d=retro';
			return '<img src="$url" class="$cssClass" alt="Avatar for $m" width="$2size" height="$2size" title="${m.name}" />';
		}
		else return "";
	}

	public static function hnLink( context:HttpContext, p:BlogPost ):String {
		var blogUri = context.injector.getValue( String, "blogUri" );
		var uri = context.generateUri(blogUri + p.url);
		var url = 'http://'+context.request.hostName+uri;
		var encodedUrl = url.urlEncode();
		var title = p.title.urlEncode();
		return 'https://news.ycombinator.com/submitlink?u=${encodedUrl}&t=${title}';
	}
}
