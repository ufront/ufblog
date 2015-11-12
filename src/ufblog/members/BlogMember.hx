package ufblog.members;

import ufront.ORM;
import ufront.EasyAuth;
import ufblog.posts.*;
import sys.db.Types;

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
