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
			return BlogUtil.showPostList( 'Haxe Blog', 'Haxe Blog - Page $page.', posts, context );
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
			return BlogUtil.showPostList( 'Haxe Blog - ${tag.title} - Page $page', tag.description, posts, context );
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
			return BlogUtil.showPostList( 'Haxe Blog - ${member.name} - Page $page', member.name, posts, context );
		};
	}

	@:route("/accounts/*") public var accountController:AccountController;
	@:route("/blog-admin/*") public var blogManagementController:BlogManagementController;
	@:route("/*") public var blogPostController:BlogPostController;
}

@viewFolder("blog")
class BlogPostController extends Controller {

	@inject public var blogApi:BlogApiAsync;

	@:route("/new/")
	public function newPost() {
		return BlogUtil.showForm( new BlogPost() );
	}

	@:route(GET,"/$postSlug/edit/")
	public function editPost( postSlug:String ) {
		return blogApi.getPostBySlug( postSlug ) >> BlogUtil.showForm;
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
			return blogApi.updatePost( post, args.tags ) >> BlogUtil.showPost;
		}
		else {
			return Future.sync( Success(BlogUtil.showForm(post)) );
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
		return blogApi.getPostBySlug( postSlug ) >> BlogUtil.showPost;
	}
}

@viewFolder("blog/admin/")
class BlogManagementController extends Controller {

	@inject public var blogApi:BlogApiAsync;

	@:route(GET,"/")
	public function managePosts() {
		return blogApi.getAllPosts() >> function(posts:Array<BlogPost>) {

			return BlogUtil.showPostTable( 'Haxe Blog', 'Manage posts', posts, context );
		};
	}

	@:route(GET,"/users/")
	public function manageUsers() {
		return "Manage some users";
	}

	@:route(GET,"/tags/")
	public function manageTags() {
		return "Manage some tags";
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

class BlogUtil {

	static function postList( title:String, description:String, posts:Array<BlogPost>, context:HttpContext, view:String ):PartialViewResult {
		return new PartialViewResult({
			title: title,
			description: description,
			posts: posts,
			canPostNew: context.auth.hasPermission( BlogPermissions.WritePost ),
			canViewDrafts: context.auth.hasPermission( BlogPermissions.ViewDraftPosts ),
			canViewUserList: context.auth.hasPermission( BlogPermissions.ViewUserList ),
			canManageTags: context.auth.hasPermission( BlogPermissions.ViewUserList ),
		}, view);
	}

	public static function showPostList( title:String, description:String, posts:Array<BlogPost>, context:HttpContext ):ActionResult {
		return postList( title, description, posts, context, "list" );
	}

	public static function showPostTable( title:String, description:String, posts:Array<BlogPost>, context:HttpContext ):ActionResult {
		var p = posts[0];
		return postList( title, description, posts, context, "managePosts" );
	}

	public static function showPost( post:BlogPost ):ActionResult {
		return new PartialViewResult({
			title: post.title,
			description: post.introduction,
			post: post
		}, "post" );
	}

	public static function showForm( post:BlogPost ):ActionResult {
		var title = (post.title=="") ? "New Post" : '"${post.title}"';
		return new PartialViewResult({
			title: 'Editing $title',
			description: "",
			post: post
		}, "postForm" ).addClientAction( SetupEditForm );
	}

	public static function getLimit( page:Int ):PostLimit {
		var postsPerPage = 20;
		var start = (page-1) * 20;
		return { pos:start, length: postsPerPage };
	}
}
