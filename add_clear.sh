#!/bin/bash
# JobCatalogProvider
sed -i '' '/class JobCatalogProvider extends ChangeNotifier {/a\
  void clear() { _loaded = false; _all.clear(); _feedLoaded = false; _board.clear(); _boardSample = true; notifyListeners(); }
' lib/providers/job_catalog_provider.dart

# RunProvider
sed -i '' '/class RunProvider extends ChangeNotifier {/a\
  void clear() { _historyLoaded = false; _history.clear(); _active = null; notifyListeners(); }
' lib/providers/run_provider.dart

# PreferencesProvider
sed -i '' '/class PreferencesProvider extends ChangeNotifier {/a\
  void clear() { _loaded = false; _profile = null; notifyListeners(); }
' lib/providers/preferences_provider.dart

# SubscriptionProvider
sed -i '' '/class SubscriptionProvider extends ChangeNotifier {/a\
  void clear() { _loaded = false; _sub = null; notifyListeners(); }
' lib/providers/subscription_provider.dart
