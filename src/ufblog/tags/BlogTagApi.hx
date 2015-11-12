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

	public function getTagByName( name:String ):Outcome<BlogTag,Error> {
		var tag = BlogTag.manager.select( $name==name );
		return BlogUtil.outcomeOf( tag );
	}

	public function saveTag( tag:BlogTag ):Void {
		tag.save();
	}

	public function deleteTag( tagName:String ):Void {
		var tag = getTagByName( tagName ).sure();
		tag.posts.refreshList();
		tag.posts.clear();
		tag.delete();
	}
}
class BlogTagApiAsync extends UFAsyncApi<BlogTagApi> {}
