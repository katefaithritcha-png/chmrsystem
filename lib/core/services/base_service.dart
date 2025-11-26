import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exceptions.dart';
import '../logging/app_logger.dart';

/// Base service class for all application services
/// Provides common functionality and error handling
abstract class BaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  /// Execute a database operation with error handling
  Future<T> executeDbOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    try {
      AppLogger.debug('Starting operation: $operationName');
      final result = await operation();
      AppLogger.debug('Completed operation: $operationName');
      return result;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error in $operationName: ${e.message}',
          error: e);
      throw DatabaseException(
        message: e.message ?? 'Database operation failed',
        code: e.code,
        originalException: e,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error in $operationName',
          error: e, stackTrace: stackTrace);
      throw UnexpectedException(
        message: 'Operation failed: $operationName',
        originalException: e,
      );
    }
  }

  /// Get a single document
  Future<DocumentSnapshot> getDocument(
    String collection,
    String docId,
  ) async {
    return executeDbOperation(
      () => firestore.collection(collection).doc(docId).get(),
      operationName: 'getDocument($collection/$docId)',
    );
  }

  /// Get multiple documents
  Future<QuerySnapshot> getDocuments(
    String collection, {
    List<QueryConstraint>? constraints,
  }) async {
    return executeDbOperation(
      () async {
        Query query = firestore.collection(collection);
        if (constraints != null) {
          for (final constraint in constraints) {
            query = constraint.apply(query);
          }
        }
        return query.get();
      },
      operationName: 'getDocuments($collection)',
    );
  }

  /// Create a document
  Future<DocumentReference> createDocument(
    String collection,
    Map<String, dynamic> data, {
    String? docId,
  }) async {
    return executeDbOperation(
      () async {
        if (docId != null) {
          await firestore.collection(collection).doc(docId).set(data);
          return firestore.collection(collection).doc(docId);
        }
        return firestore.collection(collection).add(data);
      },
      operationName: 'createDocument($collection)',
    );
  }

  /// Update a document
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    return executeDbOperation(
      () => firestore.collection(collection).doc(docId).update(data),
      operationName: 'updateDocument($collection/$docId)',
    );
  }

  /// Delete a document
  Future<void> deleteDocument(
    String collection,
    String docId,
  ) async {
    return executeDbOperation(
      () => firestore.collection(collection).doc(docId).delete(),
      operationName: 'deleteDocument($collection/$docId)',
    );
  }

  /// Batch write operation
  Future<void> batchWrite(
    Future<void> Function(WriteBatch) operation,
  ) async {
    return executeDbOperation(
      () async {
        final batch = firestore.batch();
        await operation(batch);
        await batch.commit();
      },
      operationName: 'batchWrite',
    );
  }
}

/// Query constraint for building flexible queries
abstract class QueryConstraint {
  Query apply(Query query);
}

/// Where constraint
class WhereConstraint implements QueryConstraint {
  final String field;
  final dynamic value;
  final String? operator;

  WhereConstraint(this.field, this.value, {this.operator});

  @override
  Query apply(Query query) {
    if (operator == '==') {
      return query.where(field, isEqualTo: value);
    } else if (operator == '<') {
      return query.where(field, isLessThan: value);
    } else if (operator == '<=') {
      return query.where(field, isLessThanOrEqualTo: value);
    } else if (operator == '>') {
      return query.where(field, isGreaterThan: value);
    } else if (operator == '>=') {
      return query.where(field, isGreaterThanOrEqualTo: value);
    } else if (operator == '!=') {
      return query.where(field, isNotEqualTo: value);
    } else if (operator == 'in') {
      return query.where(field, whereIn: value);
    } else if (operator == 'array-contains') {
      return query.where(field, arrayContains: value);
    }
    return query.where(field, isEqualTo: value);
  }
}

/// Order constraint
class OrderConstraint implements QueryConstraint {
  final String field;
  final bool descending;

  OrderConstraint(this.field, {this.descending = false});

  @override
  Query apply(Query query) {
    return query.orderBy(field, descending: descending);
  }
}

/// Limit constraint
class LimitConstraint implements QueryConstraint {
  final int limit;

  LimitConstraint(this.limit);

  @override
  Query apply(Query query) {
    return query.limit(limit);
  }
}
