library phantom;

import 'package:phantom/server/phantom_server.dart';
import 'package:phantom/test/main.dart';

void main() async {
  await PhantomServer(
    root: Main,
  ).start();
}
