sealed class MayaResult<T> {
  const MayaResult();

  bool get isSuccess => this is MayaSuccess<T>;
  bool get isFailure => this is MayaFailure<T>;
}

class MayaSuccess<T> extends MayaResult<T> {
  final T value;

  const MayaSuccess(this.value);
}

class MayaFailure<T> extends MayaResult<T> {
  final String message;
  final Object? error;

  const MayaFailure(
    this.message, {
    this.error,
  });
}
