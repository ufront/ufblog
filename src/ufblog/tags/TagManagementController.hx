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
		return blogTagApi.getAllTags() >> function(tags:Array<BlogTag>) {
			return new PartialViewResult({
				title: "Blog Tags",
				description: "Manage the tags used on your blog",
				tags: tags,
			}, "manageTags").setVars( BlogUtil.addPermissionValues(context) );
		}
	}

	@:route(GET,"/new/")
	public function newTag() {
		return showTagForm( new BlogTag().init(
			name="new-tag",
			title="New Tag",
			description="This is your new tag"
		) );
	}

	@:route(GET,"/$name/")
	public function editTag( name:String ) {
		return blogTagApi.getTagByName( name ) >> function(tag:BlogTag) {
			return showTagForm( tag );
		}
	}

	@:route(GET,"/$name/delete/")
	public function deleteTag( name:String ) {
		return blogTagApi.deleteTag( name ) >> function(n:Noise) {
			return new RedirectResult( baseUri );
		}
	}

	@:route(POST,"/save/")
	public function saveTag( args:{ ?id:Null<Int>, name:String, title:String, description:String } ) {
		var tag = new BlogTag().init( id=args.id, name=args.name, title=args.title, description=args.description );
		return blogTagApi.saveTag( tag ) >> function(n:Noise) {
			return new RedirectResult( baseUri );
		}
	}

	function showTagForm( tag:BlogTag ):ActionResult {
		return new PartialViewResult({
			title: 'Edit ${tag.title} tag [${tag.name}]',
			tag: tag,
		}, "editTag").setVars( BlogUtil.addPermissionValues(context) );
	}
}
