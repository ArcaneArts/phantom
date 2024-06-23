library phantom;

import 'dart:io';

import 'package:phantom/node/node.dart';
import 'package:phantom/node/traits/routing.dart';
import 'package:phantom/node/traits/web_server.dart';
import 'package:phantom/server/phantom_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'node/annotations/webserver.dart';

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
  Router get router => Router();

  @OnRequest.get("/get/<folder>/<file>")
  Future<Response> getFile(
    Request r,
    String folder,
    String file, {
    bool download = false,
    int? version,
  }) async {
    return Response.ok(
        "You requested $folder/$file with download=$download and version=$version");
  }

  @OnRequest.get("/math/<operation>")
  Future<Response> doMath(
    Request r,
    String operation, {
    required double a,
    required double b,
  }) async {
    return switch (operation) {
      "add" => Response.ok("$a + $b = ${a + b}"),
      "subtract" => Response.ok("$a - $b = ${a - b}"),
      "multiply" => Response.ok("$a * $b = ${a * b}"),
      "divide" => Response.ok("$a / $b = ${a / b}"),
      "mod" => Response.ok("$a % $b = ${a % b}"),
      _ => Response.notFound("Unknown operation: $operation"),
    };
  }

  @OnRequest.get("/help")
  Future<Response> getHelp() async {
    return Response.ok("help");
  }

  @OnRequest.post("/push")
  Future<Response> push() async {
    return Response.ok("done");
  }

  @override
  String get prefix => "/api";
}
