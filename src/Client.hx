import ufront.MVC;
import ufblog.BlogController;

class Client {
	static var jsApp:ClientJsApplication;

	static function main() {
		jsApp = new ClientJsApplication({
			indexController: BlogController,
			defaultLayout: "layout-haxe.tpl",
		});

		jsApp.listen();
	}
}
