import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_section.dart';

class NavigationCubit extends Cubit<AppSection> {
  NavigationCubit() : super(AppSection.library);

  void select(AppSection section) => emit(section);
}
