import 'dart:io';

import 'package:phantom/node/node.dart';
import 'package:phantom/node/storage.dart';
import 'package:phantom/node/trait.dart';
import 'package:phantom/node/traits/routing.dart';
import 'package:precision_stopwatch/precision_stopwatch.dart';
import 'package:shelf/shelf.dart';

abstract class WebServer implements Trait, Routing {
  Future<HttpServer> onWebserverStart(Handler handler);

  static Future<void> $callWebServerStart(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is WebServer) {
      if ((node as WebServer).$server != null) {
        node.logger.warn(
            "WebServer is already running! Trying to stop the old one first...");
        await (node as WebServer).$server?.close(force: false);
        (node as WebServer).$server = null;
        node.logger.warn("Stopped the old WebServer");
      }

      (node as WebServer).$server = await (node as WebServer)
          .onWebserverStart((node as Routing).$buildRouter);
      node.logger.info(
          "Started WebServer in ${wallClock.getMilliseconds().toStringAsFixed(0)}ms");
    }
  }

  static Future<void> $callWebServerStop(
      Node node, NodeStorage storage, PrecisionStopwatch wallClock) async {
    if (node is WebServer) {
      await (node as WebServer).$server?.close(force: false);
      (node as WebServer).$server = null;

      node.logger.info(
          "Stopped WebServer in ${wallClock.getMilliseconds().toStringAsFixed(0)}ms");
    }
  }
}

extension XWebServer on WebServer {
  HttpServer? get $server =>
      (this as Node).$metadata["webserver"] as HttpServer?;
  set $server(HttpServer? server) =>
      (this as Node).$metadata["webserver"] = server;
}
