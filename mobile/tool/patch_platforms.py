#!/usr/bin/env python3
"""Idempotent platform config on host platforms created by Flutter SDK."""
from pathlib import Path
import re
import plistlib
import os
import shutil

root=Path(__file__).resolve().parent.parent
native_configs=root/'config/firebase'
android_config=native_configs/'google-services.json'
ios_config=native_configs/'GoogleService-Info.plist'
if not android_config.is_file() or not ios_config.is_file():
    raise SystemExit('Required Firebase config files missing from mobile/config/firebase/')
# Both are public client configurations, never FCM service-account private keys.
android_target=root/'android/app/google-services.json'
ios_target=root/'ios/Runner/GoogleService-Info.plist'
if (root/'android/app').exists():
    shutil.copy2(android_config,android_target)
if (root/'ios/Runner').exists():
    shutil.copy2(ios_config,ios_target)
manifest=root/'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    x=manifest.read_text()
    x=x.replace('android:label="school_pdf"','android:label="School PDF"')
    # Mixed audience: deliberately omit Android Advertising ID permission.
    # This prevents AAID for child/unknown users even before age screening.
    # All AdMob requests use non-personalized, age-limited Google inventory.
    # Note: SDK/Play Data Safety declarations must still be audited for older Android.
    if 'xmlns:tools=' not in x:
        x=x.replace('xmlns:android=', 'xmlns:tools="http://schemas.android.com/tools" xmlns:android=',1)
    if 'com.google.android.gms.permission.AD_ID' not in x:
        x=x.replace('<application',
            '<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />\n    <application',1)
    # Android image_picker uses the Android Photo Picker / system selector.
    # Do not request broad Photos/Videos permissions: Play requires a separate
    # high-trust declaration for broad media access that School PDF does not need.
    for permission in [
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VIDEO',
        'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
        'android.permission.READ_EXTERNAL_STORAGE',
    ]:
        marker = f'<uses-permission android:name="{permission}" tools:node="remove" />'
        if marker not in x:
            x = x.replace('<application', marker + '\n    <application', 1)
    before='<application'
    for permission in ['android.permission.INTERNET',
                       'android.permission.POST_NOTIFICATIONS',
                       'android.permission.RECEIVE_BOOT_COMPLETED']:
        tag=f'<uses-permission android:name="{permission}" />'
        if tag not in x: x=x.replace(before,f'{tag}\n    {before}',1)
    # Real public Android App ID can be set in CI. Ads remain OFF unless
    # the age/CMP gates in Dart are explicitly approved in a later release.
    android_app_id=os.environ.get('ADMOB_ANDROID_APP_ID','ca-app-pub-3940256099942544~3347511713')
    app_meta=f'''<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="{android_app_id}" />'''
    firebase_meta='''<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="schoolpdf_updates" />
        <meta-data android:name="firebase_messaging_auto_init_enabled"
            android:value="false" />'''
    if 'com.google.firebase.messaging.default_notification_channel_id' not in x:
        x=x.replace('</application>',f'    {firebase_meta}\n    </application>',1)
    if 'com.google.android.gms.ads.APPLICATION_ID' not in x:
        x=x.replace('</application>',f'    {app_meta}\n    </application>',1)
    rcv='''<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>'''
    if 'ScheduledNotificationReceiver' not in x:
        x=x.replace('</application>',f'    {rcv}\n    </application>',1)
    manifest.write_text(x)

# Add the Google Services Gradle plugin to both Kotlin DSL blocks.
settings_gradle=root/'android/settings.gradle.kts'
if settings_gradle.exists():
    x=settings_gradle.read_text()
    if 'com.google.gms.google-services' not in x:
        x=re.sub(r'(plugins\s*\{)',
            r'\1\n    id("com.google.gms.google-services") version "4.6.0" apply false',x,count=1)
    settings_gradle.write_text(x)

build=root/'android/app/build.gradle.kts'
if build.exists():
    s=build.read_text()
    # Flutter generates the native Android tree in GitHub Actions. Install the
    # checked-in R8 keep rules into that ephemeral tree on every build.
    proguard_source=root/'tool/android_release_proguard_rules.pro'
    if not proguard_source.is_file():
        raise SystemExit('Missing required Room/WorkManager R8 constructor keep rules')
    shutil.copy2(proguard_source,root/'android/app/proguard-rules.pro')
    if 'proguardFiles("proguard-rules.pro")' not in s:
        release_block=re.search(r'(?m)^([ \t]*)release[ \t]*\{',s)
        if release_block is None:
            raise SystemExit('Release block missing: cannot install R8 rules')
        indentation=release_block.group(1)
        insertion='\n'+indentation+'    proguardFiles("proguard-rules.pro")'
        s=s[:release_block.end()]+insertion+s[release_block.end():]
    if 'id("com.google.gms.google-services")' not in s:
        s=re.sub(r'(plugins\s*\{)',
                 r'\1\n    id("com.google.gms.google-services")',s,count=1)
    if 'isCoreLibraryDesugaringEnabled' not in s:
        s=re.sub(r'(compileOptions\s*\{)',
                 r'\1\n        isCoreLibraryDesugaringEnabled = true',s,count=1)
    # Notification plugin 22.x targets compileSdk 36 and Java 17.
    s=re.sub(r'(targetSdk\s*=\s*)flutter.targetSdkVersion',r'\g<1>36',s)
    s=re.sub(r'(compileSdk\s*=\s*)flutter.compileSdkVersion',
             r'\g<1>36',s)
    for old in ('JavaVersion.VERSION_1_8','JavaVersion.VERSION_11'):
        s=s.replace(old,'JavaVersion.VERSION_17')
    s=s.replace('jvmTarget = "1.8"','jvmTarget = "17"')
    s=s.replace('jvmTarget = "11"','jvmTarget = "17"')
    if 'coreLibraryDesugaring(' not in s:
        s+='\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    s=re.sub(r'(minSdk\s*=\s*)flutter.minSdkVersion',r'\g<1>24',s)
    s=re.sub(r'(applicationId\s*=\s*)\"[^\"]+\"',r'\g<1>"com.fiftysols.schoolpdf"',s)
    s=re.sub(r'(namespace\s*=\s*)\"[^\"]+\"',r'\g<1>"com.fiftysols.schoolpdf"',s)
    # Never permit Flutter's generated debug keystore as a Play release signer.
    # AAB CI sets these environment variables from protected repository secrets.
    # Missing keys yield an UNSIGNED candidate explicitly NOT FOR PLAY.
    if 'create("schoolPdfUpload")' not in s:
        match=re.search(r'(?m)^([ \t]*)buildTypes[ \t]*\{',s)
        if not match:
            raise SystemExit('Android release signing block not found')
        indent=match.group(1)
        block='''signingConfigs {
            create("schoolPdfUpload") {
                val keyPath = System.getenv("SCHOOLPDF_UPLOAD_KEYSTORE_FILE")
                if (!keyPath.isNullOrBlank()) {
                    storeFile = file(keyPath)
                    storePassword = System.getenv("SCHOOLPDF_UPLOAD_STORE_PASSWORD")
                    keyAlias = System.getenv("SCHOOLPDF_UPLOAD_KEY_ALIAS")
                    keyPassword = System.getenv("SCHOOLPDF_UPLOAD_KEY_PASSWORD")
                }
            }
        }
        '''
        # insert a clean block boundary, avoiding an invalid concatenated
        # Gradle signingConfigs/buildTypes line.
        s=s[:match.start()]+indent+block.rstrip()+'\n'+s[match.start():]
    s=s.replace('signingConfig = signingConfigs.getByName("debug")',
        'signingConfig = if (System.getenv("SCHOOLPDF_UPLOAD_KEYSTORE_FILE").isNullOrBlank()) null else signingConfigs.getByName("schoolPdfUpload")')
    # Fail closed if a Flutter template changed: no accidental debug-signed AAB.
    if 'getByName("schoolPdfUpload")' not in s:
        raise SystemExit('Release must not use the generated debug signing key')
    build.write_text(s)

pbx=root/'ios/Runner.xcodeproj/project.pbxproj'
if pbx.exists():
    x=pbx.read_text()
    x=re.sub(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;', 'PRODUCT_BUNDLE_IDENTIFIER = com.fiftysols.schoolpdf;', x)
    pbx.write_text(x)

# Flutter create uses the Dart project name school_pdf in the default Kotlin
# package. After overriding applicationId/namespace, move MainActivity too.
for language in ('kotlin','java'):
    for activity in (root/'android/app/src/main'/language).glob('**/MainActivity.*'):
        if activity.parts[-2] == 'schoolpdf': continue
        content=activity.read_text()
        content=re.sub(r'(?m)^package\s+[a-zA-Z0-9_.]+',
                       'package com.fiftysols.schoolpdf',content,count=1)
        target=root/'android/app/src/main'/language/'com/fiftysols/schoolpdf'/activity.name
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(content)
        if target!=activity: activity.unlink()

info=root/'ios/Runner/Info.plist'
if info.exists():
    with info.open('rb') as f: plist=plistlib.load(f)
    background=list(plist.get('UIBackgroundModes',[]))
    if 'remote-notification' not in background:
        background.append('remote-notification')
    plist['UIBackgroundModes']=background
    # Defer Firebase Messaging token creation until the user enables notifications.
    plist['FirebaseMessagingAutoInitEnabled']=False
    plist.update({
        'NSCameraUsageDescription':'Capture homework pages and convert them to PDF.',
        'NSPhotoLibraryUsageDescription':'Select homework photos for PDF conversion.',
        'NSPhotoLibraryAddUsageDescription':'Save exported homework PDFs.',
        'GADApplicationIdentifier':os.environ.get('ADMOB_IOS_APP_ID','ca-app-pub-3940256099942544~1458002511'),
    })
    # Push capability and APNs key still need signing configuration in Xcode/Firebase.
    with info.open('wb') as f: plistlib.dump(plist,f,sort_keys=False)

# A copied plist is not included in the iOS application unless it is added
# to the Xcode Runner target's Resources build phase.
pbx=root/'ios/Runner.xcodeproj/project.pbxproj'
if pbx.exists():
    x=pbx.read_text()
    if 'GoogleService-Info.plist' not in x:
        file_id='F3D7C3A7A1D24B8F9D6B1234'
        build_id='F3D7C3A7A1D24B8F9D6B1235'
        x=x.replace('/* Begin PBXBuildFile section */',
            '/* Begin PBXBuildFile section */\n'+
            f'\t\t{build_id} /* GoogleService-Info.plist in Resources */ = '
            f'{{isa = PBXBuildFile; fileRef = {file_id} /* GoogleService-Info.plist */; }};')
        x=x.replace('/* Begin PBXFileReference section */',
            '/* Begin PBXFileReference section */\n'+
            f'\t\t{file_id} /* GoogleService-Info.plist */ = '
            '{isa = PBXFileReference; lastKnownFileType = text.plist.xml; '
            'path = "GoogleService-Info.plist"; sourceTree = "<group>"; };')
        x,count=re.subn(r'(/\* Runner \*/ = \{\s*isa = PBXGroup;\s*children = \()',
            r'\1\n\t\t\t\t'+file_id+' /* GoogleService-Info.plist */,',x,count=1)
        if count != 1: raise SystemExit('Could not find Runner PBXGroup')
        phase=r'(/\* Begin PBXResourcesBuildPhase section \*/.*?files = \()'
        x,count=re.subn(phase,r'\1\n\t\t\t\t'+build_id+
            ' /* GoogleService-Info.plist in Resources */,',x,count=1,flags=re.S)
        if count != 1: raise SystemExit('Could not find PBXResourcesBuildPhase')
        pbx.write_text(x)

podfile=root/'ios/Podfile'
if podfile.exists():
    s=podfile.read_text()
    s=s.replace("# platform :ios, '13.0'","platform :ios, '15.0'")
    s=s.replace("platform :ios, '13.0'","platform :ios, '15.0'")
    podfile.write_text(s)

print('Native Firebase config, Gradle plugin, Xcode resource and notification channels patched.')


# Register document open-with types on generated Android/iOS projects.
manifest=root/'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    x=manifest.read_text()
    if 'schoolpdf.open.document' not in x:
        intent='''<intent-filter android:label="School PDF">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="content" />
                <data android:scheme="file" />
                <data android:mimeType="application/pdf" />
                <data android:mimeType="application/msword" />
                <data android:mimeType="application/vnd.openxmlformats-officedocument.wordprocessingml.document" />
                <data android:mimeType="application/vnd.ms-excel" />
                <data android:mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" />
                <data android:mimeType="application/vnd.ms-powerpoint" />
                <data android:mimeType="application/vnd.openxmlformats-officedocument.presentationml.presentation" />
                <data android:mimeType="image/jpeg" />
                <data android:mimeType="image/png" />
                <data android:mimeType="image/webp" />
            </intent-filter>
            <!-- schoolpdf.open.document -->'''
        x=x.replace('</activity>',intent+'\n        </activity>',1)
    manifest.write_text(x)

activity=root/'android/app/src/main/kotlin/com/fiftysols/schoolpdf/MainActivity.kt'
if activity.exists():
    activity.write_text('''package com.fiftysols.schoolpdf

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.fiftysols.schoolpdf/open_document"
    private var channel: MethodChannel? = null
    private var pending: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel?.setMethodCallHandler { call, result ->
            if (call.method == "initialDocument") {
                result.success(pending)
                pending = null
            } else result.notImplemented()
        }
        // Cold-start intent is delivered after Dart requests initialDocument.
        receive(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        receive(intent)
    }

    private fun receive(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        try {
            val name = displayName(uri)
            val ext = name.substringAfterLast('.', "").lowercase()
            if (ext !in setOf("pdf","doc","docx","xls","xlsx","ppt","pptx","jpg","jpeg","png","webp")) return
            val target = File.createTempFile("incoming_", ".$ext", cacheDir)
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return
            pending = target.absolutePath
            channel?.invokeMethod("onOpenDocument", target.absolutePath)
        } catch (_: Exception) { /* Do not crash on revoked or malformed provider URIs. */ }
    }

    private fun displayName(uri: Uri): String {
        if (uri.scheme == "content") {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
                if (it.moveToFirst()) return it.getString(0) ?: "unknown"
            }
        }
        return uri.lastPathSegment ?: "unknown"
    }
}
''')

info=root/'ios/Runner/Info.plist'
if info.exists():
    with info.open('rb') as f: plist=plistlib.load(f)
    plist['LSSupportsOpeningDocumentsInPlace']=True
    plist['UIFileSharingEnabled']=True
    plist['CFBundleDocumentTypes']=[{
        'CFBundleTypeName':'School PDF supported documents',
        'CFBundleTypeRole':'Viewer',
        'LSHandlerRank':'Alternate',
        'LSItemContentTypes':[
            'com.adobe.pdf','public.jpeg','public.png','org.webmproject.webp',
            'com.microsoft.word.doc','org.openxmlformats.wordprocessingml.document',
            'com.microsoft.excel.xls','org.openxmlformats.spreadsheetml.sheet',
            'com.microsoft.powerpoint.ppt','org.openxmlformats.presentationml.presentation'
        ]
    }]
    with info.open('wb') as f: plistlib.dump(plist,f,sort_keys=False)

app_delegate=root/'ios/Runner/AppDelegate.swift'
if app_delegate.exists():
    app_delegate.write_text('''import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var incomingChannel: FlutterMethodChannel?
  private var pendingDocument: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    incomingChannel = FlutterMethodChannel(
      name: "com.fiftysols.schoolpdf/open_document",
      binaryMessenger: controller.binaryMessenger)
    incomingChannel?.setMethodCallHandler { [weak self] call, result in
      if call.method == "initialDocument" {
        result(self?.pendingDocument)
        self?.pendingDocument = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let allowed = Set(["pdf","doc","docx","xls","xlsx","ppt","pptx",
                       "jpg","jpeg","png","webp"])
    guard allowed.contains(url.pathExtension.lowercased()) else { return false }
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    do {
      let target = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(url.pathExtension)
      try FileManager.default.copyItem(at: url, to: target)
      pendingDocument = target.path
      incomingChannel?.invokeMethod("onOpenDocument", arguments: target.path)
      return true
    } catch { return false }
  }
}
''')
