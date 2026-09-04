import 'package:cms/core/theme/app_sizes.dart';
import 'package:cms/core/services/homepage_reload_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/purchase_receipts/presentation/bloc/purchase_receipt_bloc.dart';
import '../../../../features/purchase_receipts/presentation/widgets/purchase_receipt_list_view.dart';
import '../../../../features/material_requests/presentation/bloc/material_request_bloc.dart';
import '../../../../features/material_requests/presentation/widgets/material_request_list_view.dart';
import '../../../../features/stock_entry/presentation/bloc/stock_entry_bloc.dart';
import '../../../../features/stock_entry/presentation/widgets/material_issue_list_view.dart';
import '../../../../features/stock_entry/presentation/widgets/material_transfer_list_view.dart';
import '../../../../features/usage/presentation/widgets/manpower_usage_list_view.dart';
import '../../../../features/usage/presentation/widgets/equipment_usage_list_view.dart';
import '../../../../features/usage/presentation/bloc/manpower_usage_bloc.dart';
import '../../../../features/usage/presentation/bloc/equipment_usage_bloc.dart';
import '../../../../features/site_diary/presentation/bloc/site_diary_bloc.dart';
import '../../../../features/site_diary/presentation/widgets/site_diary_list_view.dart';
import '../../../../features/task_progress/presentation/bloc/task_progress_bloc.dart';
import '../../../../features/task_progress/presentation/pages/task_progress_list_page.dart';
import '../../../../features/task_progress/presentation/pages/daily_progress_report_page.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import 'package:intl/intl.dart';
import '../../../../features/attendance/presentation/pages/employee_checkin_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../features/projects/domain/entities/project.dart';
import '../../../../features/projects/presentation/bloc/project_bloc.dart';
import '../../../../core/widgets/project_selection_dropdown.dart';
import 'package:cms/core/services/project_selection_service.dart';

enum HomepageFlowMode { dropdown, listFlow }

enum ListFlowState { siteList, projectList, dashboard }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Project? _selectedProject;
  String? _selectedSite;
  List<String> _fetchedSites = [];
  bool _isLoadingSites = false;
  String? _companyName;

  int _purchaseReceiptCount = 0;
  int _materialRequestCount = 0;
  int _materialIssueCount = 0;
  int _materialTransferCount = 0;
  int _manpowerUsageCount = 0;
  int _equipmentUsageCount = 0;
  bool _isLoadingCounts = false;

  HomepageFlowMode _flowMode = HomepageFlowMode.dropdown;
  ListFlowState _listFlowState = ListFlowState.siteList;

  @override
  void initState() {
    super.initState();
    sl<HomepageReloadNotifier>().addListener(_fetchCounts);
    sl<ProjectSelectionService>().addListener(_onUniversalProjectChanged);
    _loadHomepagePreference();
    _fetchSites();
    _fetchCompany();
    _fetchCounts();
  }

  @override
  void dispose() {
    sl<HomepageReloadNotifier>().removeListener(_fetchCounts);
    sl<ProjectSelectionService>().removeListener(_onUniversalProjectChanged);
    super.dispose();
  }

  void _onUniversalProjectChanged() {
    if (!mounted) return;
    final universalProject = sl<ProjectSelectionService>().selectedProject;
    final universalSite = sl<ProjectSelectionService>().selectedSite;

    if (_selectedProject?.name == universalProject &&
        _selectedSite == universalSite) {
      return;
    }

    final projectState = context.read<ProjectBloc>().state;
    Project? matchedProject;
    if (projectState is ProjectLoaded && universalProject != null) {
      final matches =
          projectState.projects.where((p) => p.name == universalProject);
      if (matches.isNotEmpty) {
        matchedProject = matches.first;
      }
    }

    setState(() {
      _selectedProject = matchedProject;
      _selectedSite = universalSite;
    });

    _fetchCounts();
  }

  Future<void> _loadHomepagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString('homepage_flow_mode');
    if (modeString == 'listFlow') {
      setState(() {
        _flowMode = HomepageFlowMode.listFlow;
        _listFlowState = ListFlowState.siteList;
        _selectedProject = null;
        _selectedSite = null;
      });
    } else {
      setState(() {
        _flowMode = HomepageFlowMode.dropdown;
      });
    }
  }

  Future<void> _fetchCounts() async {
    final project =
        _selectedProject?.name ?? sl<ProjectSelectionService>().selectedProject;
    if (project == null || project.isEmpty) {
      setState(() {
        _purchaseReceiptCount = 0;
        _materialRequestCount = 0;
        _materialIssueCount = 0;
        _materialTransferCount = 0;
        _manpowerUsageCount = 0;
        _equipmentUsageCount = 0;
      });
      return;
    }

    if (_isLoadingCounts) return;
    setState(() {
      _isLoadingCounts = true;
    });

    try {
      final sdk = sl<FrappeSDK>();
      final site = _selectedSite ?? sl<ProjectSelectionService>().selectedSite;

      // 1. Purchase Receipt
      final List<List<dynamic>> prFilters = [];
      if (project.isNotEmpty) {
        prFilters.add(['Purchase Receipt', 'project', '=', project]);
      }
      if (site != null && site.isNotEmpty) {
        prFilters.add(['Purchase Receipt', 'site', '=', site]);
      }
      final prResult = await sdk.api.doctype.list(
        'Purchase Receipt',
        fields: ['name'],
        filters: prFilters,
        limitPageLength: 1000,
      );
      final prCount = prResult.length;

      // 2. Material Request
      final List<List<dynamic>> mrFilters = [];
      if (project.isNotEmpty) {
        mrFilters.add(['Material Request Item', 'project', '=', project]);
      }
      final mrResult = await sdk.api.doctype.list(
        'Material Request',
        fields: ['name'],
        filters: mrFilters,
        limitPageLength: 1000,
      );
      final mrCount = mrResult.length;

      // 3. Material Issue (Stock Entry)
      final List<List<dynamic>> miFilters = [
        ['Stock Entry', 'stock_entry_type', '=', 'Material Issue'],
      ];
      if (project.isNotEmpty) {
        miFilters.add(['Stock Entry', 'project', '=', project]);
      }
      final miResult = await sdk.api.doctype.list(
        'Stock Entry',
        fields: ['name'],
        filters: miFilters,
        limitPageLength: 1000,
      );
      final miCount = miResult.length;

      // 4. Material Transfer (Stock Entry)
      final List<List<dynamic>> mtFilters = [
        ['Stock Entry', 'stock_entry_type', '=', 'Material Transfer'],
      ];
      if (project.isNotEmpty) {
        mtFilters.add(['Stock Entry', 'project', '=', project]);
      }
      final mtResult = await sdk.api.doctype.list(
        'Stock Entry',
        fields: ['name'],
        filters: mtFilters,
        limitPageLength: 1000,
      );
      final mtCount = mtResult.length;

      // 5. Manpower Usage
      final List<List<dynamic>> mpFilters = [];
      if (project.isNotEmpty) {
        mpFilters.add(['Manpower Usage', 'project', '=', project]);
      }
      final mpResult = await sdk.api.doctype.list(
        'Manpower Usage',
        fields: ['name'],
        filters: mpFilters,
        limitPageLength: 1000,
      );
      final mpCount = mpResult.length;

      // 6. Equipment Usage
      final List<List<dynamic>> eqFilters = [];
      if (project.isNotEmpty) {
        eqFilters.add(['Equipment Usage', 'project', '=', project]);
      }
      final eqResult = await sdk.api.doctype.list(
        'Equipment Usage',
        fields: ['name'],
        filters: eqFilters,
        limitPageLength: 1000,
      );
      final eqCount = eqResult.length;

      if (mounted) {
        setState(() {
          _purchaseReceiptCount = prCount;
          _materialRequestCount = mrCount;
          _materialIssueCount = miCount;
          _materialTransferCount = mtCount;
          _manpowerUsageCount = mpCount;
          _equipmentUsageCount = eqCount;
        });
      }
    } catch (e) {
      debugPrint('Error fetching counts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }

  Future<void> _fetchSites() async {
    if (_fetchedSites.isNotEmpty || _isLoadingSites) return;
    setState(() {
      _isLoadingSites = true;
    });
    try {
      final sdk = sl<FrappeSDK>();
      final List<dynamic> result = await sdk.api.doctype.list(
        'Site',
        fields: ['name'],
        limitPageLength: 100,
      );
      setState(() {
        _fetchedSites = result.map((item) => item['name'].toString()).toList();
      });
    } catch (_) {
      // Fallback: collect sites from project bloc loaded state
      final state = context.read<ProjectBloc>().state;
      if (state is ProjectLoaded) {
        _fetchedSites = state.projects
            .map((p) => p.site ?? 'Unspecified Site')
            .toSet()
            .toList();
      }
    } finally {
      setState(() {
        _isLoadingSites = false;
      });
    }
  }

  Future<void> _fetchCompany() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_company_name');
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() {
          _companyName = cached;
        });
      }

      final sdk = sl<FrappeSDK>();
      final List<dynamic> result = await sdk.api.doctype.list(
        'Company',
        fields: ['name'],
        limitPageLength: 1,
      );
      if (result.isNotEmpty && mounted) {
        final fetched = result.first['name']?.toString();
        if (fetched != null && fetched.isNotEmpty) {
          setState(() {
            _companyName = fetched;
          });
          await prefs.setString('cached_company_name', fetched);
        }
      }
    } catch (e) {
      debugPrint('Error fetching company: $e');
    }
  }

  Future<void> _persistSelection(String site, Project project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_site', site);
    await prefs.setString('last_selected_project_name', project.name);
    await sl<ProjectSelectionService>().saveSelection(
      site: site,
      project: project.name,
    );
  }

  void _showSelectionSheet(BuildContext context) {
    final state = context.read<ProjectBloc>().state;
    if (state is! ProjectLoaded) return;

    final projects = state.projects;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ProjectSelectionDropdown(
          projects: projects,
          sites: _fetchedSites,
          initialProject: _selectedProject,
          initialSite: _selectedSite,
          isLoadingSites: _isLoadingSites,
          onSelected: (site, project) {
            setState(() {
              _selectedSite = site;
              _selectedProject = project;
            });
            _persistSelection(site, project);
            _fetchCounts();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 16),
        vertical: sizeContextOf(context, 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 75% Progress Card
          _buildProgressCard(),
          SizedBox(height: sizeContextOf(context, 16)),

          // Material Supply Chain Section
          _buildSectionHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Material Supply Chain',
            moduleCount: '4 Modules',
          ),
          SizedBox(height: sizeContextOf(context, 6)),
          Container(
            padding: EdgeInsets.all(sizeContextOf(context, 4)),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: [
                _buildGridCard(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  value: _purchaseReceiptCount.toString().padLeft(2, '0'),
                  title: 'Purchase Receipt',
                  subtitle: 'Inward inventory',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<PurchaseReceiptBloc>(),
                        child: PurchaseReceiptListView(
                          project: _selectedProject?.name,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildGridCard(
                  context: context,
                  icon: Icons.shopping_cart_outlined,
                  value: _materialRequestCount.toString().padLeft(2, '0'),
                  title: 'Material Request',
                  subtitle: 'Structural demand',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<MaterialRequestBloc>(),
                        child: MaterialRequestListView(
                          project: _selectedProject?.name,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildGridCard(
                  context: context,
                  icon: Icons.upload_outlined,
                  value: _materialIssueCount.toString().padLeft(2, '0'),
                  title: 'Material Issue',
                  subtitle: 'Site consumption',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<StockEntryBloc>(),
                        child: MaterialIssueListView(
                          stockEntryType: 'Material Issue',
                          project: _selectedProject?.name,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildGridCard(
                  context: context,
                  icon: Icons.swap_horiz_outlined,
                  value: _materialTransferCount.toString().padLeft(2, '0'),
                  title: 'Material Transfer',
                  subtitle: 'Inter-site move',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<StockEntryBloc>(),
                        child: MaterialTransferListView(
                          project: _selectedProject?.name,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sizeContextOf(context, 6)),

          // Resource Tracking Section
          _buildSectionHeader(
            icon: Icons.engineering_outlined,
            title: 'Resource Tracking',
            moduleCount: '2 Modules',
          ),
          SizedBox(height: sizeContextOf(context, 8)),
          Container(
            padding: EdgeInsets.all(sizeContextOf(context, 4)),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
              children: [
                _buildGridCard(
                  context: context,
                  icon: Icons.people_outline,
                  value: _manpowerUsageCount.toString().padLeft(2, '0'),
                  title: 'Manpower Usage',
                  subtitle: 'Subcontractor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<ManpowerUsageBloc>(),
                        child: ManpowerUsageListView(
                          project: _selectedProject?.name,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildGridCard(
                  context: context,
                  icon: Icons.build_outlined,
                  value: _equipmentUsageCount.toString().padLeft(2, '0'),
                  title: 'Equipment Usage',
                  subtitle: 'Machinery run-time',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<EquipmentUsageBloc>(),
                        child: EquipmentUsageListView(
                          project: _selectedProject?.name,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sizeContextOf(context, 6)),

          // Progress & Planning Section
          _buildSectionHeader(
            icon: Icons.assignment_outlined,
            title: 'Progress & Planning',
            moduleCount: '3 Modules',
          ),
          SizedBox(height: sizeContextOf(context, 10)),
          Container(
            padding: EdgeInsets.all(sizeContextOf(context, 12)),
            child: Column(
              children: [
                _buildListTile(
                  context: context,
                  icon: Icons.menu_book_outlined,
                  title: 'Site Diary',
                  subtitle: 'Day logs, weather & notes',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<SiteDiaryBloc>(),
                        child: const SiteDiaryListView(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: sizeContextOf(context, 10)),
                _buildListTile(
                  context: context,
                  icon: Icons.bar_chart_outlined,
                  title: 'Task Progress',
                  subtitle: 'Update execution %',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => sl<TaskProgressBloc>(),
                        child: const TaskProgressListPage(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: sizeContextOf(context, 10)),
                _buildListTile(
                  context: context,
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Daily Task Report',
                  subtitle: 'Consolidated HQ submission',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyProgressReportPage(
                        initialProject:
                            _selectedProject?.name ??
                            sl<ProjectSelectionService>().selectedProject,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sizeContextOf(context, 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    Widget titleWidget;

    if (_flowMode == HomepageFlowMode.dropdown) {
      leadingWidget = Builder(
        builder: (context) => InkWell(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            padding: EdgeInsets.all(sizeContextOf(context, 10)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: const Icon(Icons.menu, color: AppColors.onSurface, size: 24),
          ),
        ),
      );
      titleWidget = GestureDetector(
        onTap: () => _showSelectionSheet(context),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _selectedProject?.projectName ?? 'Select Project',
                    style: const TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: sizeContextOf(context, 4)),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryText,
                  size: 16,
                ),
              ],
            ),
            if (_selectedSite != null)
              Text(
                _selectedSite!,
                style: const TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      );
    } else {
      // List Flow Mode
      if (_listFlowState == ListFlowState.siteList) {
        leadingWidget = Builder(
          builder: (context) => InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: EdgeInsets.all(sizeContextOf(context, 10)),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline, width: 1),
              ),
              child: const Icon(
                Icons.menu,
                color: AppColors.onSurface,
                size: 24,
              ),
            ),
          ),
        );
        titleWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _companyName ?? 'Select Site',
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Select a site ',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        );
      } else if (_listFlowState == ListFlowState.projectList) {
        leadingWidget = InkWell(
          onTap: () {
            setState(() {
              _listFlowState = ListFlowState.siteList;
              _selectedSite = null;
            });
          },
          child: Container(
            padding: EdgeInsets.all(sizeContextOf(context, 10)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.onSurface,
              size: 24,
            ),
          ),
        );
        titleWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _selectedSite ?? 'Unspecified Site',
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Select Project',
              style: TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        );
      } else {
        // ListFlowState.dashboard
        leadingWidget = InkWell(
          onTap: () {
            setState(() {
              _listFlowState = ListFlowState.projectList;
              _selectedProject = null;
            });
          },
          child: Container(
            padding: EdgeInsets.all(sizeContextOf(context, 10)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.onSurface,
              size: 24,
            ),
          ),
        );
        titleWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _selectedProject?.projectName ?? 'Project Detail',
              style: const TextStyle(
                fontFamily: 'HankenGrotesk',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (_selectedSite != null)
              Text(
                _selectedSite!,
                style: const TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: sizeContextOf(context, 12),
            left: sizeContextOf(context, 16),
            right: sizeContextOf(context, 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leadingWidget,
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: sizeContextOf(context, 12),
                  ),
                  child: titleWidget,
                ),
              ),
              // Logo Container
              Container(
                width: sizeContextOf(context, 40),
                height: sizeContextOf(context, 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: Column(
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                String accountName = 'Guest User';
                String accountEmail = '';
                if (state is Authenticated) {
                  accountName = state.user.id;
                  accountEmail = state.user.username;
                }
                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(
                      Icons.person,
                      color: AppColors.onSurface,
                      size: 40,
                    ),
                  ),
                  accountName: Text(
                    accountName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  accountEmail: Text(
                    accountEmail,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.dashboard,
                color: AppColors.primaryText,
              ),
              title: const Text(
                'Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: true,
              selectedTileColor: AppColors.secondaryBackground,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_suggest_outlined,
                color: AppColors.primaryText,
              ),
              title: const Text('Homepage Layout'),
              onTap: () {
                Navigator.pop(context);
                _showFlowSelectionSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.fingerprint,
                color: AppColors.primaryText,
              ),
              title: const Text('Check in / Check out'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeCheckinPage(),
                  ),
                );
              },
            ),
            // ListTile(
            //   leading: const Icon(
            //     Icons.person_outline,
            //     color: AppColors.primaryText,
            //   ),
            //   title: const Text('Profile'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const ProfilePage()),
            //     );
            //   },
            // ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            SizedBox(height: sizeContextOf(context, 20)),
          ],
        ),
      ),
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) async {
          if (_flowMode == HomepageFlowMode.dropdown &&
              state is ProjectLoaded &&
              state.projects.isNotEmpty &&
              _selectedProject == null) {
            final activeProjectName =
                sl<ProjectSelectionService>().selectedProject;
            final activeSite = sl<ProjectSelectionService>().selectedSite;

            Project? matchedProject;
            if (activeProjectName != null) {
              final matches = state.projects.where(
                (p) => p.name == activeProjectName,
              );
              if (matches.isNotEmpty) {
                matchedProject = matches.first;
              }
            }

            if (matchedProject != null) {
              final site =
                  activeSite ?? matchedProject.site ?? 'Unspecified Site';
              setState(() {
                _selectedProject = matchedProject;
                _selectedSite = site;
              });
              await sl<ProjectSelectionService>().saveSelection(
                site: site,
                project: matchedProject.name,
              );
              _fetchCounts();
            } else {
              final firstProject = state.projects.first;
              final site = firstProject.site ?? 'Unspecified Site';
              setState(() {
                _selectedProject = firstProject;
                _selectedSite = site;
              });
              await sl<ProjectSelectionService>().saveSelection(
                site: site,
                project: firstProject.name,
              );
              _fetchCounts();
            }
          }
        },
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _selectedProject?.progress ?? 0.0;
    final progressPct = progress.clamp(0.0, 100.0);
    final status = _selectedProject?.status ?? 'Unknown';
    final priority = _selectedProject?.priority ?? 'Medium';
    final isActive = _selectedProject?.isActive ?? false;
    final perGrossMargin = _selectedProject?.perGrossMargin;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(sizeContextOf(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progressPct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF27372B),
                  height: 1.0,
                ),
              ),
              Row(
                children: [
                  // Active/Inactive Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sizeContextOf(context, 10),
                      vertical: sizeContextOf(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                          : Colors.grey.shade700.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? const Color(0xFF1B5E20)
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  SizedBox(width: sizeContextOf(context, 8)),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sizeContextOf(context, 10),
                      vertical: sizeContextOf(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27372B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF27372B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: sizeContextOf(context, 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Project Completion',
                style: TextStyle(
                  fontFamily: 'HankenGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF27372B),
                ),
              ),
              // if (perGrossMargin != null)
              // Text(
              //   'PGM: ${perGrossMargin.toStringAsFixed(1)}%',
              //   style: const TextStyle(
              //     fontFamily: 'HankenGrotesk',
              //     fontSize: 13,
              //     fontWeight: FontWeight.w700,
              //     color: Color(0xFF27372B),
              //   ),
              // ),
            ],
          ),
          SizedBox(height: sizeContextOf(context, 10)),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPct / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF27372B),
              ),
              minHeight: 6,
            ),
          ),
          SizedBox(height: sizeContextOf(context, 14)),
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // Priority Pill
              _buildProgressPill(Icons.flag_outlined, '$priority Priority'),
              if (perGrossMargin != null)
                _buildProgressPill(
                  Icons.pie_chart_outline,
                  '${perGrossMargin.toStringAsFixed(1)}%  Gross Margin',
                ),
              if (_selectedProject?.projectType != null &&
                  _selectedProject!.projectType!.isNotEmpty)
                _buildProgressPill(
                  Icons.category_outlined,
                  _selectedProject!.projectType!,
                ),
              if (_selectedProject?.department != null &&
                  _selectedProject!.department!.isNotEmpty)
                _buildProgressPill(
                  Icons.business_outlined,
                  _selectedProject!.department!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPill(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 10),
        vertical: sizeContextOf(context, 6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF27372B)),
          SizedBox(width: sizeContextOf(context, 6)),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF27372B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String moduleCount,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(sizeContextOf(context, 6)),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F2E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryContainer, size: 18),
        ),
        SizedBox(width: sizeContextOf(context, 8)),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.primaryText,
          ),
        ),
        const Spacer(),
        Text(
          moduleCount,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 10.0),
              vertical: sizeContextOf(context, 8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(sizeContextOf(context, 6)),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.onSurface, size: 22),
                    ),
                    if (_isLoadingCounts)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryContainer,
                          ),
                        ),
                      )
                    else
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                          height: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: sizeContextOf(context, 6)),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Material(
        // return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 14),
              vertical: sizeContextOf(context, 10),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(sizeContextOf(context, 8)),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.onSurface, size: 18),
                ),
                SizedBox(width: sizeContextOf(context, 12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      SizedBox(height: sizeContextOf(context, 2)),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryText,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_flowMode == HomepageFlowMode.dropdown) {
      return _buildDashboardContent();
    } else {
      switch (_listFlowState) {
        case ListFlowState.siteList:
          return _buildSiteListView();
        case ListFlowState.projectList:
          return _buildProjectListView();
        case ListFlowState.dashboard:
          return _buildDashboardContent();
      }
    }
  }

  Widget _buildSiteListView() {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state is ProjectLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<String> sites = [];
        if (state is ProjectLoaded) {
          sites = state.projects
              .map((p) => p.site ?? 'Unspecified Site')
              .toSet()
              .toList();
        } else if (_fetchedSites.isNotEmpty) {
          sites = _fetchedSites;
        }

        if (sites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                const Text(
                  'No sites found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProjectBloc>().add(GetProjectsRequested());
            await Future.wait([
              _fetchSites(),
              _fetchCompany(),
            ]);
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 16),
              vertical: sizeContextOf(context, 12),
            ),
            itemCount: sites.length,
            itemBuilder: (context, index) {
              final site = sites[index];
              int projectCount = 0;
              if (state is ProjectLoaded) {
                projectCount = state.projects
                    .where((p) => (p.site ?? 'Unspecified Site') == site)
                    .length;
              }

              return Card(
                elevation: 0,
                margin: EdgeInsets.only(bottom: sizeContextOf(context, 12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outline, width: 1),
                ),
                color: AppColors.surface,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      _selectedSite = site;
                      _listFlowState = ListFlowState.projectList;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.all(sizeContextOf(context, 16)),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(sizeContextOf(context, 12)),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F2E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primaryContainer,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: sizeContextOf(context, 16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site,
                                style: const TextStyle(
                                  fontFamily: 'HankenGrotesk',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              SizedBox(height: sizeContextOf(context, 4)),
                              Text(
                                '$projectCount ${projectCount == 1 ? "Project" : "Projects"}',
                                style: const TextStyle(
                                  fontFamily: 'HankenGrotesk',
                                  fontSize: 13,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectListView() {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state is ProjectLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Project> siteProjects = [];
        if (state is ProjectLoaded) {
          siteProjects = state.projects
              .where((p) => (p.site ?? 'Unspecified Site') == _selectedSite)
              .toList();
        }

        if (siteProjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_late_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                const Text(
                  'No projects under this site',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                SizedBox(height: sizeContextOf(context, 16)),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _listFlowState = ListFlowState.siteList;
                      _selectedSite = null;
                    });
                  },
                  child: const Text('Back to Sites'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProjectBloc>().add(GetProjectsRequested());
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: sizeContextOf(context, 16),
              vertical: sizeContextOf(context, 12),
            ),
            itemCount: siteProjects.length,
            itemBuilder: (context, index) {
              final project = siteProjects[index];
              final progressPct = (project.progress).clamp(0.0, 100.0);

              return Card(
                elevation: 0,
                margin: EdgeInsets.only(bottom: sizeContextOf(context, 12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.outline, width: 1),
                ),
                color: AppColors.surface,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    setState(() {
                      _selectedProject = project;
                      _listFlowState = ListFlowState.dashboard;
                    });
                    await _persistSelection(_selectedSite!, project);
                    _fetchCounts();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(sizeContextOf(context, 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project.projectName,
                                style: const TextStyle(
                                  fontFamily: 'HankenGrotesk',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: sizeContextOf(context, 8)),
                            _buildProjectStatusBadge(project.status),
                          ],
                        ),
                        if ((project.projectType != null &&
                                project.projectType!.isNotEmpty) ||
                            (project.priority != null &&
                                project.priority!.isNotEmpty)) ...[
                          SizedBox(height: sizeContextOf(context, 8)),
                          Row(
                            children: [
                              if (project.projectType != null &&
                                  project.projectType!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: sizeContextOf(context, 8),
                                    vertical: sizeContextOf(context, 4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryBackground,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    project.projectType!,
                                    style: const TextStyle(
                                      fontFamily: 'HankenGrotesk',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              if (project.projectType != null &&
                                  project.projectType!.isNotEmpty &&
                                  project.priority != null &&
                                  project.priority!.isNotEmpty)
                                SizedBox(width: sizeContextOf(context, 8)),
                              if (project.priority != null &&
                                  project.priority!.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: sizeContextOf(context, 8),
                                    vertical: sizeContextOf(context, 4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(
                                      project.priority,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flag_outlined,
                                        size: 10,
                                        color: _getPriorityColor(
                                          project.priority,
                                        ),
                                      ),
                                      SizedBox(
                                        width: sizeContextOf(context, 4),
                                      ),
                                      Text(
                                        project.priority!,
                                        style: TextStyle(
                                          fontFamily: 'HankenGrotesk',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: _getPriorityColor(
                                            project.priority,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(height: sizeContextOf(context, 12)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Progress',
                              style: TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            Text(
                              '${progressPct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sizeContextOf(context, 6)),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPct / 100,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        SizedBox(height: sizeContextOf(context, 12)),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.secondaryText,
                            ),
                            SizedBox(width: sizeContextOf(context, 6)),
                            Text(
                              project.expectedStartDate != null &&
                                      project.expectedEndDate != null
                                  ? '${DateFormat('dd MMM yyyy').format(project.expectedStartDate!)} - ${DateFormat('dd MMM yyyy').format(project.expectedEndDate!)}'
                                  : project.expectedEndDate != null
                                  ? 'Ends: ${DateFormat('dd MMM yyyy').format(project.expectedEndDate!)}'
                                  : project.expectedStartDate != null
                                  ? 'Starts: ${DateFormat('dd MMM yyyy').format(project.expectedStartDate!)}'
                                  : 'No dates set',
                              style: const TextStyle(
                                fontFamily: 'HankenGrotesk',
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProjectStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'open':
      case 'active':
        color = const Color(0xFF2E7D32);
        break;
      case 'completed':
        color = const Color(0xFF1565C0);
        break;
      case 'on hold':
        color = const Color(0xFFEF6C00);
        break;
      default:
        color = AppColors.secondaryText;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeContextOf(context, 8),
        vertical: sizeContextOf(context, 4),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: 'HankenGrotesk',
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showFlowSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 20)),
                  const Text(
                    'Homepage Layout',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 6)),
                  const Text(
                    'Choose how you want to select and navigate your projects.',
                    style: TextStyle(
                      fontFamily: 'HankenGrotesk',
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 20)),
                  InkWell(
                    onTap: () async {
                      setSheetState(() {
                        _flowMode = HomepageFlowMode.dropdown;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('homepage_flow_mode', 'dropdown');
                      setState(() {});
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(sizeContextOf(context, 16)),
                      decoration: BoxDecoration(
                        color: _flowMode == HomepageFlowMode.dropdown
                            ? const Color(0xFFE1F2E9)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _flowMode == HomepageFlowMode.dropdown
                              ? AppColors.primary
                              : AppColors.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_drop_down_circle_outlined,
                            color: _flowMode == HomepageFlowMode.dropdown
                                ? AppColors.primary
                                : AppColors.secondaryText,
                            size: 24,
                          ),
                          SizedBox(width: sizeContextOf(context, 16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'App Bar Dropdown',
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _flowMode == HomepageFlowMode.dropdown
                                        ? AppColors.primaryText
                                        : AppColors.onSurface,
                                  ),
                                ),
                                SizedBox(height: sizeContextOf(context, 2)),
                                const Text(
                                  'Quickly switch sites and projects using dropdown selector on the dashboard.',
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<HomepageFlowMode>(
                            value: HomepageFlowMode.dropdown,
                            groupValue: _flowMode,
                            activeColor: AppColors.primary,
                            onChanged: (val) async {
                              if (val != null) {
                                setSheetState(() {
                                  _flowMode = val;
                                });
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'homepage_flow_mode',
                                  'dropdown',
                                );
                                setState(() {});
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: sizeContextOf(context, 12)),
                  InkWell(
                    onTap: () async {
                      setSheetState(() {
                        _flowMode = HomepageFlowMode.listFlow;
                        _listFlowState = ListFlowState.siteList;
                        _selectedSite = null;
                        _selectedProject = null;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('homepage_flow_mode', 'listFlow');
                      setState(() {});
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(sizeContextOf(context, 16)),
                      decoration: BoxDecoration(
                        color: _flowMode == HomepageFlowMode.listFlow
                            ? const Color(0xFFE1F2E9)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _flowMode == HomepageFlowMode.listFlow
                              ? AppColors.primary
                              : AppColors.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.list_alt_outlined,
                            color: _flowMode == HomepageFlowMode.listFlow
                                ? AppColors.primary
                                : AppColors.secondaryText,
                            size: 24,
                          ),
                          SizedBox(width: sizeContextOf(context, 16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Site & Project List Navigation',
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        _flowMode == HomepageFlowMode.listFlow
                                        ? AppColors.primaryText
                                        : AppColors.onSurface,
                                  ),
                                ),
                                SizedBox(height: sizeContextOf(context, 2)),
                                const Text(
                                  'Start with a site list, choose a site, and select a project to open the dashboard.',
                                  style: TextStyle(
                                    fontFamily: 'HankenGrotesk',
                                    fontSize: 12,
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<HomepageFlowMode>(
                            value: HomepageFlowMode.listFlow,
                            groupValue: _flowMode,
                            activeColor: AppColors.primary,
                            onChanged: (val) async {
                              if (val != null) {
                                setSheetState(() {
                                  _flowMode = val;
                                  _listFlowState = ListFlowState.siteList;
                                  _selectedSite = null;
                                  _selectedProject = null;
                                });
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString(
                                  'homepage_flow_mode',
                                  'listFlow',
                                );
                                setState(() {});
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }
}
