package ufblog.posts;

import ufront.MVC;
import ufront.ORM;
#if server
	import sys.FileSystem;
#end
using tink.CoreApi;
using StringTools;

class AttachmentApi extends UFApi {
	@inject("contentDirectory") public var contentDir:String;

	public function uploadImage( postID:DatabaseID<BlogPost>, upload:UFFileUpload ):Surprise<String,Error> {
		var post = BlogPost.manager.get( postID );
		if ( post==null )
			throw HttpError.pageNotFound();
		var dir = contentDir+'blog-uploads/${postID}';
		if ( FileSystem.exists(dir)==false )
			FileSystem.createDirectory( dir );
		var path = dir+"/"+upload.originalFileName;
		return upload.writeToFile( path ) >> function (n:Noise):String {
			return '~/${upload.originalFileName.urlEncode()}';
		}
	}

	public function uploadHeaderImage( postID:DatabaseID<BlogPost>, upload:UFFileUpload ):Surprise<String,Error> {
		var result = uploadImage( postID, upload );
		var post = BlogPost.manager.get( postID );
		post.headerImage = upload.originalFileName;
		post.save();
		return result;
	}
}
class AttachmentApiAsync extends UFAsyncApi<AttachmentApi> {}
