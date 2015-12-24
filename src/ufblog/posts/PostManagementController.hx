package ufblog.posts;

import ufront.MVC;
import ufblog.posts.BlogPostApi;

@viewFolder("blog/admin/")
class PostManagementController extends Controller {

	@inject public var blogApi:BlogPostApiAsync;
	@inject("blogTitle") public var blogTitle:String;

	@:route(GET,"/")
	public function managePosts() {
		PartialViewResult.startLoadingAnimations();
		return blogApi.getAllPosts() >> function(posts:Array<BlogPost>) {
			return new PartialViewResult({
				title: blogTitle,
				description: 'Manage posts',
				posts: posts,
			}, "managePosts.erazor").setVars( BlogUtil.addPermissionValues(context) );
		};
	}
}
