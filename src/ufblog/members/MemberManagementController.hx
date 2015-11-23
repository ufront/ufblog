package ufblog.members;

import ufront.MVC;
import ufront.EasyAuth;
import ufblog.members.BlogMemberApi;
import ufblog.BlogUtil;
import ufblog.BlogPermissions;
using tink.CoreApi;

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
		return blogMemberApi.getAllMembers() >> function(members:Array<BlogMember>) {
			return new PartialViewResult({
				title: "Blog Members",
				description: "Manage the members of your blog",
				members: members,
			}, "manageUsers").setVars( BlogUtil.addPermissionValues(context) );
		}
	}

	@:route(GET,"/$user")
	public function showUser( user:String ) {
		return blogMemberApi.getMemberByUsername( user ) >> function(member:BlogMember) {
			return new PartialViewResult({
				title: member.name,
				description: 'Viewing permissions for ${member.user}',
				member: member,
				permissions: allPermissions,
				enumName: enumName,
				enumPath: enumPath,
			}, "editUser").setVars( BlogUtil.addPermissionValues(context) );
		}
	}

	@:route(POST,"/$user")
	public function saveUser( user:String, args:{ permissions:Array<String> } ) {
		var permissions = [];
		for ( pString in args.permissions ) {
			var parts = pString.split( ":" );
			var e = Type.resolveEnum( parts[0] );
			var permission = Type.createEnum( e, parts[1] );
			permissions.push( permission );
		}
		return blogMemberApi.updatePermissions( user, permissions ) >> function (n:Noise) return new RedirectResult( baseUri+user );
	}

	static function enumName(e:EnumValue) return Type.enumConstructor(e);
	static function enumPath(e:EnumValue) return Type.getEnumName(Type.getEnum(e))+':'+Type.enumConstructor(e);
}
