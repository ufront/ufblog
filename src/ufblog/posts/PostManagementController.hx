package ufblog.posts;

import ufront.MVC;
import ufblog.posts.BlogPostApi;

@viewFolder("blog/admin/")
class PostManagementController extends Controller {

	@inject public var blogApi:BlogPostApiAsync;

	@:route(GET,"/")
	public function managePosts() {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getAllPosts() >> function(posts:Array<BlogPost>) {
			return new PartialViewResult({
				title: 'Haxe Blog',
				description: 'Manage posts',
				posts: posts,
			}, "managePosts.erazor").setVars( BlogUtil.addPermissionValues(context) );
		};
	}
}
