package ufblog.posts;

import ufront.MVC;
import ufront.ORM;
#if server
	import sys.FileSystem;
	import haxe.imagemagick.Imagick;
#end
using tink.CoreApi;
using StringTools;
using haxe.io.Path;

class AttachmentApi extends UFApi {
	@inject("contentDirectory") public var contentDir:String;

	public function uploadImage( postID:DatabaseID<BlogPost>, upload:UFFileUpload ):Surprise<String,Error> {
		auth.requirePermission( BlogPermissions.WritePost );
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
		auth.requirePermission( BlogPermissions.WritePost );
		var result = uploadImage( postID, upload );
		var post = BlogPost.manager.get( postID );
		post.headerImage = upload.originalFileName;
		post.save();
		return result;
	}

	/**
	Get the path for a resized version of an image.

	- If the resized image does not exist in the expected `${width}x${height}` subdirectory, then it will be created and the new path returned.
	- If the resized image already exists, the new path to it will be returned.
	- If the path doesn't have the extension `jpg`, `jpeg`, `png`, or `gif` then the original path will be returned.
	**/
	public function getResizedImage( path:String, ?newWidth:Int, ?newHeight:Int ):String {
		if ( ['gif','jpg','jpeg','png'].indexOf(path.extension().toLowerCase())==-1 )
			return path;
		if ( newWidth==null && newHeight==null )
			newWidth = 700; // TODO: make this configurable.
		var ratioName =
			if (newWidth!=null && newHeight!=null) '${newWidth}x${newHeight}'
			else if (newWidth!=null)'${newWidth}xAUTO'
			else 'AUTOx${newHeight}';
		var dir = path.directory().addTrailingSlash() + ratioName;
		var newPath = dir + "/" + path.withoutDirectory();
		if ( FileSystem.exists(newPath)==false || getModTime(path)>getModTime(newPath) ) {
			FileSystem.createDirectory( dir );
			var img = new Imagick( path );
			if ( newHeight==null ) {
				var ratio = img.width / img.height;
				newHeight = Math.round( newWidth/ratio );
			}
			if ( newWidth==null ) {
				var ratio = img.width / img.height;
				newWidth = Math.round( ratio*newHeight );
			}
			if ( newWidth<img.width && newHeight<img.height ) {
				img.resize( newWidth, newHeight );
			}
			img.setCompressionQuality( 75 );
			img.save( newPath );
		}
		return newPath;
	}

	function getModTime( path:String ):Float {
		return FileSystem.stat( path ).mtime.getTime();
	}
}
class AttachmentApiAsync extends UFAsyncApi<AttachmentApi> {}
