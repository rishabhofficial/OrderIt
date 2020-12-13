package com.example.startup_namer;

import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.StrictMode;

import java.io.File;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


public class MainActivity extends FlutterActivity  {
  private static final String CHANNEL = "team.native.io/openGmail";
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    StrictMode.VmPolicy.Builder builder = null;
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
      builder = new StrictMode.VmPolicy.Builder();
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.GINGERBREAD) {
      StrictMode.setVmPolicy(builder.build());
    }
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
            new MethodCallHandler() {
              @Override
              public void onMethodCall(MethodCall call, Result result) {
                if (call.method.equals("openGmail")) {
                    String fileUri =call.argument("filePath").toString();
                    String subject =call.argument("subject").toString();
                    String mailId = call.argument("mailId");
                    sendMail(Uri.fromFile(new File(fileUri)),subject,mailId);
                    result.success("Done");
                }

              
                else if (call.method.equals("sendWhatsapp")) {
                    String fileUri =call.argument("filePath").toString();
                  //  String message =call.argument("message").toString();
                    sendWhatsapp(Uri.fromFile(new File(fileUri)));
                    result.success("Done");
                }
                else {
                    result.notImplemented();
                }}

    
  }); }
  private void sendMail(Uri filePath, String subject, String mailId){
    Intent intent = new Intent(Intent.ACTION_SEND);
    intent.setType("text/plain");
    intent.putExtra(Intent.EXTRA_EMAIL, mailId);
    intent.putExtra(Intent.EXTRA_SUBJECT, subject);
    intent.putExtra(Intent.EXTRA_STREAM, filePath);
    startActivity(intent);
  }

  private void sendWhatsapp(Uri filePath){
    Intent sendIntent = new Intent();
    sendIntent.setAction(Intent.ACTION_SEND);
   // sendIntent.putExtra(Intent.EXTRA_TEXT, "Message");
    sendIntent.putExtra(Intent.EXTRA_STREAM, filePath);
    sendIntent.setType("application/vnd.ms-excel");
    //sendIntent.setPackage("com.whatsapp");
        startActivity(Intent.createChooser(sendIntent, "Send massage..."));
  }

}