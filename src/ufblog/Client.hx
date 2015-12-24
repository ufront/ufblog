package ufblog;

import ufront.MVC;
import ufblog.posts.*;

class Client {
	static var jsApp:ClientJsApplication;

	static function main() {
		jsApp = new ClientJsApplication({
			indexController: BlogRoutes,
			defaultLayout: "layout-haxe.tpl",
			clientActions: [SavePostAction,SetupEditFormAction],
		});

		jsApp.listen();
	}
}
