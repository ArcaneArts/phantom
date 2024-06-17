mixin CancellableEvent {
  bool cancelled = false;

  void cancel() => cancelled = true;

  void unCancel() => cancelled = false;
}
