import 'dart:convert';

import 'package:cartographer/cartographer.dart' as cartographer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port de stockage de la Maîtrise (ADR 0009, ADR 0005). La plateforme la stockera plus tard
/// comme donnée opaque dans le Profil local ; l'app la porte en attendant.
abstract class CartographerMasteryStore {
  Future<cartographer.Mastery> load();
  Future<void> save(cartographer.Mastery mastery);
}

class InMemoryMasteryStore implements CartographerMasteryStore {
  cartographer.Mastery _mastery;
  InMemoryMasteryStore([cartographer.Mastery? mastery]) : _mastery = mastery ?? cartographer.Mastery.empty;

  @override
  Future<cartographer.Mastery> load() async => _mastery;

  @override
  Future<void> save(cartographer.Mastery mastery) async => _mastery = mastery;
}

class SharedPreferencesMasteryStore implements CartographerMasteryStore {
  static const _key = 'cartographer.mastery';

  @override
  Future<cartographer.Mastery> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return cartographer.Mastery.empty;
      return cartographer.MasteryCodec.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Donnée illisible (version inconnue, corruption) : on repart sans Maîtrise plutôt que de planter.
      return cartographer.Mastery.empty;
    }
  }

  @override
  Future<void> save(cartographer.Mastery mastery) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(mastery.toJson()));
    } catch (_) {}
  }
}

/// Garde la Maîtrise courante, la persiste et prévient l'interface.
class CartographerMasteryController extends ChangeNotifier {
  final CartographerMasteryStore store;
  cartographer.Mastery _mastery = cartographer.Mastery.empty;

  CartographerMasteryController(this.store);

  cartographer.Mastery get mastery => _mastery;

  Future<void> load() async {
    _mastery = await store.load();
    notifyListeners();
  }

  Future<void> replace(cartographer.Mastery next) async {
    _mastery = next;
    notifyListeners();
    await store.save(next);
  }

  /// Le joueur repart de zéro sur une Carte de base.
  Future<void> resetBaseMap(String baseMapId) => replace(_mastery.withoutBaseMap(baseMapId));
}

abstract class CartographerProfileStore {
  Future<cartographer.CartographerProfile> load();
  Future<void> save(cartographer.CartographerProfile profile);
}

class InMemoryCartographerProfileStore implements CartographerProfileStore {
  cartographer.CartographerProfile _profile;
  InMemoryCartographerProfileStore([cartographer.CartographerProfile? profile])
    : _profile = profile ?? cartographer.CartographerProfile.defaults();

  @override
  Future<cartographer.CartographerProfile> load() async => _profile;

  @override
  Future<void> save(cartographer.CartographerProfile profile) async => _profile = profile;
}

class SharedPreferencesCartographerProfileStore implements CartographerProfileStore {
  static const _key = 'cartographer.profile';

  @override
  Future<cartographer.CartographerProfile> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return cartographer.CartographerProfile.defaults();
      return cartographer.CartographerProfileCodec.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return cartographer.CartographerProfile.defaults();
    }
  }

  @override
  Future<void> save(cartographer.CartographerProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(profile.toJson()));
    } catch (_) {}
  }
}

/// Garde le Profil courant, le persiste et prévient l'interface. Il doit toujours rester au
/// moins un genre de Lien et une Catégorie (sinon plus aucune question possible).
class CartographerProfileController extends ChangeNotifier {
  final CartographerProfileStore store;
  cartographer.CartographerProfile _profile = cartographer.CartographerProfile.defaults();

  CartographerProfileController(this.store);

  cartographer.CartographerProfile get profile => _profile;

  Future<void> load() async {
    _profile = await store.load();
    notifyListeners();
  }

  /// Active ou désactive un genre de Lien. Refuse de désactiver le dernier.
  Future<void> setKindActive(cartographer.LinkKind kind, bool active) {
    final kinds = {..._profile.linkKinds};
    active ? kinds.add(kind) : kinds.remove(kind);
    if (kinds.isEmpty || (kinds.length == _profile.linkKinds.length && kinds.containsAll(_profile.linkKinds))) {
      return Future.value();
    }
    return _replace(_profile.copyWith(linkKinds: kinds));
  }

  /// Active ou désactive une Catégorie. Refuse de désactiver la dernière.
  Future<void> setCategoryActive(cartographer.Category category, bool active) {
    final categories = {..._profile.categories};
    active ? categories.add(category) : categories.remove(category);
    if (categories.isEmpty || categories.length == _profile.categories.length) return Future.value();
    return _replace(_profile.copyWith(categories: categories));
  }

  Future<void> _replace(cartographer.CartographerProfile next) {
    _profile = next;
    notifyListeners();
    return store.save(next);
  }
}
