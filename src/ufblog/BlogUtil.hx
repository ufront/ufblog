package ufblog;

import ufront.MVC;
import ufblog.BlogPermissions;
import tink.CoreApi;

class BlogUtil {

	public static function addPermissionValues( context:HttpContext ):TemplateData return {
		canPostNew: context.auth.hasPermission( BlogPermissions.WritePost ),
		canViewDrafts: context.auth.hasPermission( BlogPermissions.ViewDraftPosts ),
		canViewUserList: context.auth.hasPermission( BlogPermissions.ViewUserList ),
		canManageTags: context.auth.hasPermission( BlogPermissions.ViewUserList ),
	}

	/** TODO: Consider adding this as a helper in ufront.core or HttpError somewhere. **/
	public static function outcomeOf<T>( val:Null<T>, ?pos ):Outcome<T,Error> {
		return ( val!=null ) ? Success( val ) : Failure( HttpError.pageNotFound(pos) );
	}
}
