import 'errors/app_error.dart';

abstract class Try<T> {
  const Try._();

  bool get isResult => this is Result<T>;
  bool get isError => this is Error<T>;

  void when({
    required Function(T) result,
    required Function(AppError) error,
  }) {
    if (this is Result<T>) {
      result((this as Result).data);
    } else {
      error((this as Error).error);
    }
  }
}

class Result<T> extends Try<T> {
  final T data;
  const Result(this.data) : super._();

  @override
  String toString() => 'Result<${T.runtimeType}>(${data.toString()})';
}

class Error<T> extends Try<T> {
  final AppError error;
  const Error(this.error) : super._();

  @override
  String toString() => 'Error<${T.runtimeType}>(${error.toString()})';
}
