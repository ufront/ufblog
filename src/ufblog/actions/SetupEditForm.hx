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
		var previewBox = "#preview".find().first();

		function updatePreview( ?e ) {
			// Update the preview
			var title = titleInput.val();
			var md = editTextArea.val();
			var html = Markdown.markdownToHtml( md );
			previewBox.setInnerHTML( '<h1>$title</h1>'+html );
			// Resize the text box
			var textarea:HtmlElement = cast editTextArea;
			if ( textarea.clientHeight < textarea.scrollHeight ) {
				textarea.style.height = (textarea.scrollHeight+20) + "px";
			}
		}
		titleInput.keyup( updatePreview );
		editTextArea.keyup( updatePreview );
		updatePreview();
	}
}
