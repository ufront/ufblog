package ufblog.tags;

import ufront.MVC;
using CleverSort;
using tink.CoreApi;
using Lambda;

class BlogTagApi extends UFApi {
	public function getAllTags():Array<BlogTag> {
		var tags = Lambda.array( BlogTag.manager.all() );
		tags.cleverSort( _.name );
		return tags;
	}

	public function getTagByName( name:String ):BlogTag {
		var tag = BlogTag.manager.select( $name==name );
		if ( tag==null )
			throw HttpError.pageNotFound();
		return tag;
	}

	public function saveTag( tag:BlogTag ):Void {
		auth.requirePermission( BlogPermissions.ManageTags );
		tag.save();
	}

	public function deleteTag( tagName:String ):Void {
		auth.requirePermission( BlogPermissions.ManageTags );
		var tag = getTagByName( tagName );
		tag.posts.refreshList();
		tag.posts.clear();
		tag.delete();
	}
}
class BlogTagApiAsync extends UFAsyncApi<BlogTagApi> {}
