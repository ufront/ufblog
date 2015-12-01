package ufblog.posts;

import ufront.MVC;
import ufblog.posts.AttachmentApi;
import ufblog.posts.BlogPostApi;
import ufblog.tags.BlogTag;
import ufblog.tags.BlogTagApi;
import tink.CoreApi;
using ufront.web.result.AddClientActionResult;
using ObjectInit;
using StringTools;

@viewFolder("blog")
class BlogPostController extends Controller {

	@inject public var blogApi:BlogPostApiAsync;
	@inject public var blogTagApi:BlogTagApiAsync;
	@inject public var attachmentApi:AttachmentApi;

	@:route("/new/")
	public function newPost():FutureActionOutcome {
		return showForm( new BlogPost() );
	}

	@:route(GET,"/$postSlug/edit/")
	public function editPost( postSlug:String ):FutureActionOutcome {
		return showForm( blogApi.getPostBySlug(postSlug) );
	}

	@:route(POST,"/save/")
	public function submitEditPost( args:{
		?id:Null<Int>,
		title:String,
		url:String,
		?created:Date,
		?modified:Date,
		?publishDate:Date,
		?authorID:Int,
		content:String,
		introduction:String,
		?headerImage:String,
		?tags:Array<String>,
		publish:Bool
	} ):FutureActionOutcome {
		var post = new BlogPost().init({
			id: args.id,
			created: args.created,
			modified: args.modified,
			authorID: args.authorID,
			content: args.content,
			title: args.title.trim(),
			url: args.url.trim(),
			introduction: args.introduction,
			headerImage: args.headerImage,
			publishDate:
				if ( args.publish==false ) null
				else if ( args.publishDate!=null ) args.publishDate
				else Date.now(),
			authorID: -1 // We need a non-null value for it to pass validation.
		});
		if ( post.validate() ) {
			return blogApi.updatePost( post, args.tags ) >> redirectToPost;
		}
		else {
			return showForm( post );
		}
	}

	@:route(GET,"/$postSlug/delete/")
	public function deletePost( postSlug:String ) {
		return blogApi.deletePostBySlug( postSlug ) >> function(post:BlogPost) {
			ufLog( 'Deleted BlogPost#${post.id}: ${post.title} [${post.url}]');
			return new RedirectResult( this.baseUri );
		};
	}

	@:route("/p/$postID")
	public function permalink( postID:Int ) {
		return blogApi.getPostByID( postID ) >> redirectToPost;
	}

	@:route("/$postSlug")
	public function viewPost( postSlug:String ) {
		var pvr = new PartialViewResult( {}, "post.erazor" );
		pvr.setVars( BlogUtil.addPermissionValues(context) );
		pvr.addPartial( 'postMeta', '/blog/postMeta.erazor' );
		return blogApi.getPostBySlug( postSlug ) >> function(post:BlogPost):ActionResult {
			return pvr.setVars({
				title: post.title,
				description: post.introduction,
				post: post
			});
		}
	}

	#if server
		@:route("/$postSlug/files/$filename")
		public function attachments( postSlug:String, filename:String, ?args:{ w:Int, h:Int } ) {
			// TODO: same problem as in `editPost`, for now we need explicit typing.
			var postSurprise:Surprise<BlogPost,Error> = blogApi.getPostBySlug( postSlug );
			return postSurprise >> function (post:BlogPost):DirectFilePathResult {
				var rawPath = context.contentDirectory+'blog-uploads/${post.id}/${filename}';
				var resizedPath = attachmentApi.getResizedImage( rawPath, args.w, args.h );
				return new DirectFilePathResult( resizedPath );
			};
		}
	#end

	function redirectToPost( post:BlogPost ):ActionResult {
		return new RedirectResult( baseUri+post.url );
	}

	function showForm( ?post:BlogPost, ?postSurprise:Surprise<BlogPost,Error> ):FutureActionOutcome {
		if ( postSurprise==null )
			postSurprise = Future.sync( Success(post) );
		var tagSurprise = blogTagApi.getAllTags();
		context.auth.requirePermission( BlogPermissions.WritePost );

		var pvr = new PartialViewResult( {}, "postForm.erazor" );
		pvr.setVars( BlogUtil.addPermissionValues(context) );
		pvr.addClientAction( SetupEditFormAction );

		return postSurprise >> function(post:BlogPost) {
			return tagSurprise >> function(tags:Array<BlogTag>):ActionResult {
				var title = (post.title=="") ? "New Post" : '"${post.title}"';
				return pvr.setVars({
					title: 'Editing $title',
					description: "",
					post: post,
					tags: tags,
				});
			}
		}
	}
}
