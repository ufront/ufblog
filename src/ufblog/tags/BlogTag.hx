package ufblog.tags;

import ufront.ORM;
import ufblog.posts.BlogPost;
import sys.db.Types;

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
