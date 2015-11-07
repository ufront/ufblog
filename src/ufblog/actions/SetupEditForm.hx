package ufblog.actions;

import ufront.MVC;
import tink.CoreApi;
#if client
	import js.html.HtmlElement;
	using Detox;
#end

class SetupEditForm implements UFClientAction<Noise> {
	public function new() {}

	public function execute( httpContext:HttpContext, ?data:Noise ):Void {
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
}
