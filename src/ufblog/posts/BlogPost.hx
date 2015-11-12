package ufblog.posts;

import ufront.ORM;
import ufblog.members.BlogMember;
import ufblog.tags.BlogTag;
import sys.db.Types;

@:index(url,unique)
class BlogPost extends Object {
	/** The URL-safe name of the blog post. Use `setTitle()` to set both `url` and `title` simultaneously. **/
	@:validate( ~/^[a-zA-Z0-9\-]+$/.match(_), 'URL must contain only numbers, letters and hyphens' )
	public var url:SString<255> = "";

	/** The title of the blog post. Short so we can tweet it. Use `setTitle()` to set both `url` and `title` simultaneously. **/
	public var title:SString<120> = "";

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

	/**
	Set both `title` and `url` simultaneously.
	The title will have whitespace.
	The URL will be generated from the title, by lower-casing, hyphenating and whitespace, and removing unsupported characters.
	**/
	public function setTitle( t:String ) {
		title = StringTools.trim( t );
		url = title.toLowerCase();
		url = ~/(\s)/g.replace( url, "-" );
		url = ~/([^a-zA-Z0-9\-])/g.replace( url, "-" );
		return title;
	}

	/** Get either the introduction, or the post content, as markdown. **/
	public function getIntroOrContent():String {
		return ( introduction!=null && introduction.length>0 ) ? introduction : content;
	}

	/** Get the post content as HTML (rather than Markdown). **/
	public function getContentHTML():String {
		return Markdown.markdownToHtml( content );
	}

	/** Get either the introduction, or the post content, as HTML (rather than Markdown). **/
	public function getIntroOrContentHTML():String {
		return Markdown.markdownToHtml( getIntroOrContent() );
	}
}
