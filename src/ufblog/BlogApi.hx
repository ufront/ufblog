package ufblog;

import ufblog.BlogModels;
import ufront.MVC;
import ufront.db.DatabaseID;
import tink.CoreApi;
import ufront.auth.model.User;
using CleverSort;
using tink.CoreApi;
using Lambda;

class BlogApi extends UFApi {

	@inject public var memberApi:BlogMemberApi;

	public function getAllPosts( limit:PostLimit ):Array<BlogPost> {
		return BlogPost.manager.search(
			$publishDate!=null && $publishDate<Date.now(),
			{
				orderBy:[-publishDate],
				limit:[limit.pos,limit.length]
			},
			false
		).array();
	}

	public function getTag( tagName:String, limit:PostLimit ):PostListResultFor<BlogTag> {
		var tag = BlogTag.manager.select( $name==tagName );
		if ( tag!=null ) {
			// TODO: Once Ufront-ORM has a more advanced manager, do this in the SQL query rather than using arrays.
			var now = Date.now().getTime();
			var tagPosts = [for (p in tag.posts) if (p.publishDate!=null && p.publishDate.getTime()<now) p];
			tagPosts.cleverSort( -_.publishDate.getTime() );
			tagPosts = tagPosts.splice( limit.pos, limit.length );
			return Success( new Pair(tag,tagPosts) );
		}
		else return Failure( HttpError.pageNotFound() );
	}

	public function getMember( name:String, limit:PostLimit ):PostListResultFor<BlogMember> {
		var user = User.manager.select( $username==name );
		var posts = null;
		if (user!=null) {
			var member = BlogMember.manager.select( $userID==user.id );
			if (member!=null) {
				posts = BlogPost.manager.search(
					$publishDate!=null && $publishDate<Date.now() && $authorID==member.id,
					{
						orderBy:[-publishDate],
						limit:[limit.pos,limit.length]
					},
					false
				).array();
				return Success( new Pair(member,posts) );
			}
		}
		return Failure( HttpError.pageNotFound() );
	}

	public function getPostByID( id:Int ):Outcome<BlogPost,Error> {
		var post =
			if ( auth.hasPermission(BlogPermissions.ViewDraftPosts) ) BlogPost.manager.get( id );
			else BlogPost.manager.select( $id==id && $publishDate!=null && $publishDate<Date.now() );
		return outcomeOf( post );
	}

	public function getPostBySlug( slug:String ):Outcome<BlogPost,Error> {
		var post =
			if ( auth.hasPermission(BlogPermissions.ViewDraftPosts) ) BlogPost.manager.select( $url==slug );
			else BlogPost.manager.select( $url==slug && $publishDate!=null && $publishDate<Date.now() );
		return outcomeOf( post );
	}

	public function updatePost( post:BlogPost, tagNames:Array<String> ):Outcome<BlogPost,Error> {
		try {
			// Set the author as the current user.
			var currentMember = memberApi.getCurrentMember().sure();
			if ( post.authorID==null || post.authorID<0 )
				post.author = currentMember;
			// Check they have the right set of permissions.
			auth.requirePermission( BlogPermissions.WritePost );
			if ( post.publishDate!=null )
				auth.requirePermission( BlogPermissions.PublishPost );
			if ( post.authorID!=currentMember.id )
				auth.requirePermission( BlogPermissions.EditAnyPost );
			// Save the post and set the tags.
			post.save();
			var tags = BlogTag.manager.search( $name in tagNames );
			post.tags.setList( tags );
			return Success( post );
		}
		catch (e:Dynamic) return Failure( HttpError.wrap(e, "Failed to save blog post"+e) );
	}

	public function deletePostBySlug( slug:String ):Outcome<BlogPost,Error> {
		return getPostBySlug( slug ).flatMap(function(p:BlogPost):Outcome<BlogPost,Error> {
			try {
				var currentMember = memberApi.getCurrentMember().sure();
				if ( p.authorID!=currentMember.id )
					auth.requirePermission( BlogPermissions.EditAnyPost );
				p.delete();
				return Success(p);
			}
			catch (e:Dynamic) return Failure( HttpError.wrap(e, "Failed to delete blog post") );
		});
	}

	/** TODO: Consider adding this as a helper in ufront.core or HttpError somewhere. **/
	static function outcomeOf<T>( val:Null<T>, ?pos ):Outcome<T,Error> {
		return ( val!=null ) ? Success( val ) : Failure( HttpError.pageNotFound(pos) );
	}
}

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

class BlogApiAsync extends UFAsyncApi<BlogApi> {}
class BlogMemberApiAsync extends UFAsyncApi<BlogMemberApi> {}

/**
If limiting the number of posts, start at `pos` and get `length` posts.
**/
typedef PostLimit = {
	var pos:Int;
	var length:Int;
}
