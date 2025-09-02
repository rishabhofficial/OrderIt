// lib/globals.dart
import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:startup_namer/model.dart';
import 'package:startup_namer/utils/firebase_storage_service.dart';

/// Global map
Map<String, ProductData> globalProductMap = {};
List<ProductData> globalProductList = [];
Set<String> compCodeList = {};
Map<String, Map<int, double>> globalFixedSalesData = {};
Map<String, double> globalItemQuantityData = {};
Map<String, ProductData> globalBatchData = {};
List<ProductData> globalBatchList = [];
Map<String, ReportData> globalReportData = {};
Map<String, GlobalPartyData> globalPartyData = {};
List<GlobalPartyData> globalPartyList = [];
Map<String, List<String>> globalBatchPartyCodeMapList = {};
Map<String, ProductData> globalBatchNumberItemCodeMap = {};
Set<String> globalBatchNumberSet = {};
List<String> globalBatchNumberList = [];

class ReportData {
  String icode;
  String name;
  String pack;
  String compCode;
  DateTime startDate;
  DateTime endDate;
  double openStock;
  double purchaseStock;
  double soldStock;
  double remainingStock;
  ReportData({
    this.icode,
    this.name,
    this.pack,
    this.compCode,
    this.startDate,
    this.endDate,
    this.openStock,
    this.purchaseStock,
    this.soldStock,
    this.remainingStock,
  });
  toJson() {
    return {
      'icode': icode,
      'name': name,
      'pack': pack,
      'compCode': compCode,
      'startDate': startDate,
      'endDate': endDate,
      'openStock': openStock,
      'purchaseStock': purchaseStock,
      'soldStock': soldStock,
      'remainingStock': remainingStock,
    };
  }
}

class GlobalPartyData {
  String partyCode;
  String partyType;
  String partyName;
  String partyLocation;
  GlobalPartyData({
    this.partyCode,
    this.partyType,
    this.partyName,
    this.partyLocation,
  });
  toJson() {
    return {
      'partyCode': partyCode,
      'partyType': partyType,
      'partyName': partyName,
      'partyLocation': partyLocation,
    };
  }
}

/// Load all CSV data in parallel
Future<bool> loadAllCSVData() async {
  globalProductMap = {};
  globalProductList = [];
  compCodeList = {};
  globalFixedSalesData = {};
  globalItemQuantityData = {};
  globalBatchData = {};
  globalBatchList = [];
  globalReportData = {};
  globalPartyData = {};
  globalPartyList = [];
  globalBatchNumberItemCodeMap = {};
  globalBatchNumberSet = {};
  globalBatchPartyCodeMapList = {};
  globalBatchNumberList = [];
  try {
    final results = await Future.wait([
      _loadItemCSV(),
      _loadSLDCSV(),
      _loadSBALCSV(),
      _loadACTCSV(),
    ]);

    await _loadHISTCSV();

    // If all results are true, return true
    return results.every((r) => r == true);
  } catch (e) {
    print('Error in loadAllCSVData: $e');
    return false;
  }
}

/// Internal: Load item.csv
Future<bool> _loadItemCSV() async {
  try {
    String csvPath = await FirebaseStorageService.getLocalCSVPath('item.csv');

    if (csvPath.isEmpty) {
      print('Local item.csv not found. Attempting to download...');
      bool downloaded =
          await FirebaseStorageService.downloadCSVFile('item.csv');
      if (!downloaded) return false;
      csvPath = await FirebaseStorageService.getLocalCSVPath('item.csv');
      if (csvPath.isEmpty) return false;
    }

    File file = File(csvPath);
    String rawData = await file.readAsString();
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

    for (int i = 1; i < listData.length; i++) {
      String key = listData[i][0].toString();
      ProductData value = ProductData(
        icode: listData[i][0].toString(),
        name: listData[i][1].toString(),
        pack: listData[i][3].toString(),
        division: listData[i][28].toString(),
        compCode: listData[i][2].toString(),
      );
      globalProductMap[key] = value;
      globalProductList.add(value);
      if (value.compCode == 'MAN' || value.compCode == 'ARI') {
        compCodeList.add('${value.compCode}-${value.division}');
      }
    }
    globalProductList.sort((a, b) => a.name.compareTo(b.name));
    print('Successfully loaded item.csv');
    return true;
  } catch (e) {
    print('Error loading item.csv: $e');
    return false;
  }
}

/// Internal: Load SLD.csv
Future<bool> _loadSLDCSV() async {
  try {
    String csvPath = await FirebaseStorageService.getLocalCSVPath('SLD.csv');

    if (csvPath.isEmpty) {
      print('Local SLD.csv not found. Attempting to download...');
      bool downloaded = await FirebaseStorageService.downloadCSVFile('SLD.csv');
      if (!downloaded) return false;
      csvPath = await FirebaseStorageService.getLocalCSVPath('SLD.csv');
      if (csvPath.isEmpty) return false;
    }

    File file = File(csvPath);
    String rawData = await file.readAsString();
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

    for (int i = 1; i < listData.length; i++) {
      final type = listData[i][13].toString();
      if (type != "S") continue;

      final dateString = listData[i][1].toString().trim();
      if (dateString.isEmpty) {
        continue; // Skip rows with empty dates
      }
      DateTime date;
      try {
        date = DateFormat("dd-MM-yyyy").parse(dateString);
      } catch (e) {
        print('Skipping row $i with invalid date format: $dateString');
        continue; // Skip rows with invalid date formats
      }
      final icode = listData[i][3].toString();
      final count = double.parse(listData[i][5].toString()) +
          double.parse(listData[i][6].toString());
      final totalDaysFromToday = date.difference(DateTime.now()).inDays;

      if (!globalFixedSalesData.containsKey(icode)) {
        globalFixedSalesData[icode] = {7: 0, 10: 0, 15: 0, 20: 0, 30: 0};
      }

      if (totalDaysFromToday * -1 <= 7) {
        globalFixedSalesData[icode][7] = globalFixedSalesData[icode][7] + count;
        globalFixedSalesData[icode][10] =
            globalFixedSalesData[icode][10] + count;
        globalFixedSalesData[icode][15] =
            globalFixedSalesData[icode][15] + count;
        globalFixedSalesData[icode][20] =
            globalFixedSalesData[icode][20] + count;
        globalFixedSalesData[icode][30] =
            globalFixedSalesData[icode][30] + count;
      } else if (totalDaysFromToday * -1 <= 10) {
        globalFixedSalesData[icode][10] =
            globalFixedSalesData[icode][10] + count;
        globalFixedSalesData[icode][15] =
            globalFixedSalesData[icode][15] + count;
        globalFixedSalesData[icode][20] =
            globalFixedSalesData[icode][20] + count;
        globalFixedSalesData[icode][30] =
            globalFixedSalesData[icode][30] + count;
      } else if (totalDaysFromToday * -1 <= 15) {
        globalFixedSalesData[icode][15] =
            globalFixedSalesData[icode][15] + count;
        globalFixedSalesData[icode][20] =
            globalFixedSalesData[icode][20] + count;
        globalFixedSalesData[icode][30] =
            globalFixedSalesData[icode][30] + count;
      } else if (totalDaysFromToday * -1 <= 20) {
        globalFixedSalesData[icode][20] =
            globalFixedSalesData[icode][20] + count;
        globalFixedSalesData[icode][30] =
            globalFixedSalesData[icode][30] + count;
      } else if (totalDaysFromToday * -1 <= 30) {
        globalFixedSalesData[icode][30] =
            globalFixedSalesData[icode][30] + count;
      }
    }
    print('Successfully loaded SLD.csv');
    return true;
  } catch (e) {
    print('Error loading SLD.csv: $e');
    return false;
  }
}

/// Internal: Load SBAL.csv
Future<bool> _loadSBALCSV() async {
  try {
    String csvPath = await FirebaseStorageService.getLocalCSVPath('SBAL.csv');

    if (csvPath.isEmpty) {
      print('Local SBAL.csv not found. Attempting to download...');
      bool downloaded =
          await FirebaseStorageService.downloadCSVFile('SBAL.csv');
      if (!downloaded) return false;
      csvPath = await FirebaseStorageService.getLocalCSVPath('SBAL.csv');
      if (csvPath.isEmpty) return false;
    }

    File file = File(csvPath);
    String rawData = await file.readAsString();
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

    for (int i = 1; i < listData.length; i++) {
      final icode = listData[i][0].toString();
      final op = double.parse(listData[i][5].toString());
      final rp = double.parse(listData[i][6].toString());
      final ip = double.parse(listData[i][7].toString());
      final quantity = op + rp - ip;

      if (!globalItemQuantityData.containsKey(icode)) {
        globalItemQuantityData[icode] = 0;
      }
      globalItemQuantityData[icode] = globalItemQuantityData[icode] + quantity;
    }
    print('Successfully loaded SBAL.csv');
    return true;
  } catch (e) {
    print('Error loading SBAL.csv: $e');
    return false;
  }
}

// add function to load ACT.csv
Future<bool> _loadACTCSV() async {
  try {
    String csvPath = await FirebaseStorageService.getLocalCSVPath('ACT.csv');
    if (csvPath.isEmpty) {
      print('Local ACT.csv not found. Attempting to download...');
      bool downloaded = await FirebaseStorageService.downloadCSVFile('ACT.csv');

      if (!downloaded) return false;
      csvPath = await FirebaseStorageService.getLocalCSVPath('ACT.csv');
      if (csvPath.isEmpty) return false;
    }

    File file = File(csvPath);
    String rawData = await file.readAsString();

    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

    for (int i = 1; i < listData.length; i++) {
      final partyCode = listData[i][0].toString();
      final partyType = listData[i][1].toString();
      if (partyType != "P") continue;
      final partyName = listData[i][2].toString();
      final partyLocation = listData[i][4].toString();
      globalPartyData[partyCode] = GlobalPartyData(
        partyCode: partyCode,
        partyType: partyType,
        partyName: partyName,
        partyLocation: partyLocation,
      );
      globalPartyList.add(globalPartyData[partyCode]);
    }
    globalPartyList.sort((a, b) => a.partyName.compareTo(b.partyName));
    print('Successfully loaded globalPartyList.csv');

    print('Successfully loaded ACT.csv');
    return true;
  } catch (e) {
    print('Error loading ACT.csv: $e');
    return false;
  }
}

// Download and load 4 files HIST2223.csv, HIST2324.csv, HIST2425.csv, HIST2526.csv in parallel
Future<bool> _loadHISTCSV() async {
  print("DEBUG: Starting _loadHISTCSV function");
  try {
    List<String> histFiles = [
      'HIST2223.csv',
      'HIST2324.csv',
      'HIST2425.csv',
      'HIST2526.csv'
    ];

    // Download all files in parallel
    List<Future<bool>> downloadTasks = histFiles.map((fileName) async {
      String csvPath = await FirebaseStorageService.getLocalCSVPath(fileName);
      if (csvPath.isEmpty) {
        print('Local $fileName not found. Attempting to download...');
        bool downloaded =
            await FirebaseStorageService.downloadCSVFile(fileName);
        if (!downloaded) {
          print('Failed to download $fileName');
          return false;
        }
        csvPath = await FirebaseStorageService.getLocalCSVPath(fileName);
        if (csvPath.isEmpty) {
          print('Failed to get local path for $fileName after download');
          return false;
        }
      }
      return true;
    }).toList();

    // Wait for all downloads to complete
    List<bool> downloadResults = await Future.wait(downloadTasks);

    // Check if all downloads were successful
    if (!downloadResults.every((result) => result)) {
      print('Some HIST files failed to download');
      return false;
    }

    // Load all files in parallel
    List<Future<bool>> loadTasks = histFiles.map((fileName) async {
      try {
        String csvPath = await FirebaseStorageService.getLocalCSVPath(fileName);
        File file = File(csvPath);
        String rawData = await file.readAsString();
        List<List<dynamic>> listData =
            const CsvToListConverter().convert(rawData);

        // Process the data for this file
        for (int i = 1; i < listData.length; i++) {
          // Add your data processing logic here
          // For example, you might want to store this data in a global map or list
          // based on the file name or content
          final DataType = listData[i][13].toString();
          if (DataType != "S") continue;
          final PartyCode = listData[i][2].toString();
          final ItemCode = listData[i][3].toString();
          final BatchNumber = listData[i][4].toString();
          final dateString = listData[i][8].toString().trim();
          if (dateString.isEmpty) {
            continue; // Skip rows with empty expiry dates
          }
          DateTime ExpDate;
          try {
            ExpDate = DateFormat("dd-MM-yyyy").parse(dateString);
          } catch (e) {
            print('Skipping row $i with invalid date format: $dateString');
            continue; // Skip rows with invalid date formats
          }
          final MRP = double.parse(listData[i][15].toString());

          if (!globalBatchNumberItemCodeMap.containsKey(BatchNumber)) {
            globalBatchNumberItemCodeMap[BatchNumber] = ProductData(
              icode: ItemCode,
              name: globalProductMap[ItemCode]?.name ?? '',
              pack: globalProductMap[ItemCode]?.pack ?? '',
              compCode: globalProductMap[ItemCode]?.compCode ?? '',
              division: globalProductMap[ItemCode]?.division ?? '',
              expiryDate: ExpDate.toString(),
              mrp: MRP,
              batchNumber: BatchNumber,
              deal1: globalProductMap[ItemCode]?.deal1 ?? 0,
              deal2: globalProductMap[ItemCode]?.deal2 ?? 0,
            );
          }
          globalBatchNumberSet.add(BatchNumber);
          if (!globalBatchPartyCodeMapList.containsKey(BatchNumber)) {
            globalBatchPartyCodeMapList[BatchNumber] = [];
          }
          globalBatchPartyCodeMapList[BatchNumber].add(PartyCode);
        }
        print("length of batch list" +
            globalBatchPartyCodeMapList.length.toString());

        // sort globalBatchNumberSet
        globalBatchNumberList = globalBatchNumberSet.toList();
        globalBatchNumberList.sort((a, b) => a.compareTo(b));

        print('Successfully loaded $fileName');
        return true;
      } catch (e) {
        print('Error loading $fileName: $e');
        return false;
      }
    }).toList();

    // Wait for all files to be loaded
    List<bool> loadResults = await Future.wait(loadTasks);

    // Check if all files were loaded successfully
    if (!loadResults.every((result) => result)) {
      print('Some HIST files failed to load');
      return false;
    }

    print('DEBUG: Successfully loaded all HIST files in parallel');
    print(
        'DEBUG: Final globalBatchPartyCodeMapList size: ${globalBatchPartyCodeMapList.length}');
    return true;
  } catch (e) {
    print('Error in _loadHISTCSV: $e');
    return false;
  }
}

// read sbal for a time range and get listData[i][6].toString() and listData[i][7].toString() for a date range
Future<bool> loadSBALCSVForDateRange(
    DateTime startDate, DateTime endDate) async {
  try {
    String csvPath = await FirebaseStorageService.getLocalCSVPath('SBAL.csv');
    if (csvPath.isEmpty) {
      print('Local SBAL.csv not found. Attempting to download...');
      bool downloaded =
          await FirebaseStorageService.downloadCSVFile('SBAL.csv');
      if (!downloaded) return false;
      csvPath = await FirebaseStorageService.getLocalCSVPath('SBAL.csv');
      if (csvPath.isEmpty) return false;
    }
    File file = File(csvPath);
    String rawData = await file.readAsString();
    List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
    for (int i = 1; i < listData.length; i++) {
      try {
        final dateString = listData[i][1].toString().trim();
        if (dateString.isEmpty || dateString == '-') {
          continue; // Skip rows with empty or invalid dates
        }

        DateTime date;
        try {
          // Try the expected format first
          date = DateFormat("dd-MM-yyyy").parse(dateString);
        } catch (formatException) {
          // If that fails, try alternative formats
          try {
            date = DateFormat("dd/MM/yyyy").parse(dateString);
          } catch (formatException2) {
            try {
              date = DateFormat("yyyy-MM-dd").parse(dateString);
            } catch (formatException3) {
              // If all formats fail, skip this row
              print('Skipping row $i with invalid date format: $dateString');
              continue;
            }
          }
        }

        if (date.isAfter(startDate) && date.isBefore(endDate)) {
          if (!globalReportData.containsKey(listData[i][0].toString())) {
            globalReportData[listData[i][0].toString()] = ReportData(
              icode: listData[i][0].toString(),
              name: globalProductMap[listData[i][0].toString()]?.name ??
                  'Unknown',
              pack: globalProductMap[listData[i][0].toString()]?.pack ?? '',
              compCode:
                  globalProductMap[listData[i][0].toString()]?.compCode ?? '',
            );
          }

          // Safely parse numeric values
          double purchaseStock = 0;
          double soldStock = 0;

          try {
            purchaseStock = double.parse(listData[i][6].toString());
          } catch (e) {
            purchaseStock = 0;
          }

          try {
            soldStock = double.parse(listData[i][7].toString());
          } catch (e) {
            soldStock = 0;
          }

          globalReportData[listData[i][0].toString()].purchaseStock =
              globalReportData[listData[i][0].toString()].purchaseStock +
                  purchaseStock;
          globalReportData[listData[i][0].toString()].soldStock =
              globalReportData[listData[i][0].toString()].soldStock + soldStock;
          globalReportData[listData[i][0].toString()].remainingStock =
              globalItemQuantityData[listData[i][0].toString()] ?? 0;
          globalReportData[listData[i][0].toString()].openStock =
              globalReportData[listData[i][0].toString()].soldStock +
                  globalReportData[listData[i][0].toString()].remainingStock -
                  globalReportData[listData[i][0].toString()].purchaseStock;

          globalReportData[listData[i][0].toString()].startDate = startDate;
          globalReportData[listData[i][0].toString()].endDate = endDate;
        }
      } catch (rowError) {
        print('Error processing row $i: $rowError');
        continue; // Skip this row and continue with the next
      }
    }
    print('Successfully loaded SBAL.csv for date range');
    return true;
  } catch (e) {
    print('Error loading SBAL.csv for date range: $e');
    return false;
  }
}

List<ReportData> getReportData(String compCode) {
  return globalReportData.values
      .where((report) => report.compCode == compCode)
      .toList();
}
