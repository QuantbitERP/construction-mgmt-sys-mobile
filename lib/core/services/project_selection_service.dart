import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectSelectionService extends ChangeNotifier {
  final SharedPreferences _sharedPreferences;

  ProjectSelectionService(this._sharedPreferences);

  String? get selectedSite => _sharedPreferences.getString('last_selected_site');
  String? get selectedProject => _sharedPreferences.getString('last_selected_project_name');

  Future<void> saveSelection({required String site, required String project}) async {
    final currentSite = selectedSite;
    final currentProject = selectedProject;

    await _sharedPreferences.setString('last_selected_site', site);
    await _sharedPreferences.setString('last_selected_project_name', project);

    if (currentSite != site || currentProject != project) {
      notifyListeners();
    }
  }

  Future<void> clearSelection() async {
    await _sharedPreferences.remove('last_selected_site');
    await _sharedPreferences.remove('last_selected_project_name');
    notifyListeners();
  }
}
