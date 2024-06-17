import 'package:phantom/service/graph.dart';
import 'package:phantom/service/service.dart';
import 'package:phantom/service/subsystem.dart';

void main() async {
  await Phantom.start(Main);
  NodeGraph.dump();
}

@Node()
class Main {
  @Instance()
  static late Main i;

  Main();

  @OnStart()
  Future<void> onStart() async {
    print("+ Main");
    print("I is $i");
  }

  @OnStop()
  Future<void> onStop() async {
    print("- Main");
  }
}

@Node(instanced: false)
class Util {
  final String value;

  Util({this.value = "def"});

  @OnStart()
  Future<void> onStart() async {
    print("+ Util");
  }

  @OnStop()
  Future<void> onStop() async {
    print("- Util");
  }

  @override
  String toString() => "Util($value):${identityHashCode(this)}";
}
