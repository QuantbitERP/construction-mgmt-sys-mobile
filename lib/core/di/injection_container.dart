import 'package:get_it/get_it.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cms/core/config/app_config.dart' as cfg;
import 'package:cms/core/services/base_url_storage.dart';
import 'package:cms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cms/features/auth/domain/repositories/auth_repository.dart';
import 'package:cms/features/auth/domain/usecases/login_usecase.dart';
import 'package:cms/features/auth/presentation/bloc/auth_bloc.dart';

// Projects
import 'package:cms/features/projects/domain/repositories/project_repository.dart';
import 'package:cms/features/projects/data/repositories/project_repository_impl.dart';
import 'package:cms/features/projects/data/datasources/project_remote_data_source.dart';
import 'package:cms/features/projects/domain/usecases/get_projects.dart';
import 'package:cms/features/projects/presentation/bloc/project_bloc.dart';

// Tasks
import 'package:cms/features/tasks/domain/repositories/task_repository.dart';
import 'package:cms/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:cms/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:cms/features/tasks/domain/usecases/get_tasks.dart';
import 'package:cms/features/tasks/domain/usecases/update_task_status.dart';
import 'package:cms/features/tasks/presentation/bloc/task_bloc.dart';

// Material Requests
import 'package:cms/features/material_requests/domain/repositories/material_request_repository.dart';
import 'package:cms/features/material_requests/data/repositories/material_request_repository_impl.dart';
import 'package:cms/features/material_requests/presentation/bloc/material_request_bloc.dart';
import 'package:cms/features/material_requests/data/datasources/material_request_remote_data_source.dart';
import 'package:cms/features/material_requests/domain/usecases/get_material_requests.dart';
import 'package:cms/features/material_requests/domain/usecases/get_material_request_details.dart';
import 'package:cms/features/material_requests/domain/usecases/download_material_request_pdf.dart';

// Site Diary
import 'package:cms/features/site_diary/domain/repositories/site_diary_repository.dart';
import 'package:cms/features/site_diary/data/repositories/site_diary_repository_impl.dart';
import 'package:cms/features/site_diary/data/datasources/site_diary_remote_data_source.dart';
import 'package:cms/features/site_diary/domain/usecases/get_site_diaries.dart';
import 'package:cms/features/site_diary/domain/usecases/get_site_diary_details.dart';
import 'package:cms/features/site_diary/domain/usecases/get_site_diary_meta.dart';
import 'package:cms/features/site_diary/domain/usecases/load_site_diary_document.dart';
import 'package:cms/features/site_diary/domain/usecases/call_site_diary_api.dart';
import 'package:cms/features/site_diary/domain/usecases/upload_site_diary_file.dart';
import 'package:cms/features/site_diary/domain/usecases/save_site_diary_document.dart';
import 'package:cms/features/site_diary/domain/usecases/get_employee_name.dart';
import 'package:cms/features/site_diary/domain/usecases/get_site_diary_base_url.dart';
import 'package:cms/features/site_diary/presentation/bloc/site_diary_bloc.dart';
import 'package:cms/features/site_diary/presentation/bloc/site_diary_form_bloc.dart';

// Purchase Receipts
import 'package:cms/features/purchase_receipts/domain/repositories/purchase_receipt_repository.dart';
import 'package:cms/features/purchase_receipts/data/repositories/purchase_receipt_repository_impl.dart';
import 'package:cms/features/purchase_receipts/presentation/bloc/purchase_receipt_bloc.dart';

// Stock Entry
import 'package:cms/features/stock_entry/domain/repositories/stock_entry_repository.dart';
import 'package:cms/features/stock_entry/data/repositories/stock_entry_repository_impl.dart';
import 'package:cms/features/stock_entry/data/datasources/stock_entry_remote_data_source.dart';
import 'package:cms/features/stock_entry/domain/usecases/get_stock_entries.dart';
import 'package:cms/features/stock_entry/domain/usecases/get_stock_entry_details.dart';
import 'package:cms/features/stock_entry/domain/usecases/load_stock_entry_document.dart';
import 'package:cms/features/stock_entry/domain/usecases/save_stock_entry_document.dart';
import 'package:cms/features/stock_entry/domain/usecases/get_stock_entry_base_url.dart';
import 'package:cms/features/stock_entry/domain/usecases/download_stock_entry_pdf.dart';
import 'package:cms/features/stock_entry/presentation/bloc/stock_entry_bloc.dart';
import 'package:cms/features/stock_entry/presentation/bloc/stock_entry_form_bloc.dart';

// Task Progress
import 'package:cms/features/task_progress/domain/repositories/task_progress_repository.dart';
import 'package:cms/features/task_progress/data/repositories/task_progress_repository_impl.dart';
import 'package:cms/features/task_progress/data/datasources/task_progress_remote_data_source.dart';
import 'package:cms/features/task_progress/domain/usecases/get_task_progresses.dart';
import 'package:cms/features/task_progress/domain/usecases/get_task_progress_details.dart';
import 'package:cms/features/task_progress/domain/usecases/get_task_progress_meta.dart';
import 'package:cms/features/task_progress/domain/usecases/load_task_progress_document.dart';
import 'package:cms/features/task_progress/domain/usecases/save_task_progress_document.dart';
import 'package:cms/features/task_progress/domain/usecases/upload_task_progress_file.dart';
import 'package:cms/features/task_progress/domain/usecases/get_task_progress_base_url.dart';
import 'package:cms/features/task_progress/domain/usecases/download_task_progress_pdf.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_bloc.dart';
import 'package:cms/features/task_progress/presentation/bloc/task_progress_form_bloc.dart';

// Usage
import 'package:cms/features/usage/domain/repositories/manpower_usage_repository.dart';
import 'package:cms/features/usage/data/repositories/manpower_usage_repository_impl.dart';
import 'package:cms/features/usage/data/datasources/manpower_usage_remote_data_source.dart';
import 'package:cms/features/usage/domain/usecases/get_manpower_usages.dart';
import 'package:cms/features/usage/domain/usecases/get_manpower_usage_details.dart';
import 'package:cms/features/usage/domain/usecases/get_manpower_usage_meta.dart';
import 'package:cms/features/usage/domain/usecases/load_manpower_usage_document.dart';
import 'package:cms/features/usage/domain/usecases/save_manpower_usage_document.dart';
import 'package:cms/features/usage/domain/usecases/get_manpower_usage_base_url.dart';
import 'package:cms/features/usage/domain/usecases/download_manpower_usage_pdf.dart';
import 'package:cms/features/usage/presentation/bloc/manpower_usage_bloc.dart';
import 'package:cms/features/usage/presentation/bloc/manpower_usage_form_bloc.dart';

import 'package:cms/features/usage/domain/repositories/equipment_usage_repository.dart';
import 'package:cms/features/usage/data/repositories/equipment_usage_repository_impl.dart';
import 'package:cms/features/usage/data/datasources/equipment_usage_remote_data_source.dart';
import 'package:cms/features/usage/domain/usecases/get_equipment_usages.dart';
import 'package:cms/features/usage/domain/usecases/get_equipment_usage_details.dart';
import 'package:cms/features/usage/domain/usecases/get_equipment_usage_meta.dart';
import 'package:cms/features/usage/domain/usecases/load_equipment_usage_document.dart';
import 'package:cms/features/usage/domain/usecases/save_equipment_usage_document.dart';
import 'package:cms/features/usage/domain/usecases/get_equipment_usage_base_url.dart';
import 'package:cms/features/usage/domain/usecases/download_equipment_usage_pdf.dart';
import 'package:cms/features/usage/presentation/bloc/equipment_usage_bloc.dart';
import 'package:cms/features/usage/presentation/bloc/equipment_usage_form_bloc.dart';

// DI
import 'package:cms/core/services/project_selection_service.dart';
import 'package:cms/core/services/homepage_reload_notifier.dart';

// Approvals
import 'package:cms/features/approvals/domain/repositories/approvals_repository.dart';
import 'package:cms/features/approvals/data/repositories/approvals_repository_impl.dart';
import 'package:cms/features/approvals/domain/usecases/get_approvals.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Storage
  final baseUrlStorage = BaseUrlStorage();
  sl.registerLazySingleton<BaseUrlStorage>(() => baseUrlStorage);

  // Services
  sl.registerLazySingleton(() => ProjectSelectionService(sl()));
  sl.registerLazySingleton(() => HomepageReloadNotifier());

  // Frappe SDK
  final savedBaseUrl = await baseUrlStorage.getBaseUrl();
  if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
    cfg.AppConfig.baseUrl = savedBaseUrl;
    final sdk = FrappeSDK(baseUrl: savedBaseUrl);
    try {
      await sdk.initialize(true);
    } catch (_) {
      try {
        await sdk.initialize(false);
      } catch (_) {}
    }
    sl.registerSingleton<FrappeSDK>(sdk);
  } else {
    // If no URL stored yet (first launch), register a placeholder SDK.
    // Replaced upon login via reconfigureFrappeSdk.
    final sdk = FrappeSDK(baseUrl: 'https://placeholder.invalid');
    sl.registerSingleton<FrappeSDK>(sdk);
  }

  // BLoC
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), authRepository: sl()));
  sl.registerFactory(() => ProjectBloc(getProjects: sl()));
  sl.registerFactory(() => TaskBloc(getTasks: sl()));
  sl.registerFactory(() => PurchaseReceiptBloc(repository: sl()));
  sl.registerFactory(
    () => StockEntryBloc(
      getStockEntries: sl(),
      getStockEntryDetails: sl(),
      downloadStockEntryPdf: sl(),
    ),
  );
  sl.registerFactory(
    () => StockEntryFormBloc(
      loadStockEntryDocument: sl(),
      saveStockEntryDocument: sl(),
      getStockEntryBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => TaskProgressBloc(
      getTaskProgresses: sl(),
      getTaskProgressDetails: sl(),
      downloadTaskProgressPdf: sl(),
      getTaskProgressBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => TaskProgressFormBloc(
      getMeta: sl(),
      loadDocument: sl(),
      saveDocument: sl(),
      uploadFile: sl(),
      getBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => ManpowerUsageBloc(
      getManpowerUsages: sl(),
      getManpowerUsageDetails: sl(),
      downloadManpowerUsagePdf: sl(),
      getManpowerUsageBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => ManpowerUsageFormBloc(
      getMeta: sl(),
      loadDocument: sl(),
      saveDocument: sl(),
      getBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => EquipmentUsageBloc(
      getEquipmentUsages: sl(),
      getEquipmentUsageDetails: sl(),
      downloadEquipmentUsagePdf: sl(),
      getEquipmentUsageBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => EquipmentUsageFormBloc(
      getMeta: sl(),
      loadDocument: sl(),
      saveDocument: sl(),
      getBaseUrl: sl(),
    ),
  );
  sl.registerFactory(
    () => MaterialRequestBloc(
      getMaterialRequests: sl(),
      getMaterialRequestDetails: sl(),
      downloadPDF: sl(),
    ),
  );
  sl.registerFactory(() => ApprovalsBloc(getApprovals: sl()));
  sl.registerFactory(
    () => SiteDiaryBloc(getSiteDiaries: sl(), getSiteDiaryDetails: sl()),
  );
  sl.registerFactory(
    () => SiteDiaryFormBloc(
      getSiteDiaryMeta: sl(),
      loadSiteDiaryDocument: sl(),
      callSiteDiaryApi: sl(),
      uploadSiteDiaryFile: sl(),
      saveSiteDiaryDocument: sl(),
      getEmployeeName: sl(),
      getSiteDiaryBaseUrl: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetProjects(sl()));
  sl.registerLazySingleton(() => GetTasks(sl()));
  sl.registerLazySingleton(() => UpdateTaskStatus(sl()));
  sl.registerLazySingleton(() => GetMaterialRequests(sl()));
  sl.registerLazySingleton(() => GetMaterialRequestDetails(sl()));
  sl.registerLazySingleton(() => GetApprovals(sl()));
  sl.registerLazySingleton(() => DownloadMaterialRequestPDFUsecase(sl()));
  sl.registerLazySingleton(() => GetSiteDiaries(sl()));
  sl.registerLazySingleton(() => GetSiteDiaryDetails(sl()));
  sl.registerLazySingleton(() => GetSiteDiaryMeta(sl()));
  sl.registerLazySingleton(() => LoadSiteDiaryDocument(sl()));
  sl.registerLazySingleton(() => CallSiteDiaryApi(sl()));
  sl.registerLazySingleton(() => UploadSiteDiaryFile(sl()));
  sl.registerLazySingleton(() => SaveSiteDiaryDocument(sl()));
  sl.registerLazySingleton(() => GetEmployeeName(sl()));
  sl.registerLazySingleton(() => GetSiteDiaryBaseUrl(sl()));

  sl.registerLazySingleton(() => GetStockEntries(sl()));
  sl.registerLazySingleton(() => GetStockEntryDetails(sl()));
  sl.registerLazySingleton(() => LoadStockEntryDocument(sl()));
  sl.registerLazySingleton(() => SaveStockEntryDocument(sl()));
  sl.registerLazySingleton(() => GetStockEntryBaseUrl(sl()));
  sl.registerLazySingleton(() => DownloadStockEntryPdf(sl()));

  sl.registerLazySingleton(() => GetTaskProgresses(sl()));
  sl.registerLazySingleton(() => GetTaskProgressDetails(sl()));
  sl.registerLazySingleton(() => GetTaskProgressMeta(sl()));
  sl.registerLazySingleton(() => LoadTaskProgressDocument(sl()));
  sl.registerLazySingleton(() => SaveTaskProgressDocument(sl()));
  sl.registerLazySingleton(() => UploadTaskProgressFile(sl()));
  sl.registerLazySingleton(() => GetTaskProgressBaseUrl(sl()));
  sl.registerLazySingleton(() => DownloadTaskProgressPdf(sl()));

  sl.registerLazySingleton(() => GetManpowerUsages(sl()));
  sl.registerLazySingleton(() => GetManpowerUsageDetails(sl()));
  sl.registerLazySingleton(() => GetManpowerUsageMeta(sl()));
  sl.registerLazySingleton(() => LoadManpowerUsageDocument(sl()));
  sl.registerLazySingleton(() => SaveManpowerUsageDocument(sl()));
  sl.registerLazySingleton(() => GetManpowerUsageBaseUrl(sl()));
  sl.registerLazySingleton(() => DownloadManpowerUsagePdf(sl()));

  sl.registerLazySingleton(() => GetEquipmentUsages(sl()));
  sl.registerLazySingleton(() => GetEquipmentUsageDetails(sl()));
  sl.registerLazySingleton(() => GetEquipmentUsageMeta(sl()));
  sl.registerLazySingleton(() => LoadEquipmentUsageDocument(sl()));
  sl.registerLazySingleton(() => SaveEquipmentUsageDocument(sl()));
  sl.registerLazySingleton(() => GetEquipmentUsageBaseUrl(sl()));
  sl.registerLazySingleton(() => DownloadEquipmentUsagePdf(sl()));

  // Data Sources
  sl.registerLazySingleton<ProjectRemoteDataSource>(
    () => ProjectRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<MaterialRequestRemoteDataSource>(
    () => MaterialRequestRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SiteDiaryRemoteDataSource>(
    () => SiteDiaryRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<StockEntryRemoteDataSource>(
    () => StockEntryRemoteDataSourceImpl(
      sdk: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<TaskProgressRemoteDataSource>(
    () => TaskProgressRemoteDataSourceImpl(
      sdk: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<ManpowerUsageRemoteDataSource>(
    () => ManpowerUsageRemoteDataSourceImpl(sdk: sl()),
  );
  sl.registerLazySingleton<EquipmentUsageRemoteDataSource>(
    () => EquipmentUsageRemoteDataSourceImpl(sdk: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDataSource: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<PurchaseReceiptRepository>(
    () => PurchaseReceiptRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<StockEntryRepository>(
    () => StockEntryRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ManpowerUsageRepository>(
    () => ManpowerUsageRepositoryImpl(
      remoteDataSource: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<EquipmentUsageRepository>(
    () => EquipmentUsageRepositoryImpl(
      remoteDataSource: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<MaterialRequestRepository>(
    () => MaterialRequestRepositoryImpl(
      remoteDataSource: sl(),
      projectSelectionService: sl(),
      sdk: sl(),
    ),
  );
  sl.registerLazySingleton<ApprovalsRepository>(
    () => ApprovalsRepositoryImpl(
      sdk: sl(),
      materialRequestRepository: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<SiteDiaryRepository>(
    () => SiteDiaryRepositoryImpl(
      remoteDataSource: sl(),
      projectSelectionService: sl(),
    ),
  );
  sl.registerLazySingleton<TaskProgressRepository>(
    () => TaskProgressRepositoryImpl(sl()),
  );
}

/// Dynamically updates FrappeSDK and saves the new base URL in secure storage.
/// Resets dependent singletons so they bind to the new SDK instance.
Future<void> reconfigureFrappeSdk(String rawBaseUrl) async {
  final normalizedUrl = BaseUrlStorage.normalizeUrl(rawBaseUrl);
  cfg.AppConfig.baseUrl = normalizedUrl;

  final baseUrlStorage = sl<BaseUrlStorage>();
  await baseUrlStorage.saveBaseUrl(normalizedUrl);

  if (sl.isRegistered<FrappeSDK>()) {
    final existingSdk = sl<FrappeSDK>();
    if (existingSdk.baseUrl == normalizedUrl) {
      return;
    }
    sl.unregister<FrappeSDK>();
  }

  final newSdk = FrappeSDK(baseUrl: normalizedUrl);
  await newSdk.initialize(false);
  sl.registerSingleton<FrappeSDK>(newSdk);

  _resetSdkDependentSingletons();
}

void _resetSdkDependentSingletons() {
  if (sl.isRegistered<ProjectRemoteDataSource>()) {
    sl.resetLazySingleton<ProjectRemoteDataSource>();
  }
  if (sl.isRegistered<TaskRemoteDataSource>()) {
    sl.resetLazySingleton<TaskRemoteDataSource>();
  }
  if (sl.isRegistered<MaterialRequestRemoteDataSource>()) {
    sl.resetLazySingleton<MaterialRequestRemoteDataSource>();
  }
  if (sl.isRegistered<SiteDiaryRemoteDataSource>()) {
    sl.resetLazySingleton<SiteDiaryRemoteDataSource>();
  }
  if (sl.isRegistered<StockEntryRemoteDataSource>()) {
    sl.resetLazySingleton<StockEntryRemoteDataSource>();
  }
  if (sl.isRegistered<TaskProgressRemoteDataSource>()) {
    sl.resetLazySingleton<TaskProgressRemoteDataSource>();
  }
  if (sl.isRegistered<ManpowerUsageRemoteDataSource>()) {
    sl.resetLazySingleton<ManpowerUsageRemoteDataSource>();
  }
  if (sl.isRegistered<EquipmentUsageRemoteDataSource>()) {
    sl.resetLazySingleton<EquipmentUsageRemoteDataSource>();
  }
  if (sl.isRegistered<MaterialRequestRepository>()) {
    sl.resetLazySingleton<MaterialRequestRepository>();
  }
  if (sl.isRegistered<ApprovalsRepository>()) {
    sl.resetLazySingleton<ApprovalsRepository>();
  }
  if (sl.isRegistered<AuthRepository>()) {
    sl.resetLazySingleton<AuthRepository>();
  }
}
