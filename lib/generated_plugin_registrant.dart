//
// Generated file. Do not edit.
//

// ignore_for_file: lines_longer_than_80_chars

import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:file_picker/src/file_picker_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_keyboard_visibility_web/flutter_keyboard_visibility_web.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

// ignore: public_member_api_docs
void registerPlugins(Registrar registrar) {
  FirestoreWeb.registerWith(registrar);
  FilePickerWeb.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  FlutterKeyboardVisibilityPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
