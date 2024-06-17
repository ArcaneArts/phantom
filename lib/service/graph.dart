import 'dart:mirrors';

import 'package:phantom/event/bus.dart';
import 'package:phantom/service/node.dart';
import 'package:phantom/service/service.dart';

final NodeGraph _mainGraph = NodeGraph._();

class NodeGraph {
  final Map<int, Object> tags = {};
  final Map<Type, List<ActiveNode>> nodes = {};

  NodeGraph._();

  static Future<T> root<T extends Object>({Object? withTag}) async =>
      await addOrGet(T, root: true, withTag: withTag);

  static void dump() {
    _mainGraph.nodes.forEach((k, v) {
      print(k);

      for (var i in v) {
        print("  - $i");
      }
    });
  }

  static Object? getTag(Object node) => _mainGraph.tags[identityHashCode(node)];

  static Iterable<T> getNodes<T extends Object>(
      {Object? withTag, Type? injectRuntimeType}) sync* {
    for (ActiveNode i in _mainGraph.nodes[injectRuntimeType ?? T] ?? []) {
      T t = i.node as T;
      Object? tag = getTag(t);

      if (identical(tag, withTag)) {
        yield t;
      }
    }
  }

  static T? getNode<T extends Object>(
          {Object? withTag, Type? injectRuntimeType}) =>
      getNodes<T>(withTag: withTag, injectRuntimeType: injectRuntimeType)
          .firstOrNull;

  static Future<T> addOrGet<T extends Object>(Type type,
      {ParameterMirror? parent, Object? withTag, bool root = false}) async {
    ClassMirror cm = reflectClass(type);

    if (!cm.metadata.any((i) => i.reflectee is Node)) {
      throw StateError(
          "Cannot instance $type as it's not annotated with @Node");
    }

    Node na = cm.metadata.firstWhere((i) => i.reflectee is Node).reflectee;

    if (parent != null) {
      ClassMirror pcm = parent.owner!.owner as ClassMirror;

      InstanceMirror? tagAnnotation;

      // Try to get Tag annotation from constructor param
      tagAnnotation ??=
          parent.metadata.where((j) => j.reflectee is Tag).firstOrNull;

      // Try to get Tag annotation from field by name of constructor param
      tagAnnotation ??= pcm.declarations.values
          .where((j) => j.simpleName == parent.simpleName)
          .firstOrNull
          ?.metadata
          .where((j) => j.reflectee is Tag)
          .firstOrNull;

      if (tagAnnotation != null) {
        withTag ??= (tagAnnotation.reflectee as Tag).value;
      }
    }

    T? t = na.instanced
        ? null
        : getNode<T>(withTag: withTag, injectRuntimeType: type);

    if (t == null) {
      List<Object> dependencies = [];
      t = await _createNode(type, parent: parent, dependencies: dependencies)
          as T;
      _mainGraph.nodes[t.runtimeType] ??= [];
      _mainGraph.nodes[t.runtimeType]!
          .add(ActiveNode(node: t, dependencies: dependencies, root: root));

      if (withTag != null) {
        _mainGraph.tags[identityHashCode(t)] = withTag;
      }
      
      InstanceMirror im = reflect(t);
      
      // Late bind services
      for ((VariableMirror, ClassMirror) i in cm.declarations.values
          .whereType<VariableMirror>()
          .where((i) => !i.isStatic && !i.isConst && !i.isFinal)
          .where((i) => reflectClass(i.type.reflectedType)
              .metadata
              .any((i) => i.reflectee is Node))
          .map((i) => (i, reflectClass(i.type.reflectedType)))) {
        VariableMirror v = i.$1;
        ClassMirror c = i.$2;
        Object? tag = v.metadata.where((i) => i.reflectee is Tag).firstOrNull?.reflectee
        await addOrGet(i.reflectedType, withTag: );
      }

      // @Instance
      cm.declarations.values
          .whereType<VariableMirror>()
          .where((i) =>
      i.isStatic &&
          !i.isPrivate &&
          !i.isConst &&
          i.type.isAssignableTo(reflectType(type)) &&
          i.metadata.any((i) => i.reflectee is Instance))
          .map((i) => i.simpleName)
          .forEach((i) => cm.setField(i, t));
      
      if (na.registerEvents) {
        EventBus.register(t);
      }

      // @OnStart
      for (MethodMirror i in cm.instanceMembers.values
          .whereType<MethodMirror>()
          .where((i) => i.metadata.any((j) => j.reflectee is OnStart))) {
        InstanceMirror r = im.invoke(i.simpleName, []);

        if (r.hasReflectee && r.reflectee is Future) {
          await r.reflectee;
        }
      }
    }

    return t;
  }

  static Future<Object> _createNode(Type nodeType,
      {ParameterMirror? parent, List<Object>? dependencies}) async {
    ClassMirror cm = reflectClass(nodeType);

    if (!cm.metadata.any((i) => i.reflectee is Node)) {
      throw StateError(
          "Cannot instance $nodeType as it's not annotated with @Node");
    }

    MethodMirror? m;

    if (parent != null) {
      ClassMirror pcm = (parent!.owner!.owner as ClassMirror);
      InstanceMirror? constructWithMirror;

      // Try to get Params annotation from constructor param
      constructWithMirror ??= parent.metadata
          .where((j) => j.reflectee is ConstructWith)
          .firstOrNull;

      // Try to get Params annotation from field by name of constructor param
      constructWithMirror ??= pcm.declarations.values
          .where((j) => j.simpleName == parent.simpleName)
          .firstOrNull
          ?.metadata
          .where((j) => j.reflectee is ConstructWith)
          .firstOrNull;

      if (constructWithMirror != null) {
        Symbol constructor = Symbol(
            (constructWithMirror.reflectee as ConstructWith).constructorName);
        m ??= cm.declarations.values
            .whereType<MethodMirror>()
            .where((i) => i.isConstructor && i.constructorName == constructor)
            .firstOrNull;
      }
    }

    m ??= cm.declarations.values
        .whereType<MethodMirror>()
        .where((i) => i.isConstructor)
        .firstOrNull;

    if (m == null) {
      throw StateError("Cannot find a constructor for $nodeType node!");
    }

    Iterable<ParameterMirror> namedParams =
        m.parameters.where((i) => i.isNamed);
    Iterable<ParameterMirror> params = m.parameters.where((i) => !i.isNamed);

    return cm
        .newInstance(
            m.constructorName,
            await params.indexed
                .map((im) => Future(() async {
                      int index = im.$1;
                      ParameterMirror i = im.$2;
                      Object? value;
                      InstanceMirror? paramsAnnotation;

                      if (parent?.owner?.owner is ClassMirror) {
                        // Try to get wired annotation from field by name of constructor param
                        ClassMirror pcm = (parent!.owner!.owner as ClassMirror);

                        // Try to get Params annotation from constructor param
                        paramsAnnotation ??= parent.metadata
                            .where((j) => j.reflectee is Params)
                            .firstOrNull;

                        // Try to get Params annotation from field by name of constructor param
                        paramsAnnotation ??= pcm.declarations.values
                            .where((j) => j.simpleName == parent.simpleName)
                            .firstOrNull
                            ?.metadata
                            .where((j) => j.reflectee is Params)
                            .firstOrNull;
                      }

                      if (paramsAnnotation != null) {
                        List<dynamic> p =
                            (paramsAnnotation.reflectee as Params).params;
                        value ??= p.length > index ? p[index] : value;
                      }

                      if (value == null) {
                        Object g =
                            await addOrGet(i.type.reflectedType, parent: i);
                        dependencies?.add(g);
                        value = g;
                      }

                      return value;
                    }))
                .oneByOne,
            Map.fromEntries(
                await Stream.fromIterable(namedParams).asyncMap((i) async {
              Object? value;
              InstanceMirror? optsAnnotation;

              // Try to get wired annotation from constructor param
              if (parent?.owner?.owner is ClassMirror) {
                // Try to get wired annotation from field by name of constructor param
                ClassMirror pcm = (parent!.owner!.owner as ClassMirror);
                optsAnnotation ??= parent.metadata
                    .where((j) => j.reflectee is Options)
                    .firstOrNull;

                optsAnnotation ??= pcm.declarations.values
                    .where((j) => j.simpleName == parent.simpleName)
                    .firstOrNull
                    ?.metadata
                    .where((j) => j.reflectee is Options)
                    .firstOrNull;
              }

              // Assign value to constructor if autowire defines mapped parameter for it
              if (optsAnnotation != null) {
                value ??= (optsAnnotation.reflectee as Options)
                    .options
                    .map((k, v) => MapEntry(Symbol(k), v))[i.simpleName];
              }

              // Assign default constructor param instead
              value ??=
                  i.hasDefaultValue && (i.defaultValue?.hasReflectee ?? false)
                      ? i.defaultValue!.reflectee
                      : value;

              if (value == null) {
                Object g = await addOrGet(i.type.reflectedType, parent: i);
                dependencies?.add(g);
                value = g;
              }

              return MapEntry(i.simpleName, value);
            }).toList()))
        .reflectee;
  }

  static Future<void> remove(Object node) async {
    int index = _mainGraph.nodes[node.runtimeType]
            ?.indexWhere((i) => identical(i.node, node)) ??
        -1;

    if (index >= 0) {
      ActiveNode removed = _mainGraph.nodes[node.runtimeType]!.removeAt(index);
      ClassMirror cm = reflectClass(removed.node.runtimeType);
      InstanceMirror im = reflect(removed.node);
      for (MethodMirror i in cm.instanceMembers.values
          .whereType<MethodMirror>()
          .where((i) => i.metadata.any((j) => j.reflectee is OnStop))) {
        InstanceMirror r = im.invoke(i.simpleName, []);

        if (r.hasReflectee && r.reflectee is Future) {
          await r.reflectee;
        }

        EventBus.unregister(removed.node);
      }

      while (await purge()) {}
    }
  }

  static Future<bool> purge() async {
    Set<int> identities = {};

    for (ActiveNode i in _mainGraph.nodes.values.expand((i) => i)) {
      identities.add(identityHashCode(i.node));
    }

    identities.removeAll(_mainGraph.nodes.values
        .expand((i) => i)
        .expand((i) => i.dependencies)
        .map((i) => identityHashCode(i)));
    List<Future> work = [];
    for (ActiveNode i in _mainGraph.nodes.values.expand((i) => i).toList()) {
      if (!i.root && identities.contains(identityHashCode(i.node))) {
        work.add(remove(i.node));
      }
    }

    return (await Future.wait(work)).isNotEmpty;
  }
}

extension _XSTR<T> on Stream<T> {
  Future<List<G>> parallelMap<G>(Future<G> Function(T t) mapper) async {
    List<Future<G>> f = [];

    await for (T i in this) {
      f.add(mapper(i));
    }

    return Future.wait(f);
  }
}

extension _XFL<T> on Iterable<Future<T>> {
  Future<List<T>> get waitFor => Future.wait(this);

  Future<List<T>> get oneByOne async {
    List<T> t = [];

    for (Future<T> i in this) {
      t.add(await i);
    }

    return t;
  }
}
