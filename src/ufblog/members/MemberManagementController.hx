package ufblog.members;

import ufront.MVC;
import ufront.EasyAuth;
import ufblog.members.BlogMemberApi;
import ufblog.BlogUtil;
import ufblog.BlogPermissions;
using tink.CoreApi;
using ObjectInit;

@viewFolder("blog/admin/")
class MemberManagementController extends Controller {

	var allPermissions:Array<EnumValue> = [
		BlogPermissions.WritePost,
		BlogPermissions.ViewDraftPosts,
		BlogPermissions.PublishPost,
		BlogPermissions.EditAnyPost,
		BlogPermissions.ViewUserList,
		BlogPermissions.ChangePermissions,
		BlogPermissions.ManageTags,
		BlogPermissions.CommentWithoutModeration,
		BlogPermissions.ModerateComments,
		EasyAuthPermissions.EAPCanDoAnything
	];

	@inject public var blogMemberApi:BlogMemberApiAsync;

	@:route(GET,"/")
	public function showUserList() {
		PartialViewResult.startLoadingAnimations();
		var blankArgs = { name:"", email:"", username:"" };
		return getUserListView( blankArgs );
	}

	@:route(POST,"/new-user")
	public function processNewUser( args:{ name:String, email:String, username:String, password1:String, password2:String } ) {
		PartialViewResult.startLoadingAnimations();
		var member = new BlogMember().init({
			email: args.email,
			name: args.name
		});
		if ( member.validate()==false ) {
			return getUserListView( args, "Validation Error: "+member.validationErrors.toString() );
		}
		else if ( args.password1!=args.password2 ) {
			return getUserListView( args, "Passwords did not match" );
		}
		else return blogMemberApi.createUser( member, args.username, args.password1 ) >> function(member:BlogMember):ActionResult {
			return new RedirectResult( baseUri+args.username );
		}
	}

	function getUserListView( args:{name:String,email:String,username:String}, ?error:String ):Surprise<ActionResult,Error> {
		return blogMemberApi.getAllMembers() >> function(members:Array<BlogMember>):ActionResult {
			return new PartialViewResult({
				title: "Blog Members",
				description: "Manage the members of your blog",
				members: members,
				error: error,
				args: args
			}, "manageUsers.erazor")
			.setVars( BlogUtil.addPermissionValues(context) )
			.addPartial( "userDetailsForm", "blog/userDetailsForm.erazor" );
		}
	}

	@:route(GET,"/$user")
	public function showUser( user:String ) {
		PartialViewResult.startLoadingAnimations();
		return blogMemberApi.getMemberByUsername( user ) >> function(member:BlogMember) {
			return getEditUserView( member );
		}
	}

	@:route(POST,"/$user/permissions/")
	public function saveUserPermissions( user:String, args:{ permissions:Array<String> } ) {
		PartialViewResult.startLoadingAnimations();
		var permissions = [];
		for ( pString in args.permissions ) {
			var parts = pString.split( ":" );
			var e = Type.resolveEnum( parts[0] );
			var permission = Type.createEnum( e, parts[1] );
			permissions.push( permission );
		}
		return blogMemberApi.updatePermissions( user, permissions ) >> function (n:Noise) return new RedirectResult( baseUri+user );
	}

	@:route(POST,"/$user/details/")
	public function saveUserDetails( user:String, args:{ name:String, email:String, username:String, password1:String, password2:String } ):Surprise<ActionResult,Error> {
		PartialViewResult.startLoadingAnimations();
		var member = new BlogMember().init({
			email: args.email,
			name: args.name,
			user: new User( args.username )
		});
		if ( member.validate()==false ) {
			var result = getEditUserView( member, "Validation Error: "+member.validationErrors.toString() );
			return Future.sync( Success(result) );
		}
		else if ( args.password1!=args.password2 ) {
			var result = getEditUserView( member, "Passwords did not match" );
			return Future.sync( Success(result) );
		}
		else return blogMemberApi.updateUser( member, user, args.username, args.password1 ) >> function(member:BlogMember):ActionResult {
			return new RedirectResult( baseUri+args.username );
		}
	}

	function getEditUserView( member:BlogMember, ?error:String ):ActionResult {
		var result = new PartialViewResult({
			title: member.name,
			description: 'Editing User ${member.name} (${member.user})',
			member: member,
			permissions: allPermissions,
			enumName: enumName,
			enumPath: enumPath,
			error: error,
			args: { name:member.name, email:member.email, username:member.user.username }
		}, "editUser.erazor" );
		result.setVars( BlogUtil.addPermissionValues(context) );
		result.addPartial( "userDetailsForm", "blog/userDetailsForm.erazor" );
		return result;
	}

	static function enumName(e:EnumValue) return Type.enumConstructor(e);
	static function enumPath(e:EnumValue) return Type.getEnumName(Type.getEnum(e))+':'+Type.enumConstructor(e);
}
