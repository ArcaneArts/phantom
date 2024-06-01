import 'dart:mirrors';

Map<Type, Object> _services = {};

T svc<T>() {
  if(!_services.containsKey(T)){
    _services[T] = _startService(T);
  }
  
  return _services[T] as T;
}

Object _startService(Type type) {
  reflectType(type).
}
