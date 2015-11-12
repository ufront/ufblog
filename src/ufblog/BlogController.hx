package ufblog;

import ufront.MVC;
import ufblog.BlogApi;
import ufblog.BlogModels;
import ufront.db.DatabaseID;
import ufront.EasyAuth;
import ufblog.actions.*;
#if server
	import ufront.ufadmin.controller.UFAdminHomeController;
#end
using tink.CoreApi;
using Lambda;
using ObjectInit;
using ufront.web.result.AddClientActionResult;

@viewFolder("blog")
class BlogController extends Controller {

	@inject public var blogApi:BlogApiAsync;

	#if server
		@:route("/ufadmin/*") public var ufadmin:UFAdminHomeController;
	#end

	@:route("/")
	public function index() {
		return allPosts( 1 );
	}

	@:route("/page/$page/")
	public function allPosts( page:Int ) {
		return blogApi.getPostList( BlogUtil.getLimit(page) ) >> function(posts:Array<BlogPost>) {
			return showPostList( 'Haxe Blog', 'Haxe Blog - Page $page.', posts );
		};
	}

	// Posts by author

	@:route("/tag/$tagName")
	public function tagIndex( tagName:String ) {
		return tag( tagName, 1 );
	}

	@:route("/tag/$tagName/page/$page/")
	public function tag( tagName:String, page:Int ) {
		return blogApi.getTag( tagName, BlogUtil.getLimit(page) ) >> function(pair:Pair<BlogTag,Array<BlogPost>>) {
			var tag = pair.a;
			var posts = pair.b;
			return showPostList( 'Haxe Blog - ${tag.title} - Page $page', tag.description, posts );
		};
	}

	// Posts by tag

	@:route("/author/$tagName")
	public function authorIndex( tagName:String ) {
		return author( tagName, 1 );
	}

	@:route("/author/$authorName/page/$page/")
	public function author( authorName:String, page:Int ) {
		return blogApi.getMember( authorName, BlogUtil.getLimit(page) ) >> function(pair:Pair<BlogMember,Array<BlogPost>>) {
			var member = pair.a;
			var posts = pair.b;
			return showPostList( 'Haxe Blog - ${member.name} - Page $page', member.name, posts );
		};
	}

	@:route("/accounts/*") public var accountController:AccountController;
	@:route("/blog-admin/*") public var blogManagementController:BlogManagementController;
	@:route("/*") public var blogPostController:BlogPostController;

	function showPostList( title:String, description:String, posts:Array<BlogPost> ):ActionResult {
		return new PartialViewResult({
			title: title,
			description: description,
			posts: posts,
		}, "list").setVars( BlogUtil.addPermissionValues(context) );
	}
}

@viewFolder("blog")
class BlogPostController extends Controller {

	@inject public var blogApi:BlogApiAsync;
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
		?publishDate:Date,
		?authorID:DatabaseID<BlogMember>,
		content:String,
		introduction:String,
		?tags:Array<String>,
		publish:Bool
	} ):FutureActionOutcome {
		var post = new BlogPost().init({
			id: args.id,
			authorID: args.authorID,
			content: args.content,
			introduction: args.introduction,
			publishDate:
				if ( args.publish==false ) null
				else if ( args.publishDate!=null ) args.publishDate
				else Date.now(),
			authorID: -1 // We need a non-null value for it to pass validation.
		});
		post.setTitle( args.title );
		if ( post.validate() ) {
			return blogApi.updatePost( post, args.tags ) >> showPost;
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
		return blogApi.getPostByID( postID ) >> function(post:BlogPost) {
			return new RedirectResult( '/${post.url}/' );
		}
	}

	@:route("/$postSlug")
	public function viewPost( postSlug:String ) {
		return blogApi.getPostBySlug( postSlug ) >> showPost;
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
			trace( tags );
			var title = (post.title=="") ? "New Post" : '"${post.title}"';
			return new PartialViewResult({
				title: 'Editing $title',
				description: "",
				post: post,
				tags: tags,
			}, "postForm" ).addClientAction( SetupEditForm );
		}
	}
}

@viewFolder("blog/admin/")
class BlogManagementController extends Controller {

	@inject public var blogApi:BlogApiAsync;
	@inject public var blogTagApi:BlogTagApiAsync;

	@:route(GET,"/")
	public function managePosts() {
		return blogApi.getAllPosts() >> function(posts:Array<BlogPost>) {
			return new PartialViewResult({
				title: 'Haxe Blog',
				description: 'Manage posts',
				posts: posts,
			}, "managePosts").setVars( BlogUtil.addPermissionValues(context) );
		};
	}

	@:route(GET,"/users/")
	public function manageUsers() {
		return "Manage some users";
	}

	@:route(GET,"/tags/")
	public function manageTags() {
		return blogTagApi.getAllTags() >> function(tags:Array<BlogTag>) {
			return new PartialViewResult({
				title: "Blog Tags",
				description: "Manage the tags used on your blog",
				tags: tags,
			}, "manageTags").setVars( BlogUtil.addPermissionValues(context) );
		}
	}

	@:route(GET,"/tags/new/")
	public function newTag() {
		return showTagForm( new BlogTag().init(
			name="new-tag",
			title="New Tag",
			description="This is your new tag"
		) );
	}

	@:route(GET,"/tags/$name/")
	public function editTag( name:String ) {
		return blogTagApi.getTagByName( name ) >> function(tag:BlogTag) {
			return showTagForm( tag );
		}
	}

	@:route(GET,"/tags/$name/delete/")
	public function deleteTag( name:String ) {
		return blogTagApi.deleteTag( name ) >> function(n:Noise) {
			return new RedirectResult( baseUri+"tags/" );
		}
	}

	@:route(POST,"/tags/save/")
	public function saveTag( args:{ ?id:Null<Int>, name:String, title:String, description:String } ) {
		var tag = new BlogTag().init( id=args.id, name=args.name, title=args.title, description=args.description );
		return blogTagApi.saveTag( tag ) >> function(n:Noise) {
			return new RedirectResult( baseUri+"tags/" );
		}
	}

	function showTagForm( tag:BlogTag ):ActionResult {
		return new PartialViewResult({
			title: 'Edit ${tag.title} tag [${tag.name}]',
			tag: tag,
		}, "editTag").setVars( BlogUtil.addPermissionValues(context) );
	}
}

@viewFolder("blog")
class AccountController extends Controller {

	@inject public var blogMemberApi:BlogMemberApiAsync;
	@inject public var easyAuthApi:EasyAuthApiAsync;

	@:route(GET,"/login")
	public function login() {
		return showLoginForm();
	}

	function showLoginForm( ?existingUser="", ?msg:String ) {
		return new PartialViewResult({
			title: "Login",
			username: existingUser,
			msg: msg,
		}, "login");
	}

	@:route(POST,"/login")
	public function doLogin( args:{ username:String, password:String } ):Surprise<ActionResult,Error> {
		return context.session.init()
			>> function(n:Noise) return easyAuthApi.attemptLogin( args.username, args.password )
			>> function(u:User):ActionResult return new RedirectResult( "/" );
	}

	@:route(GET,"/signup")
	public function signupForm() {
		return new PartialViewResult({
			title: "Sign Up"
		});
	}

	@:route(POST,"/signup")
	public function doSignup( args:{ name:String, email:String, username:String, password1:String, password2:String } ):Surprise<ViewResult,Error> {
		var member = new BlogMember().init({
			email: args.email,
			name: args.name,
		});
		if ( member.validate()==false ) {
			var result = new PartialViewResult( args, "signupForm" ).setVar( "error", "Validation Error: "+member.validationErrors.toString() );
			return Future.sync( Success(result) );
		}
		else if ( args.password1!=args.password2 ) {
			var result = new PartialViewResult( args, "signupForm" ).setVar( "error", "Passwords did not match" );
			return Future.sync( Success(result) );
		}
		else return blogMemberApi.createUser( member, args.username, args.password1 ) >> function(member:BlogMember):ViewResult {
			return new PartialViewResult( { member:member }, "signupSuccess" );
		}
	}
}
