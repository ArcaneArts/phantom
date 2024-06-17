class ActiveNode {
  final Object node;
  final List<Object> dependencies;
  final bool root;

  ActiveNode(
      {required this.node, this.dependencies = const [], this.root = false});

  @override
  String toString() {
    return "${node.toString()} deps ${dependencies.join(",")}";
  }
}
