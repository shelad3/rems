import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/vendor.dart';

class VendorProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Vendor> _vendors = [];
  bool _isLoading = false;

  List<Vendor> get vendors => _vendors;
  bool get isLoading => _isLoading;

  Future<void> loadVendors() async {
    _isLoading = true;
    notifyListeners();
    final maps = await _db.queryAll('vendors');
    _vendors = maps.map((m) => Vendor.fromMap(m)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<int> addVendor(Vendor vendor) async {
    final id = await _db.insert('vendors', vendor.toMap());
    await loadVendors();
    return id;
  }

  Future<void> updateVendor(Vendor vendor) async {
    await _db.update('vendors', vendor.toMap(), vendor.id!);
    await loadVendors();
  }

  Future<void> deleteVendor(int id) async {
    await _db.delete('vendors', id);
    await loadVendors();
  }

  List<Vendor> searchVendors(String query) {
    final q = query.toLowerCase();
    return _vendors.where((v) =>
      v.name.toLowerCase().contains(q) ||
      v.category.toLowerCase().contains(q) ||
      v.phone.contains(q)
    ).toList();
  }

  List<Vendor> getVendorsByCategory(String category) {
    return _vendors.where((v) => v.category == category).toList();
  }
}
