import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../instance_manager.dart';
import '../../get_state_manager.dart';
import '../simple/list_notifier.dart';

class Value<T> extends ListNotifier implements ValueListenable<T> {
  Value(this._value);

  T get value {
    notifyChildrens();
    return _value;
  }

  @override
  String toString() => value.toString();

  T _value;

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    updater();
  }

  void update(void fn(T value)) {
    fn(value);
    updater();
  }
}

extension ReactiveT<T> on T {
  Value<T> get reactive => Value<T>(this);
}

typedef Condition = bool Function();

abstract class GetNotifier<T> extends Value<T> with GetLifeCycle {
  GetNotifier(T initial) : super(initial) {
    initLifeCycle();
    _fillEmptyStatus();
  }

  @override
  @mustCallSuper
  void onInit() {
    super.onInit();
    SchedulerBinding.instance?.addPostFrameCallback((_) => onReady());
  }

  RxStatus _status;

  bool get isNullOrEmpty {
    if (_value == null) return true;
    dynamic val = _value;
    var result = false;
    if (val is Iterable) {
      result = val.isEmpty;
    } else if (val is String) {
      result = val.isEmpty;
    } else if (val is Map) {
      result = val.isEmpty;
    }
    return result;
  }

  void _fillEmptyStatus() {
    _status = isNullOrEmpty ? RxStatus.loading() : RxStatus.success();
  }

  RxStatus get status {
    notifyChildrens();
    return _status;
  }

  Widget call(NotifierBuilder<T> widget, {Widget onError, Widget onLoading}) {
    assert(widget != null);
    return SimpleBuilder(builder: (_) {
      if (status.isLoading) {
        return onLoading ?? CircularProgressIndicator();
      } else if (status.isError) {
        return onError ?? Text('A error occured: ${status.errorMessage}');
      } else {
        return widget(value);
      }
    });
  }

  @protected
  void change(T newState, {RxStatus status}) {
    var _canUpdate = false;
    if (status != null) {
      _status = status;
      _canUpdate = true;
    }
    if (newState != _value) {
      _value = newState;
      _canUpdate = true;
    }
    if (_canUpdate) {
      updater();
    }
  }

  dynamic toJson() => (value as dynamic)?.toJson();
}

class RxStatus {
  final bool isLoading;
  final bool isError;
  final bool isSuccess;
  final String errorMessage;
  RxStatus._({
    this.isLoading,
    this.isError,
    this.isSuccess,
    this.errorMessage,
  });

  factory RxStatus.loading() {
    return RxStatus._(
      isLoading: true,
      isError: false,
      isSuccess: false,
    );
  }

  factory RxStatus.success() {
    return RxStatus._(
      isLoading: false,
      isError: false,
      isSuccess: true,
    );
  }

  factory RxStatus.error([String message]) {
    return RxStatus._(
      isLoading: false,
      isError: true,
      isSuccess: false,
      errorMessage: message,
    );
  }
}

typedef NotifierBuilder<T> = Widget Function(T state);
