package ufblog.posts;

import ufblog.posts.BlogPostApi;
import ufblog.tags.BlogTag;
import ufblog.members.BlogMember;
import ufront.MVC;
import tink.CoreApi;

@viewFolder("blog")
class BlogListController extends Controller {

	@inject public var blogApi:BlogPostApiAsync;

	@:route("/")
	public function index() {
		return allPosts( 1 );
	}

	@:route("/page/$page/")
	public function allPosts( page:Int ) {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getPostList( getLimit(page) ) >> function(posts:Array<BlogPost>) {
			var page = (page!=1) ? ' - Page $page' : '';
			return showPostList( 'Haxe Blog', 'Haxe Blog$page', posts );
		};
	}

	// Posts by author

	@:route("/tag/$tagName")
	public function tagIndex( tagName:String ) {
		return tag( tagName, 1 );
	}

	@:route("/tag/$tagName/page/$page/")
	public function tag( tagName:String, page:Int ) {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getTag( tagName, getLimit(page) ) >> function(pair:Pair<BlogTag,Array<BlogPost>>) {
			var tag = pair.a;
			var posts = pair.b;
			var page = (page!=1) ? ' - Page $page' : '';
			return showPostList( 'Haxe Blog - ${tag.title}$page', tag.description, posts );
		};
	}

	// Posts by tag

	@:route("/author/$tagName")
	public function authorIndex( tagName:String ) {
		return author( tagName, 1 );
	}

	@:route("/author/$authorName/page/$page/")
	public function author( authorName:String, page:Int ) {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getMember( authorName, getLimit(page) ) >> function(pair:Pair<BlogMember,Array<BlogPost>>) {
			var member = pair.a;
			var posts = pair.b;
			var page = (page!=1) ? ' - Page $page' : '';
			return showPostList( 'Haxe Blog - ${member.name}$page', member.name, posts );
		};
	}

	@:route("/*") public var blogPostController:BlogPostController;

	function showPostList( title:String, description:String, posts:Array<BlogPost> ):ActionResult {
		return new PartialViewResult({
			title: title,
			description: description,
			posts: posts,
		}, "list.erazor")
		.setVars( BlogUtil.addPermissionValues(context) )
		.addPartial( 'postMeta', '/blog/postMeta.erazor' );
	}

	function getLimit( page:Int ):PostLimit {
		var postsPerPage = 20;
		var start = (page-1) * 20;
		return { pos:start, length: postsPerPage };
	}
}
