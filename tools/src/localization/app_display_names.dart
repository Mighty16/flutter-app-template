import 'dart:convert';
import 'dart:io';

import '../tools_common.dart';

void main(List<String> args) async {
  String configPath = args[0];
  File configFile = File(configPath);

  stdout.writeln('Reading display names config file...');
  _DisplayNamesConfig config = await _readConfigFromFile(configFile);

  String scriptPath = Platform.script.toFilePath();
  File scriptFile = File(scriptPath);
  Directory rootDir = getProjectRootDir(scriptFile);
  stdout.writeln('Getting project subfolders...');
  Map<String, Directory> subDirs = getSubDirsAsMap(rootDir);

  _generateAndroidFiles(subDirs['android'], config);
  _generateIosFiles(subDirs['ios'], config);
}

Future<_DisplayNamesConfig> _readConfigFromFile(File configFile) async {
  String fileContent = await configFile.readAsString();
  Map<String, dynamic> jsonMap = json.decode(fileContent);
  return _DisplayNamesConfig.fromJson(jsonMap);
}

void _generateAndroidFiles(Directory? androidDir, _DisplayNamesConfig config) {
  if (androidDir == null) {
    printWarning(
        'Warning: Could not find \'android\' directory. Check supported platforms');
    return;
  }
  stdout.writeln('Generating Android files...');
  Directory resDir =
      androidDir.findDir('app').findDir('src').findDir('main').findDir('res');

  for (_AndroidDisplayName displayName in config.androidNames) {
    String slash = Platform.pathSeparator;

    String subPath = 'values-${displayName.lang}${slash}strings.xml';
    if (displayName.lang == 'default') {
      subPath = 'values${slash}strings.xml';
    } else {
      subPath = 'values-${displayName.lang}${slash}strings.xml';
    }
    File stringsFile = File('${resDir.path}$slash$subPath');

    if (!stringsFile.existsSync()) {
      stringsFile.createSync(recursive: true);
      stringsFile.writeAsStringSync(_getAndroidFileContent(displayName.name));
      stdout.writeln('Created $subPath');
    } else {
      List<String> fileContent = stringsFile.readAsLinesSync();

      int appNameLineIndex = fileContent.indexWhere(
          (String line) => line.contains('<string name="app_name">'));

      if (appNameLineIndex == -1) {
        //We have string.xml but don't have 'app_name' key in it

        int resourcesBeginLineIndex = fileContent
            .indexWhere((String line) => line.contains('<resources>'));

        fileContent.insert(resourcesBeginLineIndex + 1,
            '   <string name="app_name">${displayName.name}</string>');
        stringsFile.writeAsStringSync(fileContent.join('\n'));
        printWarning('Added \'app_name\' key to $subPath');
      } else {
        String appNameLine = fileContent[appNameLineIndex];
        int replaceStart = appNameLine.indexOf('>') + 1;
        int replaceEnd = appNameLine.indexOf('</string>');
        String updatedLine = appNameLine.replaceRange(
            replaceStart, replaceEnd, displayName.name);
        fileContent[appNameLineIndex] = updatedLine;
        stringsFile.writeAsStringSync(fileContent.join('\n'));
        printWarning('Changed \'app_name\' value in $subPath');
      }
    }
  }
  stdout.writeln("✔ Android app display names configured!");
}

void _generateIosFiles(Directory? iOSDir, _DisplayNamesConfig config) {
  if (iOSDir == null) {
    printWarning(
        'Warning: Could not find \'ios\' directory. Check supported platforms');
    return;
  }
  stdout.writeln('Generating iOS files...');

  Directory runnerDir = iOSDir.findDir('Runner');

  for (_IOSStrings iOSStrings in config.iOSNames) {
    String slash = Platform.pathSeparator;

    String subPath;
    if (iOSStrings.lang == 'default') {
      subPath = 'InfoPlist.strings';
    } else {
      subPath = '${iOSStrings.lang}.lproj${slash}InfoPlist.strings';
    }

    File infoPlistFile = File('${runnerDir.path}$slash$subPath');

    if (!infoPlistFile.existsSync()) {
      infoPlistFile.createSync(recursive: true);
      String nameLine = 'CFBundleDisplayName = "${iOSStrings.title}";';

      List<String> lines = [
        nameLine,
        if (iOSStrings.nSPhotoLibraryUsageDescription != null)
          'NSPhotoLibraryUsageDescription = "${iOSStrings.nSPhotoLibraryUsageDescription}";',
        if (iOSStrings.nSCameraUsageDescription != null)
          'NSCameraUsageDescription = "${iOSStrings.nSCameraUsageDescription}";',
        if (iOSStrings.nSMicrophoneUsageDescription != null)
          'NSMicrophoneUsageDescription = "${iOSStrings.nSMicrophoneUsageDescription}";',
        if (iOSStrings.nSLocationWhenInUseUsageDescription != null)
          'NSLocationWhenInUseUsageDescription = "${iOSStrings.nSLocationWhenInUseUsageDescription}";',
        if (iOSStrings.nSLocationAlwaysUsageDescription != null)
          'NSLocationAlwaysUsageDescription = "${iOSStrings.nSLocationAlwaysUsageDescription}";',
        if (iOSStrings.nSLocationAlwaysAndWhenInUseUsageDescription != null)
          'NSLocationAlwaysAndWhenInUseUsageDescription = "${iOSStrings.nSLocationAlwaysAndWhenInUseUsageDescription}";',
      ];

      infoPlistFile.writeAsStringSync(lines.join('\n'));
    } else {
      List<String> fileContents = infoPlistFile.readAsLinesSync();

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'CFBundleDisplayName',
        iOSStrings.title,
      );

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'NSPhotoLibraryUsageDescription',
        iOSStrings.nSPhotoLibraryUsageDescription,
      );

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'NSCameraUsageDescription',
        iOSStrings.nSCameraUsageDescription,
      );

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'NSMicrophoneUsageDescription',
        iOSStrings.nSMicrophoneUsageDescription,
      );

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'NSLocationWhenInUseUsageDescription',
        iOSStrings.nSLocationWhenInUseUsageDescription,
      );

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'NSLocationAlwaysUsageDescription',
        iOSStrings.nSLocationAlwaysUsageDescription,
      );

      _addOrUpdateIOSString(
        fileContents,
        subPath,
        'NSLocationAlwaysAndWhenInUseUsageDescription',
        iOSStrings.nSLocationAlwaysAndWhenInUseUsageDescription,
      );

      infoPlistFile.writeAsStringSync(fileContents.join('\n'));
    }
  }
  stdout.writeln("✔ iOS app display names configured!");
}

void _addOrUpdateIOSString(
    List<String> fileContents, String subPath, String key, String? value) {
  int targetLineIndex =
      fileContents.indexWhere((String line) => line.contains(key));

  if (targetLineIndex == -1) {
    if (value != null) {
      fileContents.insert(fileContents.length, '$key = "$value";');
      printWarning('Added \'CFBundleDisplayName\' key to $subPath');
    }
  } else {
    if (value == null) {
      fileContents.removeAt(targetLineIndex);
      printWarning('Removed \'$key\' value in $subPath');
    } else {
      String nameLine = fileContents[targetLineIndex];

      int keyLength = key.length;
      int substringStart = nameLine.indexOf(key) + keyLength;
      String subString = nameLine.substring(substringStart);

      int currentNameStart = subString.indexOf('"') + 1;
      int currentNameEnd = subString.indexOf('";');

      String currentName =
          subString.substring(currentNameStart, currentNameEnd);
      String updatedNameLine = nameLine.replaceAll(currentName, value);
      fileContents[targetLineIndex] = updatedNameLine;
      printWarning('Changed \'$key\' value in $subPath');
    }
  }
}

String _getAndroidFileContent(String appName) {
  return '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$appName</string>
</resources>''';
}

class _DisplayNamesConfig {
  final List<_AndroidDisplayName> androidNames;
  final List<_IOSStrings> iOSNames;

  _DisplayNamesConfig({
    required this.androidNames,
    required this.iOSNames,
  });

  factory _DisplayNamesConfig.fromJson(Map<String, dynamic> json) {
    return _DisplayNamesConfig(
      androidNames:
          _androidDisplayNamesFromMap(json['android'] as Map<String, dynamic>),
      iOSNames: _iOSStringFromMap(json['iOS'] as Map<String, dynamic>),
    );
  }

  static List<_AndroidDisplayName> _androidDisplayNamesFromMap(
      Map<String, dynamic> namesMap) {
    return namesMap.entries
        .map(
          (MapEntry<String, dynamic> entry) =>
              _AndroidDisplayName(lang: entry.key, name: entry.value),
        )
        .toList();
  }

  static List<_IOSStrings> _iOSStringFromMap(Map<String, dynamic> namesMap) {
    return namesMap.entries.map((MapEntry<String, dynamic> entry) {
      String lang = entry.key;
      Map<String, dynamic> stringsMap = entry.value;

      return _IOSStrings(
        lang: lang,
        title: stringsMap['title'],
        nSPhotoLibraryUsageDescription:
            stringsMap['NSPhotoLibraryUsageDescription'],
        nSCameraUsageDescription: stringsMap['NSCameraUsageDescription'],
        nSMicrophoneUsageDescription:
            stringsMap['NSMicrophoneUsageDescription'],
        nSLocationWhenInUseUsageDescription:
            stringsMap['NSLocationWhenInUseUsageDescription'],
        nSLocationAlwaysUsageDescription:
            stringsMap['NSLocationAlwaysUsageDescription'],
        nSLocationAlwaysAndWhenInUseUsageDescription:
            stringsMap['NSLocationAlwaysAndWhenInUseUsageDescription'],
      );
    }).toList();
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('{');
    buffer.writeln('  "android":{');
    for (_AndroidDisplayName name in androidNames) {
      buffer.writeln('    ${name.toString()},');
    }
    buffer.writeln('  }');
    buffer.writeln('  "iOS":{');
    for (_IOSStrings name in iOSNames) {
      buffer.writeln('    ${name.toString()},');
    }
    buffer.writeln('  }');
    buffer.write('}');
    return buffer.toString();
  }
}

class _IOSStrings {
  final String lang;
  final String title;
  final String? nSPhotoLibraryUsageDescription;
  final String? nSCameraUsageDescription;
  final String? nSMicrophoneUsageDescription;
  final String? nSLocationWhenInUseUsageDescription;
  final String? nSLocationAlwaysUsageDescription;
  final String? nSLocationAlwaysAndWhenInUseUsageDescription;

  _IOSStrings({
    required this.lang,
    required this.title,
    required this.nSPhotoLibraryUsageDescription,
    required this.nSCameraUsageDescription,
    required this.nSMicrophoneUsageDescription,
    required this.nSLocationWhenInUseUsageDescription,
    required this.nSLocationAlwaysUsageDescription,
    required this.nSLocationAlwaysAndWhenInUseUsageDescription,
  });
}

class _AndroidDisplayName {
  final String lang;
  final String name;

  _AndroidDisplayName({
    required this.lang,
    required this.name,
  });

  @override
  String toString() => '"$lang":"$name"';
}
