import 'package:fire_api/fire_api.dart';
import 'package:fire_api_dart/fire_api_dart.dart';
import 'package:phantom/node/node.dart';
import 'package:phantom/node/traits/lifecycle.dart';

class FireFS with Node implements Lifecycle {
  late FireStorage storage;
  @override
  Future<void> onStart() async {
    storage = await GoogleCloudFireStorage.create();
  }

  @override
  Future<void> onStop() async {}

  FireStorageRef bucket(String bucket) => storage.bucket(bucket);

  FireStorageRef ref(String bucket, String path) => storage.ref(bucket, path);
}
