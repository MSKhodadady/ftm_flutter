import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LoadingHook {
  final ValueNotifier<bool> isLoading;
  Future<void> withLoading(Future<void> Function() a) async {
    isLoading.value = true;

    await a();

    isLoading.value = false;
  }

  LoadingHook() : isLoading = useState(false);
}
