import 'dart:async';

import 'package:phantom/node/trait.dart';
import 'package:shelf/shelf.dart';

abstract class RouterMiddleware implements Trait {
  Future<Response?> onRequest(Request request);

  Future<Response> onResponse(Response response);

  Future<Response> onError(Object error, StackTrace stackTrace);
}

extension XRouterMiddleware on RouterMiddleware {
  Middleware get $createMiddleware => createMiddleware(
      requestHandler: onRequest,
      responseHandler: onResponse,
      errorHandler: onError);
}
