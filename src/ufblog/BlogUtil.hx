package ufblog;

import ufront.MVC;
import ufblog.BlogPermissions;
import ufblog.members.BlogMember;
import ufblog.posts.BlogPost;
import tink.CoreApi;
import haxe.crypto.Md5;
using StringTools;
using DateTools;

class BlogUtil {

	public static function addPermissionValues( context:HttpContext ):TemplateData return {
		canPostNew: context.auth.hasPermission( BlogPermissions.WritePost ),
		canViewDrafts: context.auth.hasPermission( BlogPermissions.ViewDraftPosts ),
		canViewUserList: context.auth.hasPermission( BlogPermissions.ViewUserList ),
		canManageTags: context.auth.hasPermission( BlogPermissions.ViewUserList ),
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
