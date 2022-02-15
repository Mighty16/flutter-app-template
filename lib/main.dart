import '_runner/runner_stub.dart'
    if (dart.library.io) '_runner/runner_io.dart'
    if (dart.library.html) '_runner/runner_web.dart' as runner;

void main() => runner.run();
