"""Patches the generated Android project:
   * permissions + notification receivers + app label + https query in AndroidManifest.xml
   * core library desugaring (needed by flutter_local_notifications)
   * release signing with the bundled keystore (so updates install over older versions)
"""
import os, re, sys

MANIFEST = 'android/app/src/main/AndroidManifest.xml'
m = open(MANIFEST, encoding='utf-8').read()

perms = '''    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
'''
if 'POST_NOTIFICATIONS' not in m:
    m = m.replace('<application', perms + '    <application', 1)

m = re.sub(r'android:label="[^"]*"', 'android:label="Home Gardening"', m, count=1)

receivers = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
if 'ScheduledNotificationReceiver' not in m:
    m = m.replace('</application>', receivers + '    </application>', 1)

https_q = '''        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
'''
if '</queries>' in m and 'android:scheme="https"' not in m:
    m = m.replace('</queries>', https_q + '    </queries>', 1)
open(MANIFEST, 'w', encoding='utf-8').write(m)
print('manifest patched')

# ---------------- gradle ----------------
kts = 'android/app/build.gradle.kts'
grv = 'android/app/build.gradle'
if os.path.exists(kts):
    p, is_kts = kts, True
elif os.path.exists(grv):
    p, is_kts = grv, False
else:
    sys.exit('No app build.gradle found')
g = open(p, encoding='utf-8').read()

KS_REL = '../../keystore/home_gardening.p12'
if is_kts:
    g = re.sub(r'(compileOptions\s*\{)', r'\1\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
    signing = f'''    signingConfigs {{
        create("release") {{
            storeFile = file("{KS_REL}")
            storePassword = "homegarden123"
            keyAlias = "home_gardening"
            keyPassword = "homegarden123"
            storeType = "pkcs12"
        }}
    }}

'''
    g = g.replace('buildTypes {', signing + '    buildTypes {', 1)
    g = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)', 'signingConfig = signingConfigs.getByName("release")', g)
    g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
else:
    g = re.sub(r'(compileOptions\s*\{)', r'\1\n        coreLibraryDesugaringEnabled true', g, count=1)
    signing = f'''    signingConfigs {{
        release {{
            storeFile file("{KS_REL}")
            storePassword "homegarden123"
            keyAlias "home_gardening"
            keyPassword "homegarden123"
            storeType "pkcs12"
        }}
    }}

'''
    g = g.replace('buildTypes {', signing + '    buildTypes {', 1)
    g = re.sub(r'signingConfig\s+signingConfigs\.debug', 'signingConfig signingConfigs.release', g)
    g += '\ndependencies {\n    coreLibraryDesugaring \'com.android.tools:desugar_jdk_libs:2.1.4\'\n}\n'
open(p, 'w', encoding='utf-8').write(g)
print('gradle patched:', p)
