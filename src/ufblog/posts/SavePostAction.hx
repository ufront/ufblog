package ufblog.posts;

import ufront.MVC;
import ufblog.posts.BlogPost;
import ufblog.posts.BlogPostApi;
import pushstate.PushState;
#if client
	import js.html.*;
	import js.Browser.*;
	using Detox;
#end
using ObjectInit;

@:enum abstract SavePublishOption(String) from String {
	var Default = "default";
	var Custom = "custom";
	var Draft = "draft";
}

class SavePostAction extends UFClientAction<String> {
	public function new() {}

	override public function execute( ctx:HttpContext, ?publishOption:SavePublishOption ):Void {
		var blogPost = readBlogPostFromForm( publishOption );
		var tagNames = [for (opt in "#tags option:checked".find()) opt.attr("value")];
		var blogPostApi = ctx.injector.getInstance( BlogPostApiAsync );
		blogPostApi.updatePost( blogPost, tagNames ).handle(function (outcome) {
			switch outcome {
				case Success(blogPost):
					// Replace the URL in the edit form (in case it's changed) and update the ID input.
					var urlParts = ctx.getRequestUri().split("/");
					urlParts.pop();
					urlParts.pop();
					urlParts.push( blogPost.url );
					urlParts.push( "edit" );
					var newUrl = ctx.generateUri( urlParts.join("/") );
					PushState.silentReplace( newUrl );
					"#id".find().setVal( ""+blogPost.id );
					"#post-url".find().setVal( ctx.generateUri("/"+blogPost.url) );
					// TODO: something less brutal than an alert.
					window.alert( 'Saved successfully' );
				case Failure(err):
					window.alert( 'Failed to save post: $err' );
			}
		});
	}

	function readBlogPostFromForm( publishOption ):BlogPost {
		var publishDate = switch publishOption {
			case Default:
				var str = "#publishDate".find().val();
				if ( str=="null" || str==null || str=="" ) null
				else try Date.fromString( str ) catch (e:Dynamic) promptForDate();
			case Custom: promptForDate();
			case Draft: null;
		}
		var createdStr = "#created".find().val();
		var modifiedStr = "#modified".find().val();
		return new BlogPost().init({
			id: Std.parseInt( "#id".find().val() ),
			created: (createdStr!="") ? Date.fromString( createdStr ) : null,
			modified: (modifiedStr!="") ? Date.fromString( modifiedStr ) : null,
			authorID: Std.parseInt( "#authorID".find().val() ),
			url: "#url".find().val(),
			title: "#title".find().val(),
			headerImage: "#headerImage".find().val(),
			introduction: "#introduction".find().val(),
			publishDate: publishDate,
			content: "#content".find().val(),
		});
	}

	function promptForDate():Date {
		var today = BlogUtil.dateString( Date.now() );
		var date:Date = null;
		while ( date==null ) {
			var dateStr = window.prompt( 'Please enter the date to publish', today );
			if ( dateStr==null || dateStr=="" )
				return null;
			date = try Date.fromString( dateStr ) catch ( e:Dynamic ) null;
		}
		return date;
	}
}
