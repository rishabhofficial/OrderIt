# Firebase Storage Setup for CSV Downloads

This document explains how to set up Firebase Storage to enable CSV file downloads in the OrderIt app.

## Prerequisites

1. Firebase project already configured for your Flutter app
2. Firebase Storage enabled in your Firebase console

## Setup Instructions

### 1. Firebase Storage Configuration

1. Go to your Firebase Console
2. Navigate to Storage section
3. Create a new storage bucket if you don't have one
4. Set up security rules to allow read access to CSV files

### 2. Storage Security Rules

Add the following security rules to your Firebase Storage:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow read access to CSV files in the csv_files folder
    match /csv_files/{fileName} {
      allow read: if true; // Anyone can read CSV files
    }

    // Deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### 3. Upload CSV Files

1. In Firebase Storage, create a folder named `csv_files`
2. Upload your CSV files to this folder:
   - `ITEM.csv`
   - `SLD.csv`
   - `SBAL.csv`

### 4. File Structure in Firebase Storage

Your Firebase Storage should have this structure:
```
your-bucket/
└── csv_files/
    ├── ITEM.csv
    ├── SLD.csv
    └── SBAL.csv
```

## Usage

### In the App

1. **From Home Screen**:
   - Tap the floating action button (+)
   - Select "Data Management"
   - Tap "Upgrade Data" to download all CSV files

2. **From Profile Screen**:
   - Navigate to Profile
   - Scroll down to "Data Management" section
   - Tap "Upgrade Data" button

### What Happens During Download

1. The app downloads all CSV files from Firebase Storage
2. Files are saved to the app's local storage in an `asset` folder
3. The app automatically uses the downloaded files instead of the bundled assets
4. If download fails, the app falls back to the original bundled CSV files

## Technical Details

### File Storage Location

- **Downloaded files**: `{app_documents_directory}/asset/`
- **Bundled files**: `asset/` folder in the app bundle

### CSV Files Used

1. **ITEM.csv**: Product catalog data
2. **SLD.csv**: Sales data for analytics
3. **SBAL.csv**: Balance data for inventory

### Error Handling

- If download fails, the app shows an error message
- The app continues to work with bundled CSV files
- Network connectivity is required for downloads

## Troubleshooting

### Common Issues

1. **Download fails**: Check internet connection and Firebase Storage rules
2. **Files not updating**: Ensure files are uploaded to the correct `csv_files` folder
3. **Permission errors**: Verify Firebase Storage security rules allow read access

### Debug Information

The app logs download progress and errors to the console. Check the debug output for:
- Download success/failure messages
- File paths where CSV files are saved
- Any Firebase Storage errors

## Security Considerations

- CSV files are publicly readable (as per the security rules above)
- If you need more security, modify the rules to require authentication
- Consider implementing file versioning or timestamps for better data management
