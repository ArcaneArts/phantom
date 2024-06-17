import 'dart:mirrors';

class Instance {
  const Instance();
}

class OnStart {
  const OnStart();
}

class OnStop {
  const OnStop();
}

class Node {
  final bool registerEvents;
  final bool instanced;

  const Node({this.instanced = false, this.registerEvents = true});
}

class Tag {
  final Object value;

  /// A tag can be used to discern parameters or fields from others
  const Tag(this.value);
}

class ConstructWith {
  final String constructorName;

  /// Allows you to specify a specific constructor to call
  /// For example @ConstructWith("custom") would call Object.custom(...)
  /// for initialization
  const ConstructWith(this.constructorName);
}

class Params {
  final List<dynamic> params;

  /// Allows you to specify ordered parameter values
  /// Specify null to skip an ordered parameter into wired constructor
  const Params(this.params);
}

class Options {
  final Map<String, dynamic> options;

  /// Allows you to specify mapped parameters
  /// into a constructor
  const Options(this.options);
}
