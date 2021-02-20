import 'package:invoiceninja_flutter/redux/static/static_state.dart';
import 'package:memoize/memoize.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';

var memoizedDropdownVendorList = memo4(
    (BuiltMap<String, VendorEntity> vendorMap, BuiltList<String> vendorList,
            BuiltMap<String, UserEntity> userMap, StaticState staticState) =>
        dropdownVendorsSelector(vendorMap, vendorList, userMap, staticState));

List<String> dropdownVendorsSelector(
    BuiltMap<String, VendorEntity> vendorMap,
    BuiltList<String> vendorList,
    BuiltMap<String, UserEntity> userMap,
    StaticState staticState) {
  final list = vendorList.where((vendorId) {
    final vendor = vendorMap[vendorId];
    return vendor.isActive;
  }).toList();

  list.sort((vendorAId, vendorBId) {
    final vendorA = vendorMap[vendorAId];
    final vendorB = vendorMap[vendorBId];
    return vendorA.compareTo(
        vendorB, VendorFields.name, true, userMap, staticState);
  });

  return list;
}

var memoizedFilteredVendorList = memo5(
    (BuiltMap<String, VendorEntity> vendorMap,
            BuiltList<String> vendorList,
            ListUIState vendorListState,
            BuiltMap<String, UserEntity> userMap,
            StaticState staticState) =>
        filteredVendorsSelector(
            vendorMap, vendorList, vendorListState, userMap, staticState));

List<String> filteredVendorsSelector(
    BuiltMap<String, VendorEntity> vendorMap,
    BuiltList<String> vendorList,
    ListUIState vendorListState,
    BuiltMap<String, UserEntity> userMap,
    StaticState staticState) {
  final list = vendorList.where((vendorId) {
    final vendor = vendorMap[vendorId];

    if (!vendor.matchesStates(vendorListState.stateFilters)) {
      return false;
    }

    if (vendorListState.custom1Filters.isNotEmpty &&
        !vendorListState.custom1Filters.contains(vendor.customValue1)) {
      return false;
    }

    if (vendorListState.custom2Filters.isNotEmpty &&
        !vendorListState.custom2Filters.contains(vendor.customValue2)) {
      return false;
    }

    return vendor.matchesFilter(vendorListState.filter);
  }).toList();

  list.sort((vendorAId, vendorBId) {
    final vendorA = vendorMap[vendorAId];
    final vendorB = vendorMap[vendorBId];
    return vendorA.compareTo(vendorB, vendorListState.sortField,
        vendorListState.sortAscending, userMap, staticState);
  });

  return list;
}

var memoizedVendorStatsForUser = memo2(
    (String userId, BuiltMap<String, VendorEntity> vendorMap) =>
        vendorStatsForUser(userId, vendorMap));

EntityStats vendorStatsForUser(
    String userId, BuiltMap<String, VendorEntity> vendorMap) {
  int countActive = 0;
  int countArchived = 0;
  vendorMap.forEach((vendorId, vendor) {
    if (vendor.assignedUserId == userId) {
      if (vendor.isActive) {
        countActive++;
      } else if (vendor.isArchived) {
        countArchived++;
      }
    }
  });

  return EntityStats(countActive: countActive, countArchived: countArchived);
}

var memoizedCalculateVendorBalance = memo4((String vendorId,
        String currencyId,
        BuiltMap<String, ExpenseEntity> expenseMap,
        BuiltList<String> expenseList) =>
    calculateVendorBalance(vendorId, currencyId, expenseMap, expenseList));

double calculateVendorBalance(String vendorId, String currencyId,
    BuiltMap<String, ExpenseEntity> expenseMap, BuiltList<String> expenseList) {
  double total = 0;

  expenseList.forEach((expenseId) {
    final expense = expenseMap[expenseId] ?? ExpenseEntity();
    if (expense.vendorId == vendorId &&
        expense.isActive &&
        (currencyId == null || expense.currencyId == currencyId)) {
      total += expense.grossAmount;
    }
  });

  return total;
}

bool hasVendorChanges(
        VendorEntity vendor, BuiltMap<String, VendorEntity> vendorMap) =>
    vendor.isNew ? vendor.isChanged : vendor != vendorMap[vendor.id];
