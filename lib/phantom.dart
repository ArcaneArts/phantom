library phantom;

import 'dart:io';

import 'package:phantom/node/node.dart';
import 'package:phantom/node/traits/routing.dart';
import 'package:phantom/node/traits/web_server.dart';
import 'package:phantom/server/phantom_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

export 'package:phantom/node/annotations/instanced.dart';
export 'package:phantom/node/annotations/tag.dart';
export 'package:phantom/node/node.dart';
export 'package:phantom/node/pool.dart';
export 'package:phantom/node/storage.dart';
export 'package:phantom/node/trait.dart';
export 'package:phantom/node/traits/lifecycle.dart';
export 'package:phantom/node/traits/stateful.dart';
export 'package:phantom/node/traits/ticked.dart';
export 'package:phantom/server/phantom_server.dart';
export 'package:phantom/util/logger.dart';

void main() {
  PhantomServer(
    root: APIServer,
  ).start();
}

class APIServer with Node implements WebServer {
  late Api api;

  @override
  Future<HttpServer> onWebserverStart(Handler handler) =>
      serve(handler, "localhost", 8080);

  @override
  String get prefix => '/';

  @override
  Router get router => Router();
}

class Api with Node implements Routing {
  @override
  Router get router => Router()
    ..get("/help", (req) => Response.ok("help"))
    ..post("/push", (req) => Response.ok("done"));

  @override
  String get prefix => "/api";
}
