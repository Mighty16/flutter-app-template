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

  for (_DisplayName displayName in config.androidNames) {
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

  for (_DisplayName displayName in config.iOSNames) {
    String slash = Platform.pathSeparator;

    String subPath;
    if (displayName.lang == 'default') {
      subPath = 'InfoPlist.strings';
    } else {
      subPath = '${displayName.lang}.lproj${slash}InfoPlist.strings';
    }

    File infoPlistFile = File('${runnerDir.path}$slash$subPath');

    if (!infoPlistFile.existsSync()) {
      infoPlistFile.createSync(recursive: true);
      String fileContent = 'CFBundleDisplayName = "${displayName.name}";';
      infoPlistFile.writeAsStringSync(fileContent);
    } else {
      List<String> fileContents = infoPlistFile.readAsLinesSync();
      int nameLineIndex = fileContents
          .indexWhere((String line) => line.contains('CFBundleDisplayName'));

      if (nameLineIndex == -1) {
        fileContents.insert(0, 'CFBundleDisplayName = "${displayName.name}";');
        infoPlistFile.writeAsStringSync(fileContents.join('\n'));
        printWarning('Added \'CFBundleDisplayName\' key to $subPath');
      } else {
        String nameLine = fileContents[nameLineIndex];

        int keyLength = 'CFBundleDisplayName'.length;

        int substringStart =
            nameLine.indexOf('CFBundleDisplayName') + keyLength;

        String subString = nameLine.substring(substringStart);

        int currentNameStart = subString.indexOf('"') + 1;
        int currentNameEnd = subString.indexOf('";');

        String currentName =
            subString.substring(currentNameStart, currentNameEnd);

        String updatedNameLine =
            nameLine.replaceAll(currentName, displayName.name);

        fileContents[nameLineIndex] = updatedNameLine;

        infoPlistFile.writeAsString(fileContents.join('\n'));
        printWarning('Changed \'CFBundleDisplayName\' value in $subPath');
      }
    }
  }
  stdout.writeln("✔ iOS app display names configured!");
}

String _getAndroidFileContent(String appName) {
  return '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$appName</string>
</resources>''';
}

class _DisplayNamesConfig {
  final List<_DisplayName> androidNames;
  final List<_DisplayName> iOSNames;

  _DisplayNamesConfig({
    required this.androidNames,
    required this.iOSNames,
  });

  factory _DisplayNamesConfig.fromJson(Map<String, dynamic> json) {
    return _DisplayNamesConfig(
      androidNames:
          _displayNamesFromMap(json['android'] as Map<String, dynamic>),
      iOSNames: _displayNamesFromMap(json['iOS'] as Map<String, dynamic>),
    );
  }

  static List<_DisplayName> _displayNamesFromMap(
      Map<String, dynamic> namesMap) {
    return namesMap.entries
        .map(
          (MapEntry<String, dynamic> entry) =>
              _DisplayName(lang: entry.key, name: entry.value),
        )
        .toList();
  }

  @override
  String toString() {
    StringBuffer buffer = StringBuffer();

    buffer.writeln('{');
    buffer.writeln('  "android":{');
    for (_DisplayName name in androidNames) {
      buffer.writeln('    ${name.toString()},');
    }
    buffer.writeln('  }');
    buffer.writeln('  "iOS":{');
    for (_DisplayName name in iOSNames) {
      buffer.writeln('    ${name.toString()},');
    }
    buffer.writeln('  }');
    buffer.write('}');
    return buffer.toString();
  }
}

class _DisplayName {
  final String lang;
  final String name;

  _DisplayName({
    required this.lang,
    required this.name,
  });

  @override
  String toString() => '"$lang":"$name"';
}
