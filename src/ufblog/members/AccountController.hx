package ufblog.members;

import ufblog.members.BlogMemberApi;
import ufront.EasyAuth;
import ufront.MVC;
import tink.CoreApi;
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
		return new PartialViewResult({
			title: "Sign Up"
		});
	}

	@:route(POST,"/signup")
	public function doSignup( args:{ name:String, email:String, username:String, password1:String, password2:String } ):Surprise<ViewResult,Error> {
		var member = new BlogMember().init({
			email: args.email,
			name: args.name,
		});
		if ( member.validate()==false ) {
			var result = new PartialViewResult( args, "signupForm.erazor" ).setVar( "error", "Validation Error: "+member.validationErrors.toString() );
			return Future.sync( Success(result) );
		}
		else if ( args.password1!=args.password2 ) {
			var result = new PartialViewResult( args, "signupForm.erazor" ).setVar( "error", "Passwords did not match" );
			return Future.sync( Success(result) );
		}
		else return blogMemberApi.createUser( member, args.username, args.password1 ) >> function(member:BlogMember):ViewResult {
			return new PartialViewResult( { member:member }, "signupSuccess.erazor" );
		}
	}
}
