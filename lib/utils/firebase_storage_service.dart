import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseStorageService {
  // Firebase project configuration
  static const String _projectId = 'orderit-3e4fb';
  static const String _storageBucket = 'orderit-123';
  static const String _appId = '1:619840286359:android:8baf6ebbea36536604c3d2';

  // Initialize Firebase Storage with specific bucket
  static final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: _storageBucket,
  );

  // List of CSV files to download
  static const List<String> csvFiles = [
    'item.csv',
    'SLD.csv',
    'SBAL.csv',
    'batch.csv'
  ];

  /// Get the local storage directory for CSV files
  static Future<String> getLocalStoragePath() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String csvPath = '${appDocDir.path}/csv_files';

      // Create directory if it doesn't exist
      Directory csvDir = Directory(csvPath);
      if (!await csvDir.exists()) {
        await csvDir.create(recursive: true);
      }

      return csvPath;
    } catch (e) {
      print('Error getting local storage path: $e');
      rethrow;
    }
  }

  /// Download all CSV files from Firebase Storage and save them to local storage
  /// This method is called when the download button is clicked
  static Future<bool> downloadAllCSVFiles() async {
    try {
      bool allDownloadsSuccessful = true;
      String localPath = await getLocalStoragePath();

      for (String fileName in csvFiles) {
        bool success = await downloadCSVFile(fileName);
        if (!success) {
          allDownloadsSuccessful = false;
          print('Failed to download: $fileName');
        } else {
          print('Successfully downloaded: $fileName to $localPath/$fileName');
        }
      }

      return allDownloadsSuccessful;
    } catch (e) {
      print('Error downloading CSV files: $e');
      return false;
    }
  }

  /// Download all CSV files with progress updates
  /// This method provides real-time progress feedback
  static Future<bool> downloadAllCSVFilesWithProgress(
      Function(double) onProgress) async {
    try {
      bool allDownloadsSuccessful = true;
      String localPath = await getLocalStoragePath();
      int totalFiles = csvFiles.length;
      int completedFiles = 0;

      for (String fileName in csvFiles) {
        // Update progress before starting each file
        double progress = completedFiles / totalFiles;
        onProgress(progress);

        bool success = await downloadCSVFile(fileName);
        completedFiles++;

        if (!success) {
          allDownloadsSuccessful = false;
          print('Failed to download: $fileName');
        } else {
          print('Successfully downloaded: $fileName to $localPath/$fileName');
        }

        // Update progress after completing each file
        progress = completedFiles / totalFiles;
        onProgress(progress);
      }

      return allDownloadsSuccessful;
    } catch (e) {
      print('Error downloading CSV files: $e');
      return false;
    }
  }

  /// Download a single CSV file from Firebase Storage to local storage
  /// This method is called when the download button is clicked for a specific file
  static Future<bool> downloadCSVFile(String fileName) async {
    try {
      String localPath = await getLocalStoragePath();
      File localFile = File('$localPath/$fileName');

      // Download file from Firebase Storage
      Reference storageRef = _storage.ref().child('$fileName');
      await storageRef.writeToFile(localFile);

      print('Successfully downloaded: $fileName to $localPath/$fileName');
      return true;
    } catch (e) {
      print('Error downloading $fileName: $e');
      return false;
    }
  }

  /// Get the local file path for a CSV file
  static Future<String> getLocalCSVPath(String fileName) async {
    try {
      String localPath = await getLocalStoragePath();
      String filePath = '$localPath/$fileName';
      File file = File(filePath);

      if (await file.exists()) {
        return filePath;
      } else {
        print('Local file not found: $filePath');
        return '';
      }
    } catch (e) {
      print('Error getting local CSV path: $e');
      return '';
    }
  }

  /// Check if local CSV files exist in local storage
  static Future<bool> checkLocalCSVFilesExist() async {
    try {
      String localPath = await getLocalStoragePath();

      for (String fileName in csvFiles) {
        File file = File('$localPath/$fileName');
        if (!await file.exists()) {
          print('Missing local file: $fileName');
          return false;
        }
      }
      print('All CSV files exist in local storage');
      return true;
    } catch (e) {
      print('Error checking local CSV files: $e');
      return false;
    }
  }

  /// Get local file size
  static Future<int> getLocalFileSize(String fileName) async {
    try {
      String filePath = await getLocalCSVPath(fileName);
      if (filePath.isNotEmpty) {
        File file = File(filePath);
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting local file size for $fileName: $e');
      return 0;
    }
  }

  /// Get file size from Firebase Storage
  static Future<int> getRemoteFileSize(String fileName) async {
    try {
      Reference storageRef = _storage.ref().child('$fileName');
      FullMetadata metadata = await storageRef.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      print('Error getting remote file size for $fileName: $e');
      return 0;
    }
  }

  /// Delete local CSV files
  static Future<bool> deleteLocalCSVFiles() async {
    try {
      String localPath = await getLocalStoragePath();
      bool allDeleted = true;

      for (String fileName in csvFiles) {
        File file = File('$localPath/$fileName');
        if (await file.exists()) {
          await file.delete();
          print('Deleted local file: $fileName');
        }
      }

      return allDeleted;
    } catch (e) {
      print('Error deleting local CSV files: $e');
      return false;
    }
  }

  /// Get Firebase Storage configuration details
  static Map<String, String> getStorageConfig() {
    return {
      'projectId': _projectId,
      'storageBucket': _storageBucket,
      'appId': _appId,
    };
  }

  /// Test Firebase Storage connection
  static Future<bool> testConnection() async {
    try {
      // Try to list files in the root directory
      Reference rootRef = _storage.ref();
      await rootRef.listAll();
      print('Firebase Storage connection successful');
      print('Project ID: $_projectId');
      print('Storage Bucket: $_storageBucket');
      return true;
    } catch (e) {
      print('Firebase Storage connection failed: $e');
      return false;
    }
  }

  /// Get download URL for a file
  static Future<String> getDownloadURL(String fileName) async {
    try {
      Reference storageRef = _storage.ref().child('$fileName');
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error getting download URL for $fileName: $e');
      return '';
    }
  }

  /// Get list of all local CSV files with their paths
  static Future<Map<String, String>> getLocalCSVFiles() async {
    try {
      Map<String, String> files = {};
      String localPath = await getLocalStoragePath();

      for (String fileName in csvFiles) {
        String filePath = '$localPath/$fileName';
        File file = File(filePath);
        if (await file.exists()) {
          files[fileName] = filePath;
        }
      }

      return files;
    } catch (e) {
      print('Error getting local CSV files: $e');
      return {};
    }
  }

  /// Example usage of the Firebase Storage service with local storage
  /// This method demonstrates the complete workflow
  static Future<void> exampleUsage() async {
    try {
      print('=== Firebase Storage Service Example ===');

      // 1. Test connection to Firebase Storage
      bool connected = await testConnection();
      if (!connected) {
        print('Failed to connect to Firebase Storage');
        return;
      }

      // 2. Check if local files exist
      bool filesExist = await checkLocalCSVFilesExist();
      if (!filesExist) {
        print(
            'Local CSV files not found. Use download button to download files.');
      } else {
        print(
            'Local CSV files exist. Use download button to update if needed.');
      }

      // 3. Get local file information
      Map<String, String> localFiles = await getLocalCSVFiles();
      print('Local files: ${localFiles.keys.join(', ')}');

      // 4. Get file sizes for information
      for (String fileName in csvFiles) {
        int localSize = await getLocalFileSize(fileName);
        int remoteSize = await getRemoteFileSize(fileName);
        print(
            '$fileName - Local: ${localSize} bytes, Remote: ${remoteSize} bytes');
      }

      print('=== Example completed successfully ===');
      print(
          'Use downloadAllCSVFiles() or downloadCSVFile(fileName) when download button is clicked');
    } catch (e) {
      print('Error in example usage: $e');
    }
  }

  /// Check if syncing is needed and return status information
  /// Returns a map with syncing status for UI display
  static Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      Map<String, dynamic> status = {
        'needsSync': false,
        'missingFiles': [],
        'existingFiles': [],
        'totalFiles': csvFiles.length,
        'connectionStatus': 'unknown',
      };

      // Check connection
      bool connected = await testConnection();
      status['connectionStatus'] = connected ? 'connected' : 'disconnected';

      if (!connected) {
        status['needsSync'] = true;
        status['missingFiles'] = csvFiles;
        return status;
      }

      // Check local files
      for (String fileName in csvFiles) {
        String localPath = await getLocalCSVPath(fileName);
        if (localPath.isEmpty) {
          status['missingFiles'].add(fileName);
        } else {
          status['existingFiles'].add(fileName);
        }
      }

      status['needsSync'] = status['missingFiles'].isNotEmpty;
      return status;
    } catch (e) {
      print('Error getting sync status: $e');
      return {
        'needsSync': true,
        'missingFiles': csvFiles,
        'existingFiles': [],
        'totalFiles': csvFiles.length,
        'connectionStatus': 'error',
      };
    }
  }

  /// Get sync progress information for UI display
  static Future<Map<String, dynamic>> getSyncProgress() async {
    try {
      Map<String, dynamic> progress = {
        'totalFiles': csvFiles.length,
        'downloadedFiles': 0,
        'failedFiles': [],
        'currentFile': '',
        'isComplete': false,
      };

      for (String fileName in csvFiles) {
        progress['currentFile'] = fileName;
        String localPath = await getLocalCSVPath(fileName);
        if (localPath.isNotEmpty) {
          progress['downloadedFiles']++;
        } else {
          progress['failedFiles'].add(fileName);
        }
      }

      progress['isComplete'] =
          progress['downloadedFiles'] == progress['totalFiles'];
      return progress;
    } catch (e) {
      print('Error getting sync progress: $e');
      return {
        'totalFiles': csvFiles.length,
        'downloadedFiles': 0,
        'failedFiles': csvFiles,
        'currentFile': '',
        'isComplete': false,
      };
    }
  }
}
