package ufblog.members;

import ufront.MVC;
import ufront.EasyAuth;
import tink.CoreApi;

class BlogMemberApi extends UFApi {
	#if server
		// TODO: make sure EasyAuth can at least exist on the client so I don't need this conditional compilation.
		@inject public var easyAuth:ufront.auth.EasyAuth;
	#end

	public function createUser( member:BlogMember, username:String, password:String ):Outcome<BlogMember,Error> {
		try {
			var u = new User( username, password );
			u.save();
			member.user = u;
			member.save();
			return Success( member );
		}
		catch ( e:Dynamic ) return Failure( HttpError.wrap(e, "Failed to create new blog member") );
	}

	public function getCurrentMember():Outcome<BlogMember,Error> {
		if ( easyAuth.isLoggedIn() ) {
			var u = easyAuth.getCurrentUser();
			var member = BlogMember.manager.select( $userID==u.id );
			return
				if ( member==null) Failure( new Error(404,'No BlogMember matching current user $u') )
				else Success( member );
		}
		else return Failure( HttpError.authError(ANotLoggedIn) );

	}
}
class BlogMemberApiAsync extends UFAsyncApi<BlogMemberApi> {}
