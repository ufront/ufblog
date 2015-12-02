package ufblog.tags;

import ufront.MVC;
import ufblog.tags.BlogTagApi;
import tink.CoreApi;
using ObjectInit;

@viewFolder("blog/admin/")
class TagManagementController extends Controller {

	@inject public var blogTagApi:BlogTagApiAsync;

	@:route(GET,"/")
	public function manageTags() {
		PartialViewResult.startLoadingAnimations();
		context.auth.requirePermission( BlogPermissions.ManageTags );
		return blogTagApi.getAllTags() >> function(tags:Array<BlogTag>) {
			return new PartialViewResult({
				title: "Blog Tags",
				description: "Manage the tags used on your blog",
				tags: tags,
			}, "manageTags.erazor").setVars( BlogUtil.addPermissionValues(context) );
		}
	}

	@:route(GET,"/new/")
	public function newTag() {
		PartialViewResult.startLoadingAnimations();
		return showTagForm( new BlogTag().init(
			name="new-tag",
			title="New Tag",
			description="This is your new tag"
		) );
	}

	@:route(GET,"/$name/")
	public function editTag( name:String ) {
		PartialViewResult.startLoadingAnimations();
		return blogTagApi.getTagByName( name ) >> function(tag:BlogTag) {
			return showTagForm( tag );
		}
	}

	@:route(GET,"/$name/delete/")
	public function deleteTag( name:String ) {
		PartialViewResult.startLoadingAnimations();
		return blogTagApi.deleteTag( name ) >> function(n:Noise) {
			return new RedirectResult( baseUri );
		}
	}

	@:route(POST,"/save/")
	public function saveTag( args:{ ?id:Null<Int>, name:String, title:String, description:String } ) {
		PartialViewResult.startLoadingAnimations();
		var tag = new BlogTag().init( id=args.id, name=args.name, title=args.title, description=args.description );
		return blogTagApi.saveTag( tag ) >> function(n:Noise) {
			return new RedirectResult( baseUri );
		}
	}

	function showTagForm( tag:BlogTag ):ActionResult {
		return new PartialViewResult({
			title: 'Edit ${tag.title} tag [${tag.name}]',
			tag: tag,
		}, "editTag.erazor").setVars( BlogUtil.addPermissionValues(context) );
	}
}
