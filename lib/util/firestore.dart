import 'package:fire_api/fire_api.dart';
import 'package:fire_api_dart/fire_api_dart.dart';
import 'package:phantom/node/node.dart';
import 'package:phantom/node/traits/lifecycle.dart';

/// To use Firestore in your Phantom server, you need to either make sure
/// you are running in a google cloud environment or provide a service account key file.
///
/// <br/>
///
/// If you are not running on google and want to easily test ensure the following
/// environment variables are set when running. (in intellij, you can set them in the run configuration)
/// 1. GCP_PROJECT=<project_id>
/// 2. GOOGLE_APPLICATION_CREDENTIALS=<path_to_service_account_key.json>
///
/// <br/>
///
/// If you need a custom database name, other than "(default)", or custom auth provider: copy the source
/// of this class then modify the create() call in onStart() to pass the custom database name or custom auth
class Firestore with Node implements Lifecycle {
  late FirestoreDatabase _db;

  @override
  Future<void> onStart() async {
    _db = await GoogleCloudFirestoreDatabase.create();
    logger.info("Firestore Database Online");
  }

  @override
  Future<void> onStop() async {}

  CollectionReference collection(String id) => _db.collection(id);

  DocumentReference doc(String id) => _db.document(id);
}
