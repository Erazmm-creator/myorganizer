// lib/screens/vehicles_screen.dart

import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'vehicle_form_screen.dart';
import 'vehicle_detail_screen.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _db = DatabaseService();
  List<Vehicle> _vehicles = [];
  String _filter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _db.getVehicles();
    setState(() {
      _vehicles = data;
      _loading = false;
    });
  }

  List<Vehicle> get _filtered {
    switch (_filter) {
      case 'expiring':
        return _vehicles
            .where((v) =>
                v.worstStatus == 'expiring' || v.worstStatus == 'expired')
            .toList();
      case 'active':
        return _vehicles.where((v) => v.worstStatus == 'active').toList();
      default:
        return _vehicles;
    }
  }

  Future<void> _delete(Vehicle v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Изтриване'),
        content: Text('Изтриване на "${v.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отказ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Изтрий',
                  style: TextStyle(color: AppTheme.accentRed))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteVehicle(v.id!);
      await NotificationService().scheduleAllNotifications();
      _load();
    }
  }

  Future<void> _openForm({Vehicle? vehicle}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => VehicleFormScreen(vehicle: vehicle)),
    );
    if (result == true) {
      await NotificationService().scheduleAllNotifications();
      _load();
    }
  }

  Future<void> _openDetail(Vehicle v) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: v)),
    );
    if (result == true) {
      await NotificationService().scheduleAllNotifications();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _VehicleCard(
                              vehicle: _filtered[i],
                              onTap: () => _openDetail(_filtered[i]),
                              onEdit: () => _openForm(vehicle: _filtered[i]),
                              onDelete: () => _delete(_filtered[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Нов автомобил'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
                label: 'Всички',
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all')),
            const SizedBox(width: 8),
            _FilterChip(
                label: '⚠ Изтичащи',
                selected: _filter == 'expiring',
                onTap: () => setState(() => _filter = 'expiring'),
                color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            _FilterChip(
                label: '✓ Активни',
                selected: _filter == 'active',
                onTap: () => setState(() => _filter = 'active'),
                color: AppTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('Няма автомобили',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Натисни + за да добавиш',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.15) : AppTheme.cardDarker,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? c : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard(
      {required this.vehicle,
      required this.onTap,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(vehicle.worstStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: vehicle.worstStatus == 'active'
                ? AppTheme.border
                : statusColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.directions_car,
                            color: statusColor, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            Text(vehicle.licensePlate,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      _StatusBadge(status: vehicle.worstStatus),
                    ],
                  ),

                  if (vehicle.documents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.border, height: 1),
                    const SizedBox(height: 12),
                    ...vehicle.documents.map((doc) => _DocRow(doc: doc)),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDarker,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppTheme.textSecondary, size: 16),
                          const SizedBox(width: 8),
                          Text('Натисни за да добавиш документи',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppTheme.border, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppTheme.textSecondary, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Редактирай',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.accentRed, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Изтрий',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final VehicleDocument doc;
  const _DocRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(doc.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(doc.type,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 13)),
          ),
          if (doc.validTo != null)
            Text(
              doc.daysRemaining < 0
                  ? 'Изтекъл'
                  : '${doc.daysRemaining} дни',
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            )
          else
            const Text('—',
                style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    String label;
    switch (status) {
      case 'expired':
        label = 'Изтекъл';
        break;
      case 'expiring':
        label = 'Изтича';
        break;
      default:
        label = 'Активен';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
