package ufblog.members;

import ufblog.members.BlogMemberApi;
import ufront.EasyAuth;
import ufront.MVC;
import tink.CoreApi;
using ufront.core.AsyncTools;
using ObjectInit;

@viewFolder("blog")
class AccountController extends Controller {

	@inject public var blogMemberApi:BlogMemberApiAsync;
	@inject public var easyAuthApi:EasyAuthApiAsync;
	@inject("blogUri") public var blogUri:String;

	@:route("/")
	public function accounts() {
		return new RedirectResult( baseUri+"login/" );
	}

	@:route(GET,"/login")
	public function login() {
		return showLoginForm();
	}

	function showLoginForm( ?existingUser="", ?msg:String ) {
		return new PartialViewResult({
			title: "Login",
			username: existingUser,
			msg: msg,
		}, "login.erazor");
	}

	@:route(POST,"/login")
	public function doLogin( args:{ username:String, password:String } ):Future<ActionResult> {
		var surprise = context.session.init()
			>> function(n:Noise) return easyAuthApi.attemptLogin( args.username, args.password )
			>> function(u:User):ActionResult return new RedirectResult( blogUri );
		return surprise.map(function(outcome) return switch outcome {
			case Success(result): result;
			case Failure(err): showLoginForm( args.username, err.message );
		});
	}

	@:route("/logout")
	public function logout():Surprise<ActionResult,Error> {
		return easyAuthApi.logout()
			>> function(n:Noise):ActionResult return new RedirectResult( blogUri );
	}

	@:route(GET,"/signup")
	public function signupForm() {
		return getSignupView({ name:"", email:"", username:"" });
	}

	@:route(POST,"/signup")
	public function doSignup( args:{ name:String, email:String, username:String, password1:String, password2:String } ):Surprise<ActionResult,Error> {
		var member = new BlogMember().init({
			email: args.email,
			name: args.name,
		});
		if ( member.validate()==false ) {
			return getSignupView( args, "Validation Error: "+member.validationErrors.toString() ).asGoodSurprise();
		}
		else if ( args.password1!=args.password2 ) {
			return getSignupView( args, "Passwords did not match" ).asGoodSurprise();
		}
		else return blogMemberApi.createUser( member, args.username, args.password1 ) >> function(member:BlogMember):ActionResult {
			return new PartialViewResult( { member:member }, "signupSuccess.erazor" );
		}
	}

	function getSignupView( args:{ name:String, email:String, username:String }, ?err:String ):ActionResult {
		var result = new PartialViewResult({
			title: "Sign Up",
			error: err,
			args: args
		}, "signupForm.erazor" );
		result.addPartial( "userDetailsForm", "blog/userDetailsForm.erazor" );
		return result;
	}

	@:route(GET,"/edit-profile")
	public function editProfileForm() {
		return blogMemberApi.getCurrentMember() >> function(m:BlogMember) {
			return getEditProfileView({ name:m.name, email:m.email, username:m.user.username });
		}
	}

	@:route(POST,"/edit-profile")
	public function doEditProfile( args:{ name:String, email:String, username:String, password1:String, password2:String } ):Surprise<ActionResult,Error> {
		var member = new BlogMember().init({
			email: args.email,
			name: args.name,
		});
		var oldUsername = context.currentUserID;
		if ( member.validate()==false ) {
			return getEditProfileView( args, "Validation Error: "+member.validationErrors.toString() ).asGoodSurprise();
		}
		else if ( args.password1!=args.password2 ) {
			return getEditProfileView( args, "Passwords did not match" ).asGoodSurprise();
		}
		else return blogMemberApi.updateUser( member, oldUsername, args.username, args.password1 ) >> function(member:BlogMember):ActionResult {
			return getEditProfileView( args, "Profile updated" );
		}
	}

	function getEditProfileView( args:{ name:String, email:String, username:String }, ?err:String ):ActionResult {
		var result = new PartialViewResult({
			title: "Edit Profile",
			error: err,
			args: args
		}, "editProfile.erazor" );
		result.addPartial( "userDetailsForm", "blog/userDetailsForm.erazor" );
		return result;
	}
}
