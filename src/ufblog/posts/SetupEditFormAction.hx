package ufblog.posts;

import ufront.MVC;
import tink.CoreApi;
import ufblog.posts.BlogPost;
import ufblog.posts.BlogPostApi;
#if client
	import js.html.HtmlElement;
	using Detox;
#end

class SetupEditFormAction implements UFClientAction<Noise> {
	public function new() {}

	public function execute( httpContext:HttpContext, ?data:Noise ):Void {
		updatePreviewOnKeypress();
		updateUrlAndCheckItIsUnique( httpContext );
	}

	function updatePreviewOnKeypress() {
		var titleInput = "#title".find().first();
		var editTextArea = "#content".find().first();
		var introTextArea = "#introduction".find().first();
		var previewBox = "#preview".find().first();

		function updatePreview( ?e ) {
			// Update the preview
			var title = titleInput.val();
			var intro = introTextArea.val();
			var html = Markdown.markdownToHtml( editTextArea.val() );
			previewBox.setInnerHTML( '<h1>$title</h1><p class="lead">$intro</p>'+html );
			// Resize the text box
			var textarea:HtmlElement = cast editTextArea;
			if ( textarea.clientHeight < textarea.scrollHeight ) {
				textarea.style.height = (textarea.scrollHeight+20) + "px";
			}
			var textarea:HtmlElement = cast introTextArea;
			if ( textarea.clientHeight < textarea.scrollHeight ) {
				textarea.style.height = (textarea.scrollHeight+20) + "px";
			}
		}
		titleInput.keyup( updatePreview );
		editTextArea.keyup( updatePreview );
		introTextArea.keyup( updatePreview );
		updatePreview();
	}

	function updateUrlAndCheckItIsUnique( httpContext:HttpContext ) {
		var titleInput = "#title".find().first();
		var urlControlGroup = "#url-group".find();
		var urlWarning = "#url-warning".find();
		var urlInput = "#url".find();

		titleInput.on("keyup change", function(e) {
			var title = titleInput.val();
			var url = BlogPost.urlFromTitle( title );
			urlInput.setVal( url );
			urlInput.change();
		});
		urlInput.change(function(e) {
			var currentPostID = Std.parseInt( "#id".find().val() );
			var postApi = httpContext.injector.getInstance( BlogPostApiAsync );
			var url = urlInput.val();
			postApi.getPostBySlug( url ).handle(function(outcome) switch outcome {
				case Success(post) if (post.id!=currentPostID):
					urlControlGroup.addClass( "warning" );
					urlWarning.setText( 'A post with this URL already exists' ).removeClass( 'hidden' );
				case _:
					urlControlGroup.removeClass( "warning" );
					urlWarning.setText( '' ).addClass( 'hidden' );
			});
		});
	}
}
