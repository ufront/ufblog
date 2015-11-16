package ufblog.posts;

import ufront.ORM;
import ufblog.members.BlogMember;
import ufblog.tags.BlogTag;
import sys.db.Types;
using StringTools;

@:index(url,unique)
class BlogPost extends Object {
	/** The URL-safe name of the blog post. Use `setTitle()` to set both `url` and `title` simultaneously. **/
	@:validate( ~/^[a-zA-Z0-9\-]+$/.match(_), 'URL must contain only numbers, letters and hyphens' )
	public var url:SString<255> = "";

	/** The title of the blog post. Short so we can tweet it. Use `setTitle()` to set both `url` and `title` simultaneously. **/
	public var title:SString<120> = "";

	/** The file name of the header image. It should be saved in the same folder as other attachments. **/
	public var headerImage:Null<SString<255>> = null;

	/** A short description / introduction to the post, as markdown.  If used this will appear in the post list, rather than the full post. **/
	public var introduction:Null<SString<255>> = "";

	/** The date this should be published. Null if it's a draft. If the date is in the future, it will not appear yet. **/
	public var publishDate:Null<Date>;

	/** The person who wrote this post. **/
	public var author:BelongsTo<BlogMember>;

	/** The post, as markdown. **/
	public var content:SText = "";

	/** All the tags that apply to this post. **/
	public var tags:ManyToMany<BlogPost,BlogTag>;

	/** Get the post content as HTML (rather than Markdown). **/
	public function getContentHTML( postURL:String ):String {
		var md = content.replace( '(~/', '($postURL/files/' );
		return Markdown.markdownToHtml( md );
	}

	/** Get the header image URL based on the postURL and the headerImage filename. **/
	public function getHeaderURL( postURL:String ):String {
		return '$postURL/files/${headerImage.urlEncode()}';
	}

	public static function urlFromTitle( title:String ):String {
		var url = StringTools.trim( title );
		url = url.toLowerCase();
		url = ~/(\s)/g.replace( url, "-" );
		url = ~/([^a-zA-Z0-9\-])/g.replace( url, "" );
		return url;
	}
}
