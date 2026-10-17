import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workshop/workshop.dart' as workshop;

/// Port de stockage du Profil de génération (ADR 0008, ADR 0005). La plateforme le
/// stockera plus tard comme donnée opaque ; l'app le porte en attendant.
abstract class ProfileStore {
  Future<workshop.GenerationProfile> load();
  Future<void> save(workshop.GenerationProfile profile);
}

class InMemoryProfileStore implements ProfileStore {
  workshop.GenerationProfile _profile;
  InMemoryProfileStore([this._profile = workshop.GenerationProfile.intuitiveDefaults]);

  @override
  Future<workshop.GenerationProfile> load() async => _profile;

  @override
  Future<void> save(workshop.GenerationProfile profile) async => _profile = profile;
}

class SharedPreferencesProfileStore implements ProfileStore {
  static const _key = 'workshop.profile';

  @override
  Future<workshop.GenerationProfile> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return workshop.GenerationProfile.intuitiveDefaults;
      final profile = workshop.GenerationProfileCodec.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      // Un Profil vide ne peut rien générer : on retombe sur le réglage par défaut.
      return profile.activeFamilies.isEmpty
          ? workshop.GenerationProfile.intuitiveDefaults
          : profile;
    } catch (_) {
      return workshop.GenerationProfile.intuitiveDefaults;
    }
  }

  @override
  Future<void> save(workshop.GenerationProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(profile.toJson()));
    } catch (_) {}
  }
}

/// Garde le Profil de génération courant, le persiste et prévient l'interface. Il doit
/// toujours rester au moins une Famille active (sinon plus aucune Énigme possible).
class WorkshopProfileController extends ChangeNotifier {
  final ProfileStore store;
  workshop.GenerationProfile _profile = workshop.GenerationProfile.intuitiveDefaults;

  WorkshopProfileController(this.store);

  workshop.GenerationProfile get profile => _profile;

  Future<void> load() async {
    _profile = await store.load();
    notifyListeners();
  }

  /// Active ou désactive une Famille. Refuse de désactiver la dernière.
  Future<void> setFamilyActive(workshop.RuleFamily family, bool active) {
    final families = {..._profile.activeFamilies};
    if (active) {
      families.add(family);
    } else {
      families.remove(family);
    }
    return _replace(workshop.GenerationProfile(families));
  }

  Future<void> resetToDefaults() => _replace(workshop.GenerationProfile.intuitiveDefaults);

  Future<void> activateAll() => _replace(workshop.GenerationProfile.allFamilies);

  Future<void> _replace(workshop.GenerationProfile next) async {
    if (next.activeFamilies.isEmpty ||
        next.activeFamilies.length == _profile.activeFamilies.length &&
            next.activeFamilies.containsAll(_profile.activeFamilies)) {
      return;
    }
    _profile = next;
    notifyListeners();
    await store.save(next);
  }
}
