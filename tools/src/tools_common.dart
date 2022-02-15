import 'dart:io';

const _tools_dir_name = 'tools';

Directory getProjectRootDir(File scriptFile) {
  String scriptParentPath = scriptFile.parent.path;
  int toolsDirIndex =
      scriptParentPath.indexOf('${Platform.pathSeparator}$_tools_dir_name');
  String rootDirPath = scriptParentPath.substring(0, toolsDirIndex);
  return Directory(rootDirPath);
}

Map<String, Directory> getSubDirsAsMap(Directory rootDir) {
  Iterable<FileSystemEntity> subDirectories = rootDir.listSync().where(
        (FileSystemEntity entity) =>
            FileSystemEntity.isDirectorySync(entity.path),
      );

  return {
    for (var entity in subDirectories) getName(entity): Directory(entity.path)
  };
}

String getName(FileSystemEntity entity) {
  String path = entity.path;
  int nameStart = path.lastIndexOf(Platform.pathSeparator);
  return path.substring(nameStart + 1);
}

void printError(String error) {
  stdout.writeln('\x1B[31m$error\x1B[0m');
}

void printWarning(String warning) {
  stdout.writeln('\x1B[33m$warning\x1B[0m');
}

bool readConsoleYesNo(String message) {
  stdout.write('$message: ');
  String input = (stdin.readLineSync() ?? '').toLowerCase();
  if (input == 'y') return true;
  if (input == 'n') return false;
  return readConsoleYesNo(message);
}

String readConsoleInput(String message,
    {String? fallback, String? onEmptyMessage}) {
  stdout.write('$message: ');
  String input = stdin.readLineSync() ?? '';
  if (input.isEmpty) {
    String resolvedFallback = fallback ?? '';
    if (resolvedFallback.isEmpty && onEmptyMessage != null) {
      printError('Error: $onEmptyMessage');
      return readConsoleInput(
        message,
        fallback: fallback,
        onEmptyMessage: onEmptyMessage,
      );
    } else {
      return resolvedFallback;
    }
  }
  return input;
}

extension ToolsExt on Directory {
  FileSystemEntity find(String name) {
    return listSync().firstWhere((element) => getName(element) == name);
  }

  Directory findDir(String name) {
    return Directory(find(name).path);
  }

  File findFile(String name) {
    return File(find(name).path);
  }
}
