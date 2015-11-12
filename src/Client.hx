import ufront.MVC;
import ufblog.BlogRoutes;

class Client {
	static var jsApp:ClientJsApplication;

	static function main() {
		jsApp = new ClientJsApplication({
			indexController: BlogRoutes,
			defaultLayout: "layout-haxe.tpl",
		});

		jsApp.listen();
	}
}
