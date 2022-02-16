import 'dart:convert';
import 'dart:io';

import '../tools_common.dart';

const _androidAppId = 'applicationId';

void main(List<String> arguments) async {
  String scriptPath = Platform.script.toFilePath();
  File scriptFile = File(scriptPath);

  String configPath = arguments[0];
  File configFile = File(configPath);
  bool hasConfig = await configFile.exists();

  _SetupConfig config;

  if (hasConfig) {
    stdout.writeln('Reading bundle names config...');
    config = await _readConfigFromFile(configFile);
  } else {
    stdout.writeln('Could not find \'$configPath\'');
    bool createFile = readConsoleYesNo(
      'Would you like to set configuration manually? Y/N',
    );
    if (!createFile) return;
    config = _getConfigFromInput();
    File newConfigFile = File(configPath);
    newConfigFile.writeAsString(config.toString());
  }

  //Get root directory
  Directory projectDir = getProjectRootDir(scriptFile);
  stdout.writeln('Searching platform projects...');
  Map<String, Directory> subDirs = getSubDirsAsMap(projectDir);

  stdout.writeln('Renaming bundle ids...');
  _configureYaml(projectDir.findFile('pubspec.yaml'), config);
  _configureAndroid(subDirs['android'], config);
  _configureIOS(subDirs['ios'], config);
  _configureWeb(subDirs['web'], config);
  _configureWindows(subDirs['windows'], config);
  _configureLinux(subDirs['linux'], config);
  _configureMac(subDirs['macos'], config);
  stdout.writeln('Success!');
}

Future<_SetupConfig> _readConfigFromFile(File configFile) async {
  String fileContent = await configFile.readAsString();
  Map<String, dynamic> jsonMap = json.decode(fileContent);
  return _SetupConfig.fromJson(jsonMap);
}

_SetupConfig _getConfigFromInput() {
  String projectName = readConsoleInput('Enter project package name',
      onEmptyMessage: "Project package name must not be empty");

  String name = readConsoleInput('Enter app name',
      onEmptyMessage: "App name must not be empty");
  String description = readConsoleInput('Enter app description');

  String appCopyright = readConsoleInput('Enter app copyright notice');

  String androidAppId = readConsoleInput(
    'Specify Android app id',
    onEmptyMessage: 'Android app id must not be empty!',
  );
  String iOSBundleId = readConsoleInput(
    'Specify iOS bundle id',
    onEmptyMessage: 'iOS bundle id must not be empty!',
  );
  String linuxAppId = readConsoleInput(
    'Specify linux app id',
    onEmptyMessage: 'Linux app id must not be empty!',
  );

  String linuxBinaryName = readConsoleInput(
    'Specify linux binary name (default:$name)',
    fallback: name,
  );

  String macosId = readConsoleInput(
    'Specify macos app id',
    onEmptyMessage: 'Macos app id must not be empty!',
  );

  String webAppName = readConsoleInput(
    'Specify web app name (default:$name)',
    fallback: name,
  );
  String webAppShortName = readConsoleInput(
    'Specify web app short name (default:$name)',
    fallback: name,
  );
  String windowsAppName = readConsoleInput(
    'Specify windows app name (default:$name)',
    fallback: name,
  );
  String windowsBinaryName = readConsoleInput(
    'Specify name of the windows binary (default:$windowsAppName)',
    fallback: windowsAppName,
  );

  return _SetupConfig(
    projectName: projectName,
    appName: name,
    appDescription: description,
    appCopyright: appCopyright,
    androidId: androidAppId,
    iOSBundleId: iOSBundleId,
    webAppName: webAppName,
    webAppShortName: webAppShortName,
    linuxAppId: linuxAppId,
    linuxBinaryName: linuxBinaryName,
    windowsBinaryName: windowsBinaryName,
    windowsAppName: windowsAppName,
    macOSId: macosId,
  );
}

void _configureYaml(File pubSpecFile, _SetupConfig config) {
  try {
    List<String> pubSpecContent = pubSpecFile.readAsLinesSync();

    int nameLineIndex =
        pubSpecContent.indexWhere((String line) => line.startsWith('name:'));
    String nameLine = pubSpecContent[nameLineIndex];

    int nameReplaceStart = nameLine.indexOf(':') + 2;
    String updatedNameLine = nameLine.replaceRange(
        nameReplaceStart, nameLine.length, config.projectName);
    pubSpecContent[nameLineIndex] = updatedNameLine;

    int descriptionLineIndex = pubSpecContent
        .indexWhere((String line) => line.startsWith('description:'));
    String descriptionLine = pubSpecContent[descriptionLineIndex];

    int descriptionReplaceStart = descriptionLine.indexOf(':') + 2;
    String updatedDescriptionLine = descriptionLine.replaceRange(
        descriptionReplaceStart, descriptionLine.length, config.appDescription);
    pubSpecContent[descriptionLineIndex] = updatedDescriptionLine;

    pubSpecFile.writeAsStringSync(pubSpecContent.join('\n'));
    stdout.writeln('✔ pubspec.yaml configured');
  } catch (e) {
    printError('Error while configuring pubspec.yaml file: ${e.toString()}');
    rethrow;
  }
}

void _configureAndroid(Directory? androidDir, _SetupConfig config) async {
  if (androidDir == null) {
    printWarning(
      'Warning: Could not find \'android\' directory in project. Check supported platforms.',
    );
    return;
  }
  Directory appDir = androidDir.findDir('app');
  File gradleBuild = appDir.findFile('build.gradle');

  List<String> gradleBuildContent = gradleBuild.readAsLinesSync();

  int targetLineIndex = gradleBuildContent
      .indexWhere((String line) => line.contains(_androidAppId));

  String appIdLine = gradleBuildContent[targetLineIndex];

  int replaceStart =
      appIdLine.indexOf(_androidAppId) + _androidAppId.length + 1;

  String changedLine = appIdLine.replaceRange(
      replaceStart, appIdLine.length, '"${config.androidId}"');

  gradleBuildContent[targetLineIndex] = changedLine;
  gradleBuild.writeAsStringSync(gradleBuildContent.join('\n'));
  stdout.writeln('✔ Android configured');
}

void _configureWindows(Directory? windowsDir, _SetupConfig config) {
  if (windowsDir == null) {
    printWarning(
      'Warning: Could not find \'windows\' directory in project. Check supported platforms.',
    );
    return;
  }
  File cmakeFile = windowsDir.findFile('CMakeLists.txt');
  List<String> cMakeContent = cmakeFile.readAsLinesSync();

  _findAndReplaceStringInCMake(
      cMakeContent, 'BINARY_NAME', config.windowsBinaryName);

  cmakeFile.writeAsStringSync(cMakeContent.join('\n'));

  File mainCppFile = windowsDir.findDir('runner').findFile('main.cpp');
  List<String> mainCppContent = mainCppFile.readAsLinesSync();
  int targetLineIndex = mainCppContent
      .indexWhere((element) => element.contains('!window.CreateAndShow('));

  String targetLine = mainCppContent[targetLineIndex];

  int replaceBegin = targetLine.lastIndexOf('(L') + 2;
  int replaceEnd = targetLine.indexOf(',');
  String updatedLine = targetLine.replaceRange(
      replaceBegin, replaceEnd, '"${config.windowsAppName}"');
  mainCppContent[targetLineIndex] = updatedLine;
  mainCppFile.writeAsStringSync(mainCppContent.join('\n'));
  stdout.writeln('✔ Windows configured');
}

void _configureWeb(Directory? webDir, _SetupConfig config) {
  if (webDir == null) {
    printWarning(
      'Warning: Could not find \'web\' directory in project. Check supported platforms.',
    );
    return;
  }

  File manifestFile = webDir.findFile('manifest.json');
  List<String> manifestContent = manifestFile.readAsLinesSync();

  _findAndReplaceStringInJson(
    manifestContent,
    '"name"',
    config.webAppName,
  );

  _findAndReplaceStringInJson(
    manifestContent,
    '"short_name"',
    config.webAppShortName,
  );

  _findAndReplaceStringInJson(
    manifestContent,
    '"description"',
    config.appDescription,
  );

  manifestFile.writeAsStringSync(manifestContent.join('\n'));

  File indexFile = webDir.findFile('index.html');
  List<String> indexContent = indexFile.readAsLinesSync();

  int titleTargetIndex = indexContent.indexWhere(
      (String line) => line.contains('"apple-mobile-web-app-title"'));
  String titleLine = indexContent[titleTargetIndex];
  int replaceStart = titleLine.indexOf('content=') + ('content='.length);
  int replaceEnd = titleLine.indexOf('>');
  String titleUpdatedLine = titleLine.replaceRange(
      replaceStart, replaceEnd, '"${config.webAppName}"');
  indexContent[titleTargetIndex] = titleUpdatedLine;
  indexFile.writeAsStringSync(indexContent.join('\n'));

  stdout.writeln('✔ Web configured');
}

void _findAndReplaceStringInCMake(
    List<String> content, String key, String replacement) {
  int targetIndex =
      content.indexWhere((String element) => element.startsWith('set($key'));
  String targetString = content[targetIndex];
  int replaceStart = targetString.indexOf(key) + (key.length) + 1;
  String updatedString = targetString.replaceRange(
      replaceStart, targetString.length, '"$replacement")');
  content[targetIndex] = updatedString;
}

void _findAndReplaceStringInJson(
    List<String> content, String key, String replacement) {
  int targetLineIndex = content.indexWhere((String line) => line.contains(key));
  String targetLine = content[targetLineIndex];
  int replaceStart = targetLine.indexOf(key) + key.length + 2;
  int replaceEnd = targetLine.indexOf('",') + 1;
  String updatedNameLine =
      targetLine.replaceRange(replaceStart, replaceEnd, '"$replacement"');

  content[targetLineIndex] = updatedNameLine;
}

void _configureIOS(Directory? iOSDir, _SetupConfig config) {
  if (iOSDir == null) {
    printWarning(
      'Warning: Could not find \'ios\' directory in project. Check supported platforms.',
    );
    return;
  }

  File pbxProjFile =
      iOSDir.findDir('Runner.xcodeproj').findFile('project.pbxproj');

  List<String> projFileContent = pbxProjFile.readAsLinesSync();

  int targetLineIndex = projFileContent
      .indexWhere((String line) => line.contains('PRODUCT_BUNDLE_IDENTIFIER'));
  String targetLine = projFileContent[targetLineIndex];

  int bundleIdStart = targetLine.indexOf('= ') + 2;
  String bundleId = targetLine.substring(
    bundleIdStart,
    targetLine.indexOf(';'),
  );

  String updatedText =
      projFileContent.join('\n').replaceAll(bundleId, config.iOSBundleId);

  pbxProjFile.writeAsString(updatedText);

  File infoPlistFile = iOSDir.findDir('Runner').findFile('Info.plist');

  List<String> infoPlistContent = infoPlistFile.readAsLinesSync();

  _replaceValueInIosXml(
      infoPlistContent, 'CFBundleDisplayName', config.appName);

  _replaceValueInIosXml(infoPlistContent, 'CFBundleName', config.appName);

  infoPlistFile.writeAsString(infoPlistContent.join('\n'));

  stdout.writeln('✔ iOS configured');
}

void _replaceValueInIosXml(
    List<String> fileContent, String key, String replacement) {
  int targetLineIndex = fileContent
          .indexWhere((String line) => line.contains('<key>$key</key>')) +
      1;

  String targetLine = fileContent[targetLineIndex];
  String updatedLine = targetLine.replaceRange(targetLine.indexOf('>') + 1,
      targetLine.indexOf('</string>'), replacement);

  fileContent[targetLineIndex] = updatedLine;
}

void _configureMac(Directory? macDir, _SetupConfig config) {
  if (macDir == null) {
    printWarning(
      'Warning: Could not find \'macos\' directory in project. Check supported platforms.',
    );
    return;
  }

  File pbxProjFile =
      macDir.findDir('Runner.xcodeproj').findFile('project.pbxproj');

  List<String> projFileContent = pbxProjFile.readAsLinesSync();

  int targetLineIndex =
      projFileContent.indexWhere((String line) => line.contains('path = "'));
  String targetLine = projFileContent[targetLineIndex];

  int searchStart = targetLine.indexOf('path = "') + ('path = "'.length);
  String part = targetLine.substring(searchStart);
  int searchEnd = part.indexOf('";');
  String currentBundleId = part.substring(0, searchEnd);

  String updatedText =
      projFileContent.join('\n').replaceAll(currentBundleId, config.macOSId);

  pbxProjFile.writeAsString(updatedText);

  File appInfoFile =
      macDir.findDir('Runner').findDir('Configs').findFile('AppInfo.xcconfig');
  List<String> appInfoContent = appInfoFile.readAsLinesSync();

  _replaceValueInAppInfo(appInfoContent, 'PRODUCT_NAME', config.appName);
  _replaceValueInAppInfo(
      appInfoContent, 'PRODUCT_BUNDLE_IDENTIFIER', config.macOSId);
  _replaceValueInAppInfo(
      appInfoContent, 'PRODUCT_COPYRIGHT', config.appCopyright);

  appInfoFile.writeAsString(appInfoContent.join('\n'));

  stdout.writeln('✔ macOS configured');
}

void _replaceValueInAppInfo(
    List<String> appInfoContent, String key, String replacement) {
  int targetLineIndex =
      appInfoContent.indexWhere((String line) => line.contains(key));
  String targetLine = appInfoContent[targetLineIndex];
  int replaceStart = targetLine.indexOf('=') + 2;
  String updatedNameLine =
      targetLine.replaceRange(replaceStart, targetLine.length, replacement);
  appInfoContent[targetLineIndex] = updatedNameLine;
}

void _configureLinux(Directory? linuxDir, _SetupConfig config) {
  if (linuxDir == null) {
    printWarning(
      'Warning: Could not find \'linux\' directory in project. Check supported platforms.',
    );
    return;
  }

  File cmakeFile = linuxDir.findFile('CMakeLists.txt');
  List<String> cmakeContent = cmakeFile.readAsLinesSync();

  _findAndReplaceStringInCMake(
      cmakeContent, 'BINARY_NAME', config.linuxBinaryName);
  _findAndReplaceStringInCMake(
      cmakeContent, 'APPLICATION_ID', config.linuxAppId);

  cmakeFile.writeAsString(cmakeContent.join('\n'));
  stdout.writeln('✔ Linux configured');
}

class _SetupConfig {
  final String projectName;
  final String appName;
  final String appDescription;
  final String appCopyright;
  final String androidId;
  final String iOSBundleId;
  final String webAppName;
  final String webAppShortName;
  final String linuxAppId;
  final String linuxBinaryName;
  final String windowsBinaryName;
  final String windowsAppName;
  final String macOSId;

  const _SetupConfig({
    required this.projectName,
    required this.appName,
    required this.appCopyright,
    required this.appDescription,
    required this.androidId,
    required this.iOSBundleId,
    required this.webAppName,
    required this.webAppShortName,
    required this.linuxAppId,
    required this.linuxBinaryName,
    required this.windowsBinaryName,
    required this.windowsAppName,
    required this.macOSId,
  });

  factory _SetupConfig.fromJson(Map<String, dynamic> json) {
    return _SetupConfig(
      projectName: json['projectName'],
      appName: json['appName'],
      appDescription: json['appDescription'],
      appCopyright: json['appCopyright'],
      androidId: json['androidId'],
      iOSBundleId: json['iOSBundleId'],
      webAppName: json['webAppName'],
      webAppShortName: json['webAppShortName'],
      linuxAppId: json['linuxAppId'],
      linuxBinaryName: json['linuxBinaryName'],
      windowsBinaryName: json['windowsBinaryName'],
      windowsAppName: json['windowsAppName'],
      macOSId: json['macOSId'],
    );
  }

  @override
  String toString() => '''{
      "projectName": "$projectName",
      "appName": "$appName",
      "appDescription": "$appDescription",
      "appCopyright": "$appCopyright",
      "androidId": "$androidId",
      "iOSBundleId": "$iOSBundleId",
      "webAppName": "$webAppName",
      "webAppShortName": "$webAppShortName",
      "linuxAppId": "$linuxAppId",
      "linuxBinaryName": "$linuxBinaryName",
      "windowsBinaryName": "$windowsBinaryName",
      "windowsAppName": "$windowsAppName",
      "macOSId": "$macOSId"
  }''';
}
