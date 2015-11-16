package ufblog.posts;

import ufront.MVC;
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

	@:route("/new/")
	public function newPost():FutureActionOutcome {
		return showForm( new BlogPost() );
	}

	@:route(GET,"/$postSlug/edit/")
	public function editPost( postSlug:String ):FutureActionOutcome {
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
		return blogApi.getPostBySlug( postSlug ) >> showPost;
	}

	@:route("/$postSlug/files/$filename")
	public function attachments( postSlug:String, filename:String ) {
		return blogApi.getPostBySlug( postSlug ) >> function (post:BlogPost) {
			var path = context.contentDirectory+'blog-uploads/${post.id}/${filename}';
			return new DirectFilePathResult( path );
		};
	}

	function redirectToPost( post:BlogPost ):ActionResult {
		return new RedirectResult( baseUri+post.url );
	}

	function showPost( post:BlogPost ):ActionResult {
		return new PartialViewResult({
			title: post.title,
			description: post.introduction,
			post: post
		}, "post" );
	}

	function showForm( post:BlogPost ):FutureActionOutcome {
		return blogTagApi.getAllTags() >> function( tags:Array<BlogTag> ):ActionResult {
			var title = (post.title=="") ? "New Post" : '"${post.title}"';
			return new PartialViewResult({
				title: 'Editing $title',
				description: "",
				post: post,
				tags: tags,
			}, "postForm" ).addClientAction( SetupEditFormAction );
		}
	}
}
