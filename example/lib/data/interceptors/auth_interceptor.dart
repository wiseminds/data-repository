import 'package:data_repository/data_repository.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// monitor Api response and dispatch logout of the status code is 401
class AuthInterceptor extends ApiInterceptor {
  @override
  ApiResponse<ResponseType, InnerType> onError<ResponseType, InnerType>(
      ApiResponse<ResponseType, InnerType> response) {
    if (kDebugMode) {
      print('in auth interceptor response ${response.statusCode}');
    }
    // if ((response.statusCode == 401) &&
    // || response.statusCode == 403) &&
    //   GetIt.I<AuthBloc>().state is Authenticated) {
    // GetIt.I<AuthBloc>().add(LogOut(clearSaved: false));
    // Future.delayed(const Duration(milliseconds: 700), () {
    //   CitiDialog.info(Get.context!, 'Session expired', '',
    //       button: Navigator.pop, buttonLabel: 'Close');
    // });
    // }
    return response;
  }
}
