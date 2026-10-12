import 'dart:io';

void main() async {
  // 1. Remove test directory
  final testDir = Directory('test');
  if (testDir.existsSync()) {
    testDir.deleteSync(recursive: true);
    print('Deleted test directory');
  }

  // 2. Patch AndroidManifest.xml
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    print('Error: $manifestPath not found');
    exit(1);
  }
  String m = manifestFile.readAsStringSync();

  const perms = '''    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
''';
  if (!m.contains('POST_NOTIFICATIONS')) {
    m = m.replaceFirst('<application', '$perms    <application');
  }

  m = m.replaceAll(RegExp(r'android:label="[^"]*"'), 'android:label="Home Gardening"');

  const receivers = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';
  if (!m.contains('ScheduledNotificationReceiver')) {
    m = m.replaceFirst('</application>', '$receivers    </application>');
  }

  const httpsQ = '''        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
''';
  if (m.contains('</queries>') && !m.contains('android:scheme="https"')) {
    m = m.replaceFirst('</queries>', '$httpsQ    </queries>');
  } else if (!m.contains('</queries>')) {
    const queriesBlock = '''    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
    </queries>
''';
    m = m.replaceFirst('</manifest>', '$queriesBlock</manifest>');
  }

  manifestFile.writeAsStringSync(m);
  print('manifest patched');

  // 3. Patch build.gradle.kts
  const ktsPath = 'android/app/build.gradle.kts';
  const grvPath = 'android/app/build.gradle';
  String p;
  bool isKts;
  if (File(ktsPath).existsSync()) {
    p = ktsPath;
    isKts = true;
  } else if (File(grvPath).existsSync()) {
    p = grvPath;
    isKts = false;
  } else {
    print('Error: No app build.gradle found');
    exit(1);
  }

  final gradleFile = File(p);
  String g = gradleFile.readAsStringSync();

  const ksRel = '../../keystore/home_gardening.p12';
  if (isKts) {
    if (!g.contains('isCoreLibraryDesugaringEnabled')) {
      g = g.replaceFirst('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    }
    const signing = '''    signingConfigs {
        create("release") {
            storeFile = file("$ksRel")
            storePassword = "homegarden123"
            keyAlias = "home_gardening"
            keyPassword = "homegarden123"
            storeType = "pkcs12"
        }
    }

''';
    if (!g.contains('signingConfigs')) {
      g = g.replaceFirst('buildTypes {', '$signing    buildTypes {');
    }
    g = g.replaceAll('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = signingConfigs.getByName("release")');
    if (!g.contains('coreLibraryDesugaring')) {
      g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
    }
  } else {
    if (!g.contains('coreLibraryDesugaringEnabled')) {
      g = g.replaceFirst('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    }
    const signing = '''    signingConfigs {
        release {
            storeFile file("$ksRel")
            storePassword "homegarden123"
            keyAlias "home_gardening"
            keyPassword "homegarden123"
            storeType "pkcs12"
        }
    }

''';
    if (!g.contains('signingConfigs')) {
      g = g.replaceFirst('buildTypes {', '$signing    buildTypes {');
    }
    g = g.replaceAll('signingConfig signingConfigs.debug', 'signingConfig signingConfigs.release');
    if (!g.contains('coreLibraryDesugaring')) {
      g += '\ndependencies {\n    coreLibraryDesugaring \'com.android.tools:desugar_jdk_libs:2.1.4\'\n}\n';
    }
  }

  gradleFile.writeAsStringSync(g);
  print('gradle patched: $p');
}
