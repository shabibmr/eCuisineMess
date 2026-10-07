import 'package:ecuisine_mess/config/api_config.dart';
import 'package:ecuisine_mess/core/config/app_config.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/session_token_holder.dart';
import 'package:ecuisine_mess/core/network/unauthorized_handler.dart';
import 'package:ecuisine_mess/core/router/app_router.dart';
import 'package:ecuisine_mess/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ecuisine_mess/features/auth/data/datasources/session_local_datasource.dart';
import 'package:ecuisine_mess/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ecuisine_mess/features/auth/domain/repositories/auth_repository.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/login.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/logout.dart';
import 'package:ecuisine_mess/features/auth/domain/usecases/restore_session.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:ecuisine_mess/features/bills/data/repositories/bill_repository_impl.dart';
import 'package:ecuisine_mess/features/bills/domain/repositories/bill_repository.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/cancel_bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/get_bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/get_bills.dart';
import 'package:ecuisine_mess/features/bills/presentation/bloc/bill_list_bloc.dart';
import 'package:ecuisine_mess/features/counter/data/datasources/counter_remote_datasource.dart';
import 'package:ecuisine_mess/features/counter/data/repositories/counter_repository_impl.dart';
import 'package:ecuisine_mess/features/counter/domain/repositories/counter_repository.dart';
import 'package:ecuisine_mess/features/counter/domain/usecases/get_current_meal_window.dart';
import 'package:ecuisine_mess/features/counter/domain/usecases/issue_token.dart';
import 'package:ecuisine_mess/features/counter/domain/usecases/tap_rfid.dart';
import 'package:ecuisine_mess/features/counter/presentation/bloc/counter_bloc.dart';
import 'package:ecuisine_mess/features/cuisines/data/datasources/cuisine_remote_datasource.dart';
import 'package:ecuisine_mess/features/cuisines/data/repositories/cuisine_repository_impl.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/copy_cuisine_mapping.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/delete_cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisines.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/save_cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/bloc/cuisine_editor_bloc.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/bloc/cuisine_list_bloc.dart';
import 'package:ecuisine_mess/features/daily_menu/data/datasources/daily_menu_remote_datasource.dart';
import 'package:ecuisine_mess/features/daily_menu/data/repositories/daily_menu_repository_impl.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_from_date.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_meal_to_cuisines.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_day_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_menu_history.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/save_day_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/menu_history_bloc.dart';
import 'package:ecuisine_mess/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:ecuisine_mess/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:ecuisine_mess/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:ecuisine_mess/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ecuisine_mess/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:ecuisine_mess/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:ecuisine_mess/features/reports/domain/repositories/reports_repository.dart';
import 'package:ecuisine_mess/features/reports/domain/usecases/reports_usecases.dart';
import 'package:ecuisine_mess/shared/services/file_export_service.dart';
import 'package:ecuisine_mess/features/item_categories/data/datasources/item_category_remote_datasource.dart';
import 'package:ecuisine_mess/features/item_categories/data/repositories/item_category_repository_impl.dart';
import 'package:ecuisine_mess/features/item_categories/domain/repositories/item_category_repository.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/get_item_categories.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/save_item_category.dart';
import 'package:ecuisine_mess/features/item_categories/presentation/bloc/item_category_list_bloc.dart';
import 'package:ecuisine_mess/features/items/data/datasources/item_remote_datasource.dart';
import 'package:ecuisine_mess/features/items/data/repositories/item_repository_impl.dart';
import 'package:ecuisine_mess/features/items/domain/repositories/item_repository.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/delete_item.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/get_items.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/get_uoms.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/save_item.dart';
import 'package:ecuisine_mess/features/items/presentation/bloc/item_list_bloc.dart';
import 'package:ecuisine_mess/features/meal_times/data/datasources/meal_time_remote_datasource.dart';
import 'package:ecuisine_mess/features/meal_times/data/repositories/meal_time_repository_impl.dart';
import 'package:ecuisine_mess/features/meal_times/domain/repositories/meal_time_repository.dart';
import 'package:ecuisine_mess/features/meal_times/domain/usecases/get_meal_times.dart';
import 'package:ecuisine_mess/features/meal_times/domain/usecases/save_meal_time.dart';
import 'package:ecuisine_mess/features/meal_times/presentation/bloc/meal_time_settings_bloc.dart';
import 'package:ecuisine_mess/features/members/data/datasources/member_remote_datasource.dart';
import 'package:ecuisine_mess/features/members/data/repositories/member_repository_impl.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/check_rfid_available.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/delete_member.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_cuisine_options.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_member.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_members.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/save_member.dart';
import 'package:ecuisine_mess/features/members/presentation/bloc/member_list_bloc.dart';
import 'package:ecuisine_mess/features/settings/presentation/cubit/server_settings_cubit.dart';
import 'package:ecuisine_mess/services/api_service.dart';
import 'package:ecuisine_mess/shared/services/printer_service.dart';
import 'package:ecuisine_mess/shared/services/printer_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final appConfig = AppConfig(prefs);
  await appConfig.load();
  // Strangler: legacy ApiService still reads ApiConfig.baseUrl.
  ApiConfig.baseUrl = appConfig.baseUrl;
  sl.registerSingleton<AppConfig>(appConfig);

  sl.registerLazySingleton<SessionTokenHolder>(SessionTokenHolder.new);
  sl.registerLazySingleton<UnauthorizedHandler>(UnauthorizedHandler.new);

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      config: sl(),
      session: sl(),
      unauthorized: sl(),
    ),
  );

  sl.registerLazySingleton(() => PrinterSettings(sl()));
  sl.registerLazySingleton<PrinterService>(() => ConfiguredPrinterService(sl()));

  _registerAuth();
  _registerSettings();
  _registerItemCategories();
  _registerItems();
  _registerMembers();
  _registerCuisines();
  _registerMealTimes();
  _registerDailyMenu();
  _registerCounter();
  _registerBills();
  _registerDashboard();
  _registerReports();

  sl.registerLazySingleton<AppRouter>(() => AppRouter(sl()));

  // Wire 401 from Dio and legacy http client into AuthBloc.
  void handleUnauthorized() {
    if (!sl.isRegistered<AuthBloc>()) return;
    final bloc = sl<AuthBloc>();
    if (bloc.state is Authenticated) {
      bloc.add(const SessionExpired());
    }
  }

  sl<UnauthorizedHandler>().onUnauthorized = handleUnauthorized;
  ApiService.onUnauthorized = handleUnauthorized;
}

void _registerAuth() {
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      sessionTokenHolder: sl(),
    ),
  );
  sl.registerLazySingleton(() => RestoreSession(sl()));
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      restoreSession: sl(),
      login: sl(),
      logout: sl(),
      authRepository: sl(),
      sessionTokenHolder: sl(),
    ),
  );
}

void _registerSettings() {
  sl.registerFactory(
    () => ServerSettingsCubit(appConfig: sl(), apiClient: sl()),
  );
}

void _registerItemCategories() {
  sl.registerLazySingleton<ItemCategoryRemoteDataSource>(
    () => ItemCategoryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ItemCategoryRepository>(
    () => ItemCategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetItemCategories(sl()));
  sl.registerLazySingleton(() => SaveItemCategory(sl()));
  sl.registerFactory(
    () => ItemCategoryListBloc(
      getItemCategories: sl(),
      saveItemCategory: sl(),
    ),
  );
}

void _registerItems() {
  sl.registerLazySingleton<ItemRemoteDataSource>(
    () => ItemRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ItemRepository>(
    () => ItemRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetItems(sl()));
  sl.registerLazySingleton(() => GetUoms(sl()));
  sl.registerLazySingleton(() => SaveItem(sl()));
  sl.registerLazySingleton(() => DeleteItem(sl()));
  sl.registerFactory(
    () => ItemListBloc(
      getItems: sl(),
      getUoms: sl(),
      getItemCategories: sl(),
      saveItem: sl(),
      deleteItem: sl(),
    ),
  );
}

void _registerMembers() {
  sl.registerLazySingleton<MemberRemoteDataSource>(
    () => MemberRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<MemberRepository>(
    () => MemberRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMembers(sl()));
  sl.registerLazySingleton(() => GetMember(sl()));
  sl.registerLazySingleton(() => SaveMember(sl()));
  sl.registerLazySingleton(() => CheckRfidAvailable(sl()));
  sl.registerLazySingleton(() => DeleteMember(sl()));
  sl.registerLazySingleton(() => GetCuisineOptions(sl()));
  sl.registerFactory(
    () => MemberListBloc(
      getMembers: sl(),
      getCuisineOptions: sl(),
      saveMember: sl(),
      checkRfidAvailable: sl(),
    ),
  );
}

void _registerCuisines() {
  sl.registerLazySingleton<CuisineRemoteDataSource>(
    () => CuisineRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CuisineRepository>(
    () => CuisineRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetCuisines(sl()));
  sl.registerLazySingleton(() => GetCuisine(sl()));
  sl.registerLazySingleton(() => SaveCuisine(sl()));
  sl.registerLazySingleton(() => DeleteCuisine(sl()));
  sl.registerLazySingleton(() => CopyCuisineMapping(sl()));
  sl.registerFactory(
    () => CuisineListBloc(
      getCuisines: sl(),
      deleteCuisine: sl(),
    ),
  );
  sl.registerFactory(
    () => CuisineEditorBloc(
      getCuisine: sl(),
      getCuisines: sl(),
      getItems: sl(),
      saveCuisine: sl(),
    ),
  );
}

void _registerMealTimes() {
  sl.registerLazySingleton<MealTimeRemoteDataSource>(
    () => MealTimeRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<MealTimeRepository>(
    () => MealTimeRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetMealTimes(sl()));
  sl.registerLazySingleton(() => SaveMealTime(sl()));
  sl.registerFactory(
    () => MealTimeSettingsBloc(
      getCuisineOptions: sl(),
      getMealTimes: sl(),
      saveMealTime: sl(),
    ),
  );
}

void _registerCounter() {
  sl.registerLazySingleton<CounterRemoteDataSource>(
    () => CounterRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CounterRepository>(
    () => CounterRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetCurrentMealWindow(sl()));
  sl.registerLazySingleton(() => TapRfid(sl()));
  sl.registerLazySingleton(() => IssueToken(sl()));
  sl.registerFactory(
    () => CounterBloc(
      getCurrentMealWindow: sl(),
      tapRfid: sl(),
      issueToken: sl(),
    ),
  );
}

void _registerDashboard() {
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDashboardSummary(sl()));
  sl.registerFactory(
    () => DashboardBloc(
      getDashboardSummary: sl(),
      getMealTimes: sl(),
    ),
  );
}

void _registerBills() {
  sl.registerLazySingleton<BillRemoteDataSource>(
    () => BillRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BillRepository>(
    () => BillRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetBills(sl()));
  sl.registerLazySingleton(() => GetBill(sl()));
  sl.registerLazySingleton(() => CancelBill(sl()));
  sl.registerFactory(
    () => BillListBloc(
      getBills: sl(),
      getBill: sl(),
      cancelBill: sl(),
    ),
  );
}

void _registerDailyMenu() {
  sl.registerLazySingleton<DailyMenuRemoteDataSource>(
    () => DailyMenuRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<DailyMenuRepository>(
    () => DailyMenuRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetDayMenu(sl()));
  sl.registerLazySingleton(() => GetMenuStatus(sl()));
  sl.registerLazySingleton(() => GetMenuHistory(sl()));
  sl.registerLazySingleton(() => SaveDayMenu(sl()));
  sl.registerLazySingleton(() => CopyFromDate(sl()));
  sl.registerLazySingleton(() => CopyMealToCuisines(sl()));
  sl.registerFactory(
    () => DailyMenuEditorBloc(
      getCuisineOptions: sl(),
      getDayMenu: sl(),
      saveDayMenu: sl(),
      copyFromDate: sl(),
      copyMealToCuisines: sl(),
      getCuisine: sl(),
    ),
  );
  sl.registerFactory(
    () => MenuHistoryBloc(
      getMenuHistory: sl(),
      getCuisineOptions: sl(),
    ),
  );
}



void _registerReports() {
  sl.registerLazySingleton<FileExportService>(DownloadsFileExportService.new);
  sl.registerLazySingleton<ReportsRemoteDataSource>(
    () => ReportsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetAttendanceReport(sl()));
  sl.registerLazySingleton(() => GetItemMovementReport(sl()));
  sl.registerLazySingleton(() => GetTimeDistributionReport(sl()));
  sl.registerLazySingleton(() => GetMembersRegister(sl()));
  sl.registerLazySingleton(() => ExportReportCsv(sl(), sl()));
}
