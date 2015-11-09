import ufront.MVC;
import ufblog.BlogController;
import ufblog.BlogApi;
import sys.db.*;

class Server {
	static var ufApp:UfrontApplication;

	static function main() {
		ufApp = new UfrontApplication({
			indexController: BlogController,
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
