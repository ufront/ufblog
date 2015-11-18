package ufblog;

import ufront.MVC;
import ufblog.members.*;
import ufblog.posts.*;
import ufblog.tags.*;
#if server
	import ufront.ufadmin.controller.UFAdminHomeController;
#end

class BlogRoutes extends Controller {

	@post public function setupGlobalHelpers() {
		ViewResult.globalValues.set( "date", BlogUtil.dateString );
		ViewResult.globalValues.set( "datetime", BlogUtil.dateTimeString );
	}

	#if server
		@:route("/ufadmin/*") public var ufadmin:UFAdminHomeController;
	#end
	@:route("/accounts/*") public var accountController:AccountController;
	@:route("/blog-admin/users/*") public var memberManagementController:MemberManagementController;
	@:route("/blog-admin/tags/*") public var tagManagementController:TagManagementController;
	@:route("/blog-admin/*") public var postManagementController:PostManagementController;
	@:route("/*") public var blogListController:BlogListController;
}
