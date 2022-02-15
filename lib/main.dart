import 'package:test_project/_runner/runner_stub.dart'
    if (dart.library.io) 'package:scoped_bloc_example/runner_io.dart'
    if (dart.library.html) 'package:scoped_bloc_example/runner_web.dart'
    as runner;

void main() => runner.run();
