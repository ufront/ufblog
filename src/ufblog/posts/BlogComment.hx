package ufblog.posts;

import ufront.ORM;
import ufblog.members.BlogMember;
import sys.db.Types;

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
