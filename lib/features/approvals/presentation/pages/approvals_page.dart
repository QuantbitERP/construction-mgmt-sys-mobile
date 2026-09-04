import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/project_selection_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/project_selection_dropdown.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/bloc/project_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../attendance/presentation/pages/employee_checkin_page.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../../domain/entities/approval_item.dart';
import '../widgets/approval_item_card.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  List<String> _fetchedSites = [];
  bool _isLoadingSites = false;
  Project? _selectedProject;
  String? _selectedSite;

  @override
  void initState() {
    super.initState();
    sl<ProjectSelectionService>().addListener(_onUniversalProjectChanged);
    _fetchSites();
    // Trigger initial load of approvals using active project
    final activeProj = sl<ProjectSelectionService>().selectedProject;
    context.read<ApprovalsBloc>().add(LoadApprovals(project: activeProj));
  }

  @override
  void dispose() {
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
      try {
        matchedProject = projectState.projects.firstWhere(
          (p) => p.name == universalProject,
        );
      } catch (_) {}
    }

    setState(() {
      _selectedProject = matchedProject;
      _selectedSite = universalSite;
    });

    context.read<ApprovalsBloc>().add(
      LoadApprovals(project: universalProject),
    );
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
      if (!mounted) return;
      // Fallback: collect sites from project bloc loaded state
      final state = context.read<ProjectBloc>().state;
      if (state is ProjectLoaded) {
        _fetchedSites = state.projects
            .map((p) => p.site ?? 'Unspecified Site')
            .toSet()
            .toList();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSites = false;
        });
      }
    }
  }

  void _syncSelectedProjectAndSite(List<Project> projects) {
    final activeProjectName = sl<ProjectSelectionService>().selectedProject;
    final activeSiteName = sl<ProjectSelectionService>().selectedSite;

    if (activeProjectName != null) {
      if (_selectedProject == null ||
          _selectedProject!.name != activeProjectName) {
        try {
          _selectedProject = projects.firstWhere(
            (p) => p.name == activeProjectName,
          );
        } catch (_) {}
      }
    }
    _selectedSite = activeSiteName;
  }

  void _showSelectionSheet(BuildContext context, List<Project> projects) {
    final approvalsBloc = context.read<ApprovalsBloc>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BlocProvider.value(
          value: approvalsBloc,
          child: ProjectSelectionDropdown(
            projects: projects,
            sites: _fetchedSites,
            initialProject: _selectedProject,
            initialSite: _selectedSite,
            isLoadingSites: _isLoadingSites,
            onSelected: (site, project) async {
              if (mounted) {
                setState(() {
                  _selectedSite = site;
                  _selectedProject = project;
                });
              }
              await sl<ProjectSelectionService>().saveSelection(
                site: site,
                project: project.name,
              );
              // Reload approvals for the new project!
              approvalsBloc.add(
                LoadApprovals(project: project.name),
              );
            },
          ),
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

  @override
  Widget build(BuildContext context) {
    // 1. Fetch available projects from ProjectBloc
    final projectState = context.watch<ProjectBloc>().state;
    List<Project> projects = [];
    if (projectState is ProjectLoaded) {
      projects = projectState.projects;
      _syncSelectedProjectAndSite(projects);
    }

    // 2. Resolve Active Project & Site details
    final activeProjectName =
        _selectedProject?.projectName ??
        _selectedProject?.name ??
        sl<ProjectSelectionService>().selectedProject ??
        'Select Project';
    final activeSiteName =
        _selectedSite ?? sl<ProjectSelectionService>().selectedSite;

    // 3. Build Homepage-styled Leading Menu Button
    final leadingWidget = Builder(
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

    // 4. Build Homepage-styled Center Selector Title Widget
    final titleWidget = GestureDetector(
      onTap: projects.isNotEmpty
          ? () => _showSelectionSheet(context, projects)
          : null,
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
                  activeProjectName,
                  style: const TextStyle(
                    fontFamily: 'HankenGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (projects.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primaryText,
                  size: 16,
                ),
              ],
            ],
          ),
          if (activeSiteName != null)
            Text(
              activeSiteName,
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

    return BlocBuilder<ApprovalsBloc, ApprovalsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2FAF6),
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
                  onTap: () => Navigator.pop(context),
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
                    Navigator.pop(context);
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                ),
              ],
            ),
          ),
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
                  // Homepage Default Logo Circle Avatar
                  Container(
                    width: sizeContextOf(context, 40),
                    height: sizeContextOf(context, 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 1,
                      ),
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
          body: Column(
            children: [
              // Banner area with dynamic counts
              Container(
                color: const Color(0xFF319F77),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildApprovalCountCard(
                      '${state.pendingCount}',
                      'Pending',
                      active: state.selectedFilter == 'Pending',
                      onTap: () => _changeFilter('Pending'),
                    ),
                    _buildApprovalCountCard(
                      '${state.approvedCount}',
                      'Approved',
                      active: state.selectedFilter == 'Approved',
                      onTap: () => _changeFilter('Approved'),
                    ),
                    _buildApprovalCountCard(
                      '${state.rejectedCount}',
                      'Rejected',
                      active: state.selectedFilter == 'Rejected',
                      onTap: () => _changeFilter('Rejected'),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              // Container(
              //   color: Colors.white,
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 16.0,
              //     vertical: 10.0,
              //   ),
              //   child: Row(
              //     children: [
              //       _buildFilterChip('Pending', state.selectedFilter),
              //       const SizedBox(width: 8),
              //       _buildFilterChip('Approved', state.selectedFilter),
              //       const SizedBox(width: 8),
              //       _buildFilterChip('Rejected', state.selectedFilter),
              //     ],
              //   ),
              // ),

              // List of approvals
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<ApprovalsBloc>().add(const RefreshApprovals());
                  },
                  child: _buildListContent(state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApprovalCountCard(
    String count,
    String label, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: active ? const Color(0xFF319F77) : Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? const Color(0xFF319F77) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(ApprovalsState state) {
    List<ApprovalItem> displayItems = [];
    if (state.selectedFilter == 'Pending') {
      displayItems = state.pendingItems;
    } else if (state.selectedFilter == 'Approved') {
      displayItems = state.approvedItems;
    } else if (state.selectedFilter == 'Rejected') {
      displayItems = state.rejectedItems;
    }

    if (state.status == ApprovalsStatus.loading && displayItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == ApprovalsStatus.failure && displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load approvals',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? '',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ApprovalsBloc>().add(const LoadApprovals());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF319F77),
              ),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No ${state.selectedFilter.toLowerCase()} approvals found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        return ApprovalItemCard(item: item);
      },
    );
  }

  void _changeFilter(String filter) {
    context.read<ApprovalsBloc>().add(ChangeApprovalsFilter(filter));
  }
}
