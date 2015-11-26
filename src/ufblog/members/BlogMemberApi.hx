package ufblog.members;

import ufront.MVC;
import ufront.EasyAuth;
import tink.CoreApi;
using CleverSort;

class BlogMemberApi extends UFApi {
	#if server
		// TODO: make sure EasyAuth can at least exist on the client so I don't need this conditional compilation.
		@inject public var easyAuth:ufront.auth.EasyAuth;
		@inject public var easyAuthApi:ufront.auth.api.EasyAuthApi;
	#end

	public function getAllMembers():Array<BlogMember> {
		auth.requirePermission( BlogPermissions.ViewUserList );
		var members = [for(m in BlogMember.manager.all()) setSerialization(m)];
		members.cleverSort( _.user.username );
		return members;
	}

	public function getMemberByUsername( username:String ):BlogMember {
		auth.requirePermission( BlogPermissions.ViewUserList );
		var user = User.manager.select( $username==username );
		if ( user==null )
			throw HttpError.pageNotFound();
		var member = BlogMember.manager.select( $userID==user.id );
		if ( member==null )
			throw HttpError.pageNotFound();
		return setSerialization( member );
	}

	public function createUser( member:BlogMember, username:String, password:String ):BlogMember {
		var u = new User( username, password );
		u.save();
		member.user = u;
		member.save();
		return setSerialization( member );
	}

	public function getCurrentMember():BlogMember {
		if ( easyAuth.isLoggedIn() ) {
			var u = easyAuth.getCurrentUser();
			var member = BlogMember.manager.select( $userID==u.id );
			if ( member==null)
				throw new Error( 404, 'No BlogMember matching current user $u' );
			return setSerialization( member );
		}
		else return throw HttpError.authError(ANotLoggedIn);
	}

	public function updatePermissions( username:String, permissions:Array<EnumValue> ):Void {
		auth.requirePermission( BlogPermissions.ChangePermissions );
		var member = getMemberByUsername( username );
		for ( p in permissions )
			easyAuthApi.assignPermissionToUser( p, member.userID );
	}

	static function setSerialization( m:BlogMember ):BlogMember {
		function includeField( obj:ufront.db.Object, field:String ) {
			if ( obj.hxSerializationFields.indexOf(field)==-1 )
				obj.hxSerializationFields.push( field );
		}
		if ( m!=null ) {
			includeField( m, "user" );
			m.user.hxSerializationFields = ["id","username","allUserPermissions"];
		}
		return m;
	}
}
class BlogMemberApiAsync extends UFAsyncApi<BlogMemberApi> {}
