import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';
import '../../cubits/paper_selection/paper_selection_cubit.dart';
import '../../../app/routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              const _SectionHeader('Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: state.isDarkMode,
                onChanged: (_) =>
                    context.read<SettingsCubit>().toggleDarkMode(),
              ),
              const Divider(),
              const _SectionHeader('AI Behaviour'),
              ListTile(
                title: const Text('Expertise Level'),
                subtitle: Text(_expertiseDescription(state.expertiseLevel)),
                trailing: DropdownButton<String>(
                  value: state.expertiseLevel,
                  items: const [
                    DropdownMenuItem(
                        value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(
                        value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(
                        value: 'expert', child: Text('Expert')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      context.read<SettingsCubit>().setExpertiseLevel(v);
                    }
                  },
                ),
              ),
              const Divider(),
              const _SectionHeader('Data'),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Clear All Data',
                    style: TextStyle(color: Colors.red)),
                subtitle: const Text(
                    'Delete all chat history and cached papers'),
                onTap: () => _confirmClear(context),
              ),
              const Divider(),
              const _SectionHeader('About'),
              ListTile(
                title: const Text('Research Assistant'),
                subtitle: const Text('AI-powered academic paper analysis'),
                trailing: const Text('v1.0.0',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _expertiseDescription(String level) {
    switch (level) {
      case 'beginner':
        return 'Simplified explanations, no jargon';
      case 'expert':
        return 'Technical depth, assumes domain knowledge';
      default:
        return 'Balanced explanations for researchers';
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will delete all chat sessions and cached paper data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // Clear Hive data + reset settings state
      await context.read<SettingsCubit>().clearAllData();

      if (!context.mounted) return;

      // Reset in-memory paper selection so the UI reflects the cleared state
      context.read<PaperSelectionCubit>().clearAll();

      // Pop the entire navigation stack back to the search root so no page
      // (chat, paper details, etc.) holds stale in-memory state
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.search,
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data cleared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
