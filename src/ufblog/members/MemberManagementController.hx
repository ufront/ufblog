package ufblog.members;

import ufront.MVC;

@viewFolder("blog/admin/")
class MemberManagementController extends Controller {

	@:route(GET,"/users/")
	public function manageUsers() {
		return "Manage some users";
	}
}
