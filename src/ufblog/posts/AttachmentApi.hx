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

	/**
		The env var, BLOG_S3BUCKET, is used to define the bucket to be used.
		If the env var is not defined, no sync will be performed.
	**/
	public function uploadToS3(localPath:String, s3Path:String):Void {
		return switch (Sys.getEnv("BLOG_S3BUCKET")) {
			case null:
				//pass
			case bucket:
				var localPath = sys.FileSystem.absolutePath(localPath);
				if (Sys.command("aws", ["s3", "cp", localPath, 's3://${bucket}/${s3Path}']) != 0) {
					throw 'failed to upload ${localPath} to s3://${bucket}/${s3Path}';
				}
		}
	}

	/**
		The env var, BLOG_S3BUCKET, is used to define the bucket to be used.
		If the env var is not defined, no sync will be performed.
	**/
	public function downloadFromS3(s3Path:String, localPath:String):Void {
		return switch (Sys.getEnv("BLOG_S3BUCKET")) {
			case null:
				//pass
			case bucket:
				var localPath = sys.FileSystem.absolutePath(localPath);
				if (Sys.command("aws", ["s3", "cp", 's3://${bucket}/${s3Path}', localPath]) != 0) {
					throw 'failed to download s3://${bucket}/${s3Path} to ${localPath}';
				}
		}
	}

	public function uploadImage( postID:DatabaseID<BlogPost>, upload:UFFileUpload ):Surprise<String,Error> {
		auth.requirePermission( BlogPermissions.WritePost );
		var post = BlogPost.manager.get( postID );
		if ( post==null )
			throw HttpError.pageNotFound();
		var dir = 'blog-uploads/${postID}';
		var absDir = contentDir + dir;
		if ( FileSystem.exists(absDir)==false )
			FileSystem.createDirectory( absDir );
		var path = dir+"/"+upload.originalFileName;
		var absPath = contentDir + path;
		return upload.writeToFile( absPath ) >> function (n:Noise):String {
			uploadToS3(absPath, path);
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
