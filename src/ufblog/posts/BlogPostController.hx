package ufblog.posts;

import ufront.MVC;
import ufblog.posts.AttachmentApi;
import ufblog.posts.BlogPostApi;
import ufblog.tags.BlogTag;
import ufblog.tags.BlogTagApi;
import ufblog.BlogUtil;
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
		PartialViewResult.startLoadingAnimations();
		return showForm( new BlogPost() );
	}

	@:route(GET,"/$postSlug/edit/")
	public function editPost( postSlug:String ):FutureActionOutcome {
		PartialViewResult.startLoadingAnimations();
		var post:Surprise<BlogPost,Error> =  blogApi.getPostBySlug( postSlug );
		// `getPostBySlug` returns a `Surprise<BlogPost,TypedError<...>>`
		// Because TypedError is invariant with Error when used in a Surprise, the overload does transformation 3.v not 3.i (from the docs)
		// Then we get `Surprise<Outcome<ActionResult,TypedError>,Error>` instead of `Surprise<ActionResult,Error>`.
		// TODO: See if we can improve this. Either in tink or in ufront.
		return post >> showForm;
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
		PartialViewResult.startLoadingAnimations();
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
		PartialViewResult.startLoadingAnimations();
		return blogApi.deletePostBySlug( postSlug ) >> function(post:BlogPost) {
			ufLog( 'Deleted BlogPost#${post.id}: ${post.title} [${post.url}]');
			return new RedirectResult( this.baseUri );
		};
	}

	@:route("/p/$postID")
	public function permalink( postID:Int ) {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getPostByID( postID ) >> redirectToPost;
	}

	@:route("/$postSlug")
	public function viewPost( postSlug:String ) {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getPostBySlug( postSlug ) >> showPost;
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
		PartialViewResult.startLoadingAnimations();
		return new RedirectResult( baseUri+post.url );
	}

	function showPost( post:BlogPost ):ActionResult {
		var uri = context.generateUri( baseUri+post.url );
		var result = new PartialViewResult({
			title: post.title,
			description: post.introduction,
			post: post
		}, "post.erazor" )
		.setVars( BlogUtil.addPermissionValues(context) )
		.addPartial( 'postMeta', '/blog/postMeta.erazor' )
		.addClientAction( LoadCommentsAction, { id:post.id, uri:uri } )
		.addClientAction( HighlightSyntaxAction, {} );
		return BlogUtil.addCommentCountScript( result, context );
	}

	function showForm( post:BlogPost ):FutureActionOutcome {
		context.auth.requirePermission( BlogPermissions.WritePost );
		return blogTagApi.getAllTags() >> function( tags:Array<BlogTag> ):ActionResult {
			var title = (post.title=="") ? "New Post" : '"${post.title}"';
			return new PartialViewResult({
				title: 'Editing $title',
				description: "",
				post: post,
				tags: tags,
			}, "postForm.erazor" )
			.setVars( BlogUtil.addPermissionValues(context) )
			.addClientAction( SetupEditFormAction );
		}
	}
}
