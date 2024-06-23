import 'package:google_cloud/google_cloud.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
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
class FirestoreDatabase with Node implements Lifecycle {
  late FirestoreDatabaseWrapper _db;

  @override
  Future<void> onStart() async {
    _db = await FirestoreDatabaseWrapper.create();
    logger.info("Firestore Database Online ${_db._dbPath}");
  }

  @override
  Future<void> onStop() async {}

  CollectionReference collection(String id) => _db.collection(id);

  DocumentReference doc(String id) => _db.doc(id);
}

class FirestoreDatabaseWrapper {
  final FirestoreApi _api;
  final String _project;
  final String _database;
  String get _dbPath => "projects/$_project/databases/$_database";
  String get _documentsPath => "$_dbPath/documents";
  ProjectsDatabasesDocumentsResource get _documents =>
      _api.projects.databases.documents;

  FirestoreDatabaseWrapper._create(this._api, this._project, this._database);

  static Future<FirestoreDatabaseWrapper> create(
      {AuthClient? auth, String database = "(default)"}) async {
    Future<String> projectId = computeProjectId();
    Future<AuthClient> authClient = auth == null
        ? clientViaApplicationDefaultCredentials(
            scopes: [FirestoreApi.datastoreScope])
        : Future.value(auth);
    return FirestoreDatabaseWrapper._create(
        FirestoreApi(await authClient), await projectId, database);
  }

  CollectionReference collection(String id) =>
      CollectionReference._(this, "$_documentsPath/$id", id);

  DocumentReference doc(String id) =>
      DocumentReference._(this, "$_documentsPath/$id", id);
}

class _Reference {
  final FirestoreDatabaseWrapper _db;
  final String _rootPath;
  final String _path;
  String get path => _path;

  _Reference._(this._db, this._rootPath, this._path);
}

class CollectionReference extends _Reference {
  CollectionReference._(super.db, super.rootPath, super.path) : super._();

  DocumentReference doc(String id) =>
      DocumentReference._(_db, "$_rootPath/$id", "$_path/$id");

  DocumentReference? get parent => _path.parent != null
      ? DocumentReference._(_db, _rootPath.parent!, _path.parent!)
      : null;

  Future<List<DocumentSnapshot>> get(
      {int? limit, (String, FieldOp, Object)? where}) async {
    Filter? filter;

    if (where != null) {
      filter = Filter(
        fieldFilter: FieldFilter(
          field: FieldReference(fieldPath: where.$1),
          op: where.$2.op,
          value: _toValue(where.$3),
        ),
      );
    }

    return _db._documents
        .runQuery(
            RunQueryRequest(
              structuredQuery: StructuredQuery(
                from: [
                  CollectionSelector(collectionId: _path),
                ],
                limit: limit,
                where: filter,
              ),
            ),
            _db._dbPath)
        .then((r) => r
            .map((i) => DocumentSnapshot._(
                doc(
                  i.document!.name!.split("/").last,
                ),
                i.document!))
            .toList());
  }
}

enum FieldOp {
  lessThan,
  lessThanOrEqual,
  greaterThan,
  greaterThanOrEqual,
  equal,
  arrayContains,
}

extension _XFieldOp on FieldOp {
  String get op => switch (this) {
        FieldOp.lessThan => "LESS_THAN",
        FieldOp.lessThanOrEqual => "LESS_THAN_OR_EQUAL",
        FieldOp.greaterThan => "GREATER_THAN",
        FieldOp.greaterThanOrEqual => "GREATER_THAN_OR_EQUAL",
        FieldOp.equal => "EQUAL",
        FieldOp.arrayContains => "ARRAY_CONTAINS",
      };
}

class DocumentSnapshot {
  final DocumentReference ref;
  final Document _doc;

  DocumentSnapshot._(this.ref, this._doc);

  bool get exists => _doc.exists;
  String get id => ref._path.split("/").last;

  Map<String, dynamic> get data => _doc.data!;
}

class DocumentReference extends _Reference {
  DocumentReference._(super.db, super.rootPath, super.path) : super._();

  CollectionReference? get parent => _path.parent != null
      ? CollectionReference._(_db, _rootPath.parent!, _path.parent!)
      : null;

  CollectionReference collection(String id) =>
      CollectionReference._(_db, "$_rootPath/$id", "$_path/$id");

  Future<void> delete() => _db._documents
      .commit(CommitRequest(writes: [Write(delete: path)]), _db._dbPath);

  Future<DocumentSnapshot> get() async {
    try {
      return DocumentSnapshot._(this, await _db._documents.get(path));
    } catch (e) {
      return DocumentSnapshot._(this, Document());
    }
  }

  Future<void> set(Map<String, dynamic> data) => _db._documents.commit(
        CommitRequest(
          writes: [
            Write(
              update: Document(
                name: path,
                fields: data._toValueMap(),
              ),
            ),
          ],
        ),
        _db._dbPath,
      );

  Future<void> updateField(String field, dynamic value) =>
      _db._documents.commit(
        CommitRequest(
          writes: [
            Write(
              update: Document(
                name: path,
                fields: {
                  field: _toValue(value),
                },
              ),
            ),
          ],
        ),
        _db._dbPath,
      );

  Future<void> increment(String field, [int amount = 1]) =>
      _db._documents.commit(
        CommitRequest(
          writes: [
            Write(
              transform: DocumentTransform(
                document: path,
                fieldTransforms: [
                  FieldTransform(
                    fieldPath: field,
                    increment: Value(
                      integerValue: amount.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _db._dbPath,
      );

  Future<void> decrement(String field, [int amount = 1]) =>
      increment(field, -amount);

  Future<void> incrementDouble(String field, [double amount = 1]) =>
      _db._documents.commit(
        CommitRequest(
          writes: [
            Write(
              transform: DocumentTransform(
                document: path,
                fieldTransforms: [
                  FieldTransform(
                    fieldPath: field,
                    increment: Value(
                      doubleValue: amount,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _db._dbPath,
      );

  Future<void> decrementDouble(String field, [double amount = 1]) =>
      incrementDouble(field, -amount);
}

dynamic _fromValue(Value v) {
  if (v.nullValue != null) return null;
  if (v.stringValue != null) return v.stringValue;
  if (v.integerValue != null) return int.tryParse(v.integerValue!) ?? 0;
  if (v.doubleValue != null) return v.doubleValue;
  if (v.booleanValue != null) return v.booleanValue;
  if (v.arrayValue != null) {
    return v.arrayValue?.values?.map(_fromValue).toList();
  }
  if (v.mapValue != null) return v.mapValue?.fields?._toDynamicMap();
  throw Exception("Unsupported type: ${v.toJson()}");
}

Value _toValue(dynamic v) {
  return v == null
      ? Value(nullValue: "NULL_VALUE")
      : switch (v) {
          String _ => Value(stringValue: v),
          int _ => Value(integerValue: v.toString()),
          double _ => Value(doubleValue: v),
          bool _ => Value(booleanValue: v),
          List _ =>
            Value(arrayValue: ArrayValue(values: v.map(_toValue).toList())),
          Map _ => Value(
              mapValue:
                  MapValue(fields: v.map((k, v) => MapEntry(k, _toValue(v))))),
          _ => throw Exception("Unsupported type: ${v.runtimeType}"),
        };
}

extension _XMapStringVal on Map<String, Value> {
  Map<String, dynamic> _toDynamicMap() =>
      map((k, v) => MapEntry(k, _fromValue(v)));
}

extension _XMapStringDyn on Map<String, dynamic> {
  Map<String, Value> _toValueMap() => map((k, v) => MapEntry(k, _toValue(v)));
}

extension _XPathString on String {
  String? get parent => contains("/")
      ? split("/").sublist(0, split("/").length - 1).join("/")
      : null;
}

extension _XDocument on Document {
  bool get exists => fields != null;

  Map<String, dynamic>? get data => fields?._toDynamicMap();
}
