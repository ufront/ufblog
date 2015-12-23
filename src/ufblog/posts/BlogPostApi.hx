package ufblog.posts;

import ufblog.tags.*;
import ufblog.members.*;
import ufront.MVC;
import ufront.EasyAuth;
using ufront.db.DBSerializationTools;
using tink.CoreApi;
using CleverSort;

class BlogPostApi extends UFApi {

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
		return [for (p in list) setSerialization(p)];
	}

	public function getAllPosts():Array<BlogPost> {
		auth.requirePermission( BlogPermissions.ViewDraftPosts );
		var list = BlogPost.manager.all();
		var array = [for (p in list) setSerialization(p)];
		array.cleverSort(-_.modified.getTime());
		return array;
	}

	public function getTag( tagName:String, limit:PostLimit ):PostListResultFor<BlogTag> {
		var tag = BlogTag.manager.select( $name==tagName );
		if ( tag==null )
			throw HttpError.pageNotFound();
		// TODO: Once Ufront-ORM has a more advanced manager, do this in the SQL query rather than using arrays.
		var now = Date.now().getTime();
		var tagPosts = [for (p in tag.posts) if (p.publishDate!=null && p.publishDate.getTime()<now) p];
		tagPosts.cleverSort( -_.publishDate.getTime() );
		tagPosts = tagPosts.splice( limit.pos, limit.length );
		tagPosts = tagPosts.map( setSerialization );
		return new Pair( tag, tagPosts );
	}

	public function getMember( name:String, limit:PostLimit ):PostListResultFor<BlogMember> {
		var user = User.manager.select( $username==name );
		if ( user==null )
			throw HttpError.pageNotFound();
		var member = BlogMember.manager.select( $userID==user.id );
		if ( member==null )
			throw HttpError.pageNotFound();
		var postList = BlogPost.manager.search(
			$publishDate!=null && $publishDate<Date.now() && $authorID==member.id,
			{
				orderBy:[-publishDate],
				limit:[limit.pos,limit.length]
			},
			false
		);
		var posts = [for (p in postList) setSerialization(p)];
		return new Pair( member, posts );
	}

	public function getPostByID( id:Int ):BlogPost {
		var post =
			if ( auth.hasPermission(BlogPermissions.ViewDraftPosts) ) BlogPost.manager.get( id );
			else BlogPost.manager.select( $id==id && $publishDate!=null && $publishDate<Date.now() );
		if ( post==null )
			throw HttpError.pageNotFound();
		return setSerialization(post);
	}

	public function getPostBySlug( slug:String ):BlogPost {
		var post =
			if ( auth.hasPermission(BlogPermissions.ViewDraftPosts) ) BlogPost.manager.select( $url==slug );
			else BlogPost.manager.select( $url==slug && $publishDate!=null && $publishDate<Date.now() );
		if ( post==null )
			throw HttpError.pageNotFound();
		return setSerialization( post );
	}

	public function updatePost( post:BlogPost, tagNames:Array<String> ):BlogPost {
		// Set the author as the current user.
		var currentMember = memberApi.getCurrentMember();
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
		return setSerialization( post );
	}

	public function deletePostBySlug( slug:String ):BlogPost {
		var p = getPostBySlug( slug );
		var currentMember = memberApi.getCurrentMember();
		if ( p.authorID!=currentMember.id )
			auth.requirePermission( BlogPermissions.EditAnyPost );
		p.delete();
		return setSerialization( p );
	}

	static function setSerialization( post:BlogPost ):BlogPost {
		return post.with( tags, author=>[user=>[[],id,username]] );
	}
}
class BlogPostApiAsync extends UFAsyncApi<BlogPostApi> {}

/**
A shortcut typedef, that contains an object and it's related `BlogPost` array.

For example: `Pair(tag, postsInTag)` or `Pair(author, postsByAuthor)`.
**/
typedef PostListResultFor<T> = Pair<T,Array<BlogPost>>;
