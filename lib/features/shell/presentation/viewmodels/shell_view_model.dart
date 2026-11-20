import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellViewModel extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) => state = index;
}

final shellViewModelProvider = NotifierProvider<ShellViewModel, int>(
  ShellViewModel.new,
);
