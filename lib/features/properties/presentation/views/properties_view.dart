import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/property_viewmodel.dart';
import '../widgets/property_card.dart';
import 'create_property_view.dart';
import '../../domain/entities/property_entity.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class PropertiesView extends StatefulWidget {
  const PropertiesView({super.key});

  @override
  State<PropertiesView> createState() => _PropertiesViewState();
}

class _PropertiesViewState extends State<PropertiesView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<PropertyViewModel>().loadProperties());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PropertyViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Propiedades', style: theme.textTheme.titleLarge),
        actions: [
          Consumer<AuthViewModel>(
            builder: (context, authVM, _) {
              final role = authVM.user?.role ?? 'USER';
              if (role == 'SELLER' || role == 'AGENCY' || role == 'ADMIN') {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePropertyView()),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: _buildBody(vm, theme),
    );
  }

  Widget _buildBody(PropertyViewModel vm, ThemeData theme) {
    switch (vm.status) {
      case PropertyStatus2.loading:
      case PropertyStatus2.initial:
        return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        );
      case PropertyStatus2.error:
        return Center(
          child: Text(vm.errorMessage ?? 'Error',
              style: TextStyle(color: theme.colorScheme.error)),
        );
      case PropertyStatus2.loaded:
        if (vm.properties.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_work_outlined,
                    size: 64, color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text('No hay propiedades',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vm.properties.length,
          itemBuilder: (_, i) => PropertyCard(
            property: vm.properties[i],
            onDelete: () => vm.deleteProperty(vm.properties[i].id),
            segmento: vm.getSegmento(vm.properties[i].id),
          ),
        );
    }
  }
}