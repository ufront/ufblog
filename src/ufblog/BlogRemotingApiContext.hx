package ufblog;

import ufront.MVC;
import ufblog.members.*;
import ufblog.posts.*;
import ufblog.tags.*;
import ufront.auth.api.*;

class BlogRemotingApiContext extends UFApiContext {
	public var attachmentApi:AttachmentApi;
	public var blogPostApi:BlogPostApi;
	public var blogMemberApi:BlogMemberApi;
	public var blogTagApi:BlogTagApi;
	public var easyAuthApi:EasyAuthApi;
}
