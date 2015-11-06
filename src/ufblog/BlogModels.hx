package ufblog;

import ufront.db.DatabaseID;
import ufront.db.Object;
import ufront.db.ManyToMany;
import ufront.auth.model.User;
import sys.db.Types;
import tink.CoreApi;

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
	The title will be lowercased, sanitised and hyphenated to generate a URL.
	**/
	public function setTitle( t:String ) {
		this.title = StringTools.trim( t );
		this.url = ~/(\s)/g.replace( this.title, "-" );
		this.url = ~/([^a-zA-Z0-9\-])/g.replace( this.title.toLowerCase(), "-" );
		return this.title;
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

@:index(userID,unique)
@:index(email,unique)
class BlogMember extends Object {
	/** A link to the ufront-easyauth `User` if they are one. **/
	public var user:Null<BelongsTo<User>>;

	/** The email address for this user. **/
	public var email:SString<255>;

	/** The human-readable name of this user. **/
	public var name:SString<255>;

	/** All the posts written by this user. **/
	public var posts:HasMany<BlogPost>;

	/** All the comments written by this user. **/
	public var comments:HasMany<BlogComment>;

	override public function toString() return name;
}

class BlogTag extends Object {
	/** The URL-safe tag name. **/
	public var name:SString<255>;

	/** The title for this tag. **/
	public var title:SString<255>;

	/** An optional description for this tag (markdown). **/
	public var description:Null<SText>;

	/** The posts that have this tag. **/
	public var posts:ManyToMany<BlogTag,BlogPost>;
}

class BlogComment extends Object {
	/** Has a moderator approved this comment? **/
	public var approved:Bool;

	/** The post the comment is attached to. **/
	public var blogPost:BelongsTo<BlogPost>;

	/** If this comment is a reply to another comment, then `replyTo` is the parent comment. **/
	public var replyTo:Null<BelongsTo<BlogComment>>;

	/** This is a list of any comments that are replies to this comment. **/
	@:relationKey(replyToID)
	public var replies:HasMany<BlogComment>;

	/** The person who wrote this comment. **/
	public var author:BelongsTo<BlogMember>;

	/** The comment itself (markdown). **/
	public var comment:SText;
}

typedef PostListResultFor<T> = Outcome<Pair<T,Array<BlogPost>>,Error>;
