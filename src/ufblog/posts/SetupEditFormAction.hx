package ufblog.posts;

import ufront.MVC;
import tink.CoreApi;
import ufblog.posts.BlogPost;
import ufblog.posts.BlogPostApi;
import ufblog.posts.AttachmentApi;
import ufront.web.upload.BrowserFileUpload;
#if client
	import js.html.*;
	import js.Browser.*;
	using Detox;
	using StringTools;
#end

class SetupEditFormAction extends UFClientAction<Noise> {
	public function new() {}

	override public function execute( httpContext:HttpContext, ?data:Noise ):Void {
		updatePreviewOnKeypress();
		updateUrlAndCheckItIsUnique( httpContext );
		setupUploadHandler( httpContext );
		setupHeaderUploadHandler( httpContext );
	}

	function updatePreviewOnKeypress() {
		var titleInput = "#title".find().first();
		var editTextArea = "#content".find().first();
		var introTextArea = "#introduction".find().first();
		var headerImageInput = "#headerImage".find().first();
		var previewBox = "#preview".find().first();

		function updatePreview( ?e ) {
			// Update the preview header
			var postUrl = "#post-url".find().val();
			"#preview header h1".find().setText( titleInput.val() );
			"#preview header p.lead".find().setText( introTextArea.val() );
			var headerImage =
				if ( headerImageInput.val()!="" && headerImageInput.val()!="null" ) 'url("$postUrl/files/${headerImageInput.val()}")'
				else "";
			"#preview header".find().setCSS( "background-image", headerImage, true );
			// Update the preview content
			var md = editTextArea.val().replace( '(~/', '($postUrl/files/' );
			"#preview section".find().setInnerHTML( Markdown.markdownToHtml(md) );
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
		});
		titleInput.change(function(e) urlInput.trigger("change"));
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

	function setupUploadHandler( httpContext:HttpContext ) {
		var fileInput = Std.instance( "#file-upload".find().first(), InputElement );
		var textArea = Std.instance( "#content".find().first(), TextAreaElement );

		fileInput.on("click", checkSavedBeforeUpload);
		fileInput.change(function(e) {
			var currentPostID = Std.parseInt( "#id".find().val() );
			var fileList = fileInput.files;
			for ( i in 0...fileList.length ) {
				var file = fileList[i];
				var upload = new BrowserFileUpload( "file-upload", file );

				// Insert a placeholder
				var filename = upload.originalFileName;
				var tmpText = '<Uploading "${filename}">';
				var start = textArea.selectionStart;
				var before = textArea.value.substring( 0, start );
				var after = textArea.value.substring( textArea.selectionEnd, textArea.textLength );
				textArea.value = before + tmpText + after;
				textArea.setSelectionRange( start, tmpText.length );

				// Upload the file using our API
				var attachmentApi = httpContext.injector.getInstance( AttachmentApiAsync );
				attachmentApi.uploadImage( currentPostID, upload ).handle(function(outcome) {
					switch outcome {
						case Success(url):
							// Replace the placeholder with a link or an image
							var newText = '[${filename}]($url)';
							if ( upload.contentType.startsWith("image/") )
								newText = '!'+newText;
							textArea.value = textArea.value.replace( tmpText, newText );
							textArea.trigger( "keyup" );
						case Failure(err):
							ufError( 'Failed: $err' );
					}
				});
			}
		});
	}

	function setupHeaderUploadHandler( httpContext:HttpContext ) {
		var headerUploadInput = Std.instance( "#header-upload".find().first(), InputElement );
		var headerUrlInput = "#headerImage".find();
		var textArea = "#content".find();

		headerUploadInput.on("click", checkSavedBeforeUpload);
		headerUploadInput.change(function(e) {
			var currentPostID = Std.parseInt( "#id".find().val() );
			var file = headerUploadInput.files[0];
			if ( file!=null ) {
				var upload = new BrowserFileUpload( "header-upload", file );
				var attachmentApi = httpContext.injector.getInstance( AttachmentApiAsync );
				attachmentApi.uploadHeaderImage( currentPostID, upload ).handle(function(outcome) {
					switch outcome {
						case Success(url):
							headerUrlInput.setVal( upload.originalFileName );
							textArea.trigger( "keyup" );
						case Failure(err):
							ufError( 'Failed: $err' );
					}
				});
			}
		});
	}

	function checkSavedBeforeUpload(e) {
		var currentPostID = Std.parseInt( "#id".find().val() );
		if ( currentPostID==null ) {
			alert( 'You must save this post before uploading images or attachments' );
			e.preventDefault();
		}
	}
}
