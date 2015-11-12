package ufblog;

import ufblog.BlogModels;
import ufront.db.DatabaseID;
import ufront.MVC;
import ufront.EasyAuth;
using CleverSort;
using tink.CoreApi;
using Lambda;

class BlogApi extends UFApi {

	@inject public var memberApi:BlogMemberApi;

	public function getPostList( limit:PostLimit ):Array<BlogPost> {
		var list = BlogPost.manager.search(
			$publishDate!=null && $publishDate<Date.now(),
			{
				orderBy:[-publishDate],
				limit:[limit.pos,limit.length]
			},
			false
		);
		return [for (p in list) includeMemberInSerialization(p)];
	}

	public function getAllPosts():Array<BlogPost> {
		auth.requirePermission( BlogPermissions.ViewDraftPosts );
		var list = BlogPost.manager.all();
		var array = [for (p in list) includeMemberInSerialization(p)];
		array.cleverSort(-_.modified.getTime());
		return array;
	}

	public function getTag( tagName:String, limit:PostLimit ):PostListResultFor<BlogTag> {
		var tag = BlogTag.manager.select( $name==tagName );
		if ( tag!=null ) {
			// TODO: Once Ufront-ORM has a more advanced manager, do this in the SQL query rather than using arrays.
			var now = Date.now().getTime();
			var tagPosts = [for (p in tag.posts) if (p.publishDate!=null && p.publishDate.getTime()<now) p];
			tagPosts.cleverSort( -_.publishDate.getTime() );
			tagPosts = tagPosts.splice( limit.pos, limit.length );
			tagPosts = tagPosts.map( includeMemberInSerialization );
			return Success( new Pair(tag,tagPosts) );
		}
		else return Failure( HttpError.pageNotFound() );
	}

	public function getMember( name:String, limit:PostLimit ):PostListResultFor<BlogMember> {
		var user = User.manager.select( $username==name );
		if (user!=null) {
			var member = BlogMember.manager.select( $userID==user.id );
			if (member!=null) {
				var postList = BlogPost.manager.search(
					$publishDate!=null && $publishDate<Date.now() && $authorID==member.id,
					{
						orderBy:[-publishDate],
						limit:[limit.pos,limit.length]
					},
					false
				);
				var posts = [for (p in postList) includeMemberInSerialization(p)];
				return Success( new Pair(member,posts) );
			}
		}
		return Failure( HttpError.pageNotFound() );
	}

	public function getPostByID( id:Int ):Outcome<BlogPost,Error> {
		var post =
			if ( auth.hasPermission(BlogPermissions.ViewDraftPosts) ) BlogPost.manager.get( id );
			else BlogPost.manager.select( $id==id && $publishDate!=null && $publishDate<Date.now() );
		return BlogUtil.outcomeOf( includeMemberInSerialization(post) );
	}

	public function getPostBySlug( slug:String ):Outcome<BlogPost,Error> {
		var post =
			if ( auth.hasPermission(BlogPermissions.ViewDraftPosts) ) BlogPost.manager.select( $url==slug );
			else BlogPost.manager.select( $url==slug && $publishDate!=null && $publishDate<Date.now() );
		return BlogUtil.outcomeOf( includeMemberInSerialization(post) );
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
			return Success( includeMemberInSerialization(post) );
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
				return Success( includeMemberInSerialization(p) );
			}
			catch (e:Dynamic) return Failure( HttpError.wrap(e, "Failed to delete blog post") );
		});
	}

	static function includeMemberInSerialization( post:BlogPost ):BlogPost {
		function includeField( obj:ufront.db.Object, field:String ) {
			if ( obj.hxSerializationFields.indexOf(field)==-1 )
				obj.hxSerializationFields.push( field );
		}
		if ( post!=null ) {
			includeField( post, "author" );
			includeField( post, "tags" );
			includeField( post.author, "user" );
			post.author.user.hxSerializationFields = ["id","username"];
		}
		return post;
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

class BlogRemotingApiContext extends UFApiContext {
	public var blogApi:BlogApi;
	public var easyAuthApi:ufront.auth.api.EasyAuthApi;
}
