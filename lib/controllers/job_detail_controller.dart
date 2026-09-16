import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/job_catalog_provider.dart';

/// Makes sure one job is in the catalog, and remembers when it can't be.
class JobDetailController extends ChangeNotifier {
  JobDetailController(this.jobId, this._catalog) {
    // Deferred: created during the screen's first build, and fetch() notifies.
    scheduleMicrotask(() {
      if (_catalog.byId(jobId) != null) return;
      _catalog.fetch(jobId).catchError((_) {
        _missing = true;
        notifyListeners();
        return null;
      });
    });
  }

  final String jobId;
  final JobCatalogProvider _catalog;

  bool _missing = false;
  bool get missing => _missing;
}
