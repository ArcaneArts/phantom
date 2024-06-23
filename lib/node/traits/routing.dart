import 'dart:mirrors';

import 'package:phantom/node/annotations/webserver.dart';
import 'package:phantom/node/node.dart';
import 'package:phantom/node/trait.dart';
import 'package:phantom/node/traits/middleware.dart';
import 'package:reflect_buddy/reflect_buddy.dart';
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
    InstanceMirror im = reflect(node);

    for (MethodMirror i in node
        .$allInstanceMethods()
        .where((i) => i.metadata.any((i) => i.reflectee is OnRequest))) {
      OnRequest? or = i.metadata
          .firstWhere((i) => i.reflectee is OnRequest)
          .reflectee as OnRequest?;

      if (!i.returnType.isAssignableTo(reflectType(Future<Response>))) {
        throw Exception(
            "Method ${i.simpleName} does not return a Future<Response>, expected since its using @OnRequest");
      }

      List<ParameterMirror> pathParams =
          i.parameters.where((i) => !i.isNamed && !i.isOptional).toList();

      bool hasRequest = false;
      if (pathParams.isNotEmpty &&
          pathParams.first.type.reflectedType == Request) {
        hasRequest = true;
        pathParams.removeAt(0);
      }

      for (ParameterMirror p in pathParams) {
        if (!p.type.isAssignableTo(reflectType(String))) {
          throw Exception(
              "Parameter ${p.simpleName} in method ${i.simpleName} is not a valid path parameter! Only String is allowed.");
        }
      }

      if (or != null) {
        List<ParameterMirror> namedParams =
            i.parameters.where((i) => i.isNamed).toList();

        Map<Symbol, dynamic> buildQParams(Request req) {
          Map<Symbol, dynamic> qparams = {};

          for (ParameterMirror p in namedParams) {
            Object? obj = req.url.queryParameters[p.simpleName.toName()];

            if (obj == null && !p.isOptional && p.defaultValue == null) {
              throw Exception(
                  "Parameter ${p.simpleName} is required but not provided!");
            }

            obj ??= p.defaultValue?.reflectee?.toString();

            if (obj != null) {
              if (p.type.reflectedType == String) {
                qparams[p.simpleName] = obj;
              } else if (p.type.reflectedType == int) {
                try {
                  qparams[p.simpleName] = int.tryParse(obj.toString()) ?? 0;
                } catch (e) {
                  throw Exception(
                      "Parameter ${p.simpleName} is not a valid integer!");
                }
              } else if (p.type.reflectedType == double) {
                try {
                  qparams[p.simpleName] =
                      double.tryParse(obj.toString()) ?? 0.0;
                } catch (e) {
                  throw Exception(
                      "Parameter ${p.simpleName} is not a valid double!");
                }
              } else if (p.type.reflectedType == bool) {
                qparams[p.simpleName] =
                    obj.toString().toLowerCase() == "true" ||
                        obj.toString().toLowerCase() == "t" ||
                        obj.toString().toLowerCase() == "y" ||
                        obj.toString().toLowerCase() == "on" ||
                        obj == "1";
              } else {
                throw Exception(
                    "Parameter ${p.simpleName} is not a valid type! String, int, double, and bool are allowed.");
              }
            }
          }

          return qparams;
        }

        StringBuffer sb = StringBuffer();
        String tpath = or.path;

        List<String> lParams = [];
        List<String> qParams = [];
        List<String> tParams = [];

        for (ParameterMirror p
            in i.parameters.where((i) => !i.isNamed && !i.isOptional)) {
          if (p.type.reflectedType == Request) {
            lParams.add("&7${p.name}");
          } else {
            lParams.add("&e${p.name}");
            tpath = tpath.replaceAll("<${p.name}>", "&7<&e${p.name}&7>&f");
          }
        }

        for (ParameterMirror p in i.parameters.where((i) => i.isNamed)) {
          if (p.hasDefaultValue) {
            qParams.add("&d${p.name}&7=${p.defaultValue!.reflectee}");
            tParams.add("&d${p.name}&7=${p.defaultValue!.reflectee}");
          } else {
            if (p.isOptional) {
              qParams.add("&d${p.name}");
              tParams.add("&d${p.name}");
            } else {
              qParams.add("&c${p.name}");
              tParams.add("&c${p.name}");
            }
          }
        }

        if (qParams.isNotEmpty) {
          lParams.add("&7{${qParams.join("&7, ")}&7}");
        }

        if (tParams.isNotEmpty) {
          tpath += "&7?${tParams.join("&7&")}";
        }

        sb.write(
            "Route &a${or.method} &f$tpath&7 -> &3${i.simpleName.toName()}(");
        sb.write(lParams.join("&7, "));
        sb.write("&3)");

        node.logger.verbose(sb.toString());

        if (pathParams.isEmpty) {
          r.add(
              or.method,
              or.path,
              (Request req) async => await (im
                  .invoke(
                      i.simpleName, [if (hasRequest) req], buildQParams(req))
                  .reflectee as Future<Response>));
        } else if (pathParams.length == 1) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1) async => await (im
                  .invoke(i.simpleName, [if (hasRequest) req, s1],
                      buildQParams(req))
                  .reflectee as Future<Response>));
        } else if (pathParams.length == 2) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2) async => await (im
                  .invoke(i.simpleName, [if (hasRequest) req, s1, s2],
                      buildQParams(req))
                  .reflectee as Future<Response>));
        } else if (pathParams.length == 3) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2, String s3) async => await (im
                  .invoke(i.simpleName, [if (hasRequest) req, s1, s2, s3],
                      buildQParams(req))
                  .reflectee as Future<Response>));
        } else if (pathParams.length == 4) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2, String s3, String s4) async =>
                  await (im
                      .invoke(
                          i.simpleName,
                          [if (hasRequest) req, s1, s2, s3, s4],
                          buildQParams(req))
                      .reflectee as Future<Response>));
        } else if (pathParams.length == 5) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2, String s3, String s4,
                      String s5) async =>
                  await (im
                      .invoke(
                          i.simpleName,
                          [if (hasRequest) req, s1, s2, s3, s4, s5],
                          buildQParams(req))
                      .reflectee as Future<Response>));
        } else if (pathParams.length == 6) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2, String s3, String s4,
                      String s5, String s6) async =>
                  await (im
                      .invoke(
                          i.simpleName,
                          [if (hasRequest) req, s1, s2, s3, s4, s5, s6],
                          buildQParams(req))
                      .reflectee as Future<Response>));
        } else if (pathParams.length == 7) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2, String s3, String s4,
                      String s5, String s6, String s7) async =>
                  await (im
                      .invoke(
                          i.simpleName,
                          [if (hasRequest) req, s1, s2, s3, s4, s5, s6, s7],
                          buildQParams(req))
                      .reflectee as Future<Response>));
        } else if (pathParams.length == 8) {
          r.add(
              or.method,
              or.path,
              (Request req, String s1, String s2, String s3, String s4,
                      String s5, String s6, String s7, String s8) async =>
                  await (im
                      .invoke(
                          i.simpleName,
                          [if (hasRequest) req, s1, s2, s3, s4, s5, s6, s7, s8],
                          buildQParams(req))
                      .reflectee as Future<Response>));
        } else {
          throw Exception(
              "Method ${i.simpleName} has too many path parameters! Only 8 are allowed.");
        }
      }
    }

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
