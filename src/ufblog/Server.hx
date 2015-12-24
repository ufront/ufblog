package ufblog;

import ufront.MVC;
import sys.db.*;

class Server {
	static var ufApp:UfrontApplication;

	static function main() {
		ufApp = new UfrontApplication({
			indexController: BlogRoutes,
			remotingApi: BlogRemotingApiContext,
			defaultLayout: "layout-haxe.tpl",
			sessionImplementation: CacheSession,
		});
		// ufApp.useModNekoCache();
		InlineSessionMiddleware.alwaysStart = true;
		ufApp.injector.map( UFCacheConnectionSync ).toClass( DBCacheConnection );
		ufApp.injector.map( UFCacheConnection ).toClass( DBCacheConnection );

		Manager.cnx = Mysql.connect( CompileTime.parseJsonFile("db.json") );
		ufApp.executeRequest();
	}
}
