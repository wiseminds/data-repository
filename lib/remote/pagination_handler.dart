// import 'package:built_collection/built_collection.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get_it/get_it.dart';
// import 'package:mobile/constants/strings.dart';
// import 'package:mobile/data/local/local_repository.dart';
// import 'package:mobile/data/remote/provider/api_response.dart';
// import 'package:mobile/models/error_model.dart';
// import 'package:mobile/widgets/base/base_bloc.dart';
// import 'package:mobile/widgets/exception_formater.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'interceptors/json_interceptor.dart';

// mixin PaginationHandlerMixin on ExceptionFormater {
//   Future<void> loadData({bool loadMore, String id});
//   final LocalRepository _localRepository = GetIt.I<LocalRepository>();

//   /// resolve response or error and dispatchs an event accordingly
//   Future<void> handleRespone<InnerType>(Bloc bloc, ApiResponse response,
//       {bool isMore = false,
//       String? message,
//       CacheDescription? cache,
//       String? errorMessage,
//       bool invertData = false}) async {
//     if (response.body != null && response.body is BuiltList<InnerType>) {
//       var pagination = response.pagination;
//       // print('page ---- ${pagination?.page} $isMore');
//       var data = response.body as BuiltList<InnerType>;
//       bloc.add(UpdateDataListEvent<InnerType>(
//         invertData ? data.reversed.toBuiltList() : data,
//         isMore,
//         total: pagination?.totalCount?.toInt(),
//         chunkCount: pagination?.chunkCount?.toInt(),
//         limit: pagination?.limit?.toInt(),
//         pages: pagination?.pageCount?.toInt(),
//         page: pagination?.page?.toInt() ?? 1,
//         order: pagination?.order,
//         query: pagination?.query,
//       ));

//       if (cache != null &&
//           pagination != null &&
//           pagination.pageCount == pagination.page) {
//         Future.delayed(const Duration(milliseconds: 400), () {
//           var json = JsonInterceptor.convertToJson(bloc.state.data);
//           if (kDebugMode) print('cache: ${cache.key}, $json');
//           _localRepository.saveData(cache.key, json);
//           _localRepository.saveTime(
//               cache.key,
//               DateTime.now()
//                   .add(Duration(milliseconds: cache.lifeSpan))
//                   .millisecondsSinceEpoch);
//         });
//       }
//     } else if (response.body != null && response.body is InnerType) {
//       var data = response.body as InnerType;
//       bloc.add(UpdateDataEvent<InnerType>(data));
//     } else {
//       // print(response.error);
//       bloc.add(LoadFailed<InnerType>((response.error as ErrorModel?)?.message ??
//           Strings.DEFAULT_ERROR_MESSAGE));
//     }
//   }
// }
