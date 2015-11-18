package ufblog;

import ufront.MVC;
import ufblog.BlogPermissions;
import tink.CoreApi;
using DateTools;

class BlogUtil {

	public static function addPermissionValues( context:HttpContext ):TemplateData return {
		canPostNew: context.auth.hasPermission( BlogPermissions.WritePost ),
		canViewDrafts: context.auth.hasPermission( BlogPermissions.ViewDraftPosts ),
		canViewUserList: context.auth.hasPermission( BlogPermissions.ViewUserList ),
		canManageTags: context.auth.hasPermission( BlogPermissions.ViewUserList ),
	}

	public static function outcomeOf<T>( val:Null<T>, ?pos ):Outcome<T,Error> {
		return ( val!=null ) ? Success( val ) : Failure( HttpError.pageNotFound(pos) );
	}

	public static function dateString( d:Date ) return (d!=null) ? d.format("%Y-%m-%d") : "";
	public static function dateTimeString( d:Date ) return (d!=null) ? d.format("%Y-%m-%d %H:%M:%S") : "";
}
