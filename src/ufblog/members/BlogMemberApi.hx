package ufblog.members;

import ufront.MVC;
import ufront.EasyAuth;
import tink.CoreApi;
using CleverSort;

class BlogMemberApi extends UFApi {
	#if server
		// TODO: make sure EasyAuth can at least exist on the client so I don't need this conditional compilation.
		@inject public var easyAuth:ufront.auth.EasyAuth;
	#end

	public function getAllMembers():Array<BlogMember> {
		var tags = Lambda.array( BlogMember.manager.all() );
		tags.cleverSort( _.user.username );
		return tags;
	}

	public function createUser( member:BlogMember, username:String, password:String ):BlogMember {
		var u = new User( username, password );
		u.save();
		member.user = u;
		member.save();
		return member;
	}

	public function getCurrentMember():BlogMember {
		if ( easyAuth.isLoggedIn() ) {
			var u = easyAuth.getCurrentUser();
			var member = BlogMember.manager.select( $userID==u.id );
			if ( member==null)
				throw new Error( 404, 'No BlogMember matching current user $u' );
			return member;
		}
		else return throw HttpError.authError(ANotLoggedIn);
	}
}
class BlogMemberApiAsync extends UFAsyncApi<BlogMemberApi> {}
