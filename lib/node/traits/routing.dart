import 'dart:mirrors';

import 'package:phantom/node/node.dart';
import 'package:phantom/node/trait.dart';
import 'package:phantom/node/traits/middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

abstract class Routing implements Trait {
  Router get router;

  String get prefix;
}

extension XRouting on Routing {
  Handler get $buildRouter {
    Node node = this as Node;
    Router r = router;

    for (VariableMirror i in node.$dependencyFields()) {
      if (i.type.isAssignableTo(reflectType(Routing))) {
        Routing? sr =
            reflect(node).getField(i.simpleName).reflectee as Routing?;

        if (sr != null) {
          r.mount(sr.prefix, sr.$buildRouter.call);
        }
      }
    }

    if (this is RouterMiddleware) {
      return Pipeline()
          .addMiddleware((this as RouterMiddleware).$createMiddleware)
          .addHandler(r.call);
    }

    return r.call;
  }
}
