// lib/screens/warranties_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/warranty.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'warranty_form_screen.dart';

class WarrantiesScreen extends StatefulWidget {
  const WarrantiesScreen({super.key});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  final _db = DatabaseService();
  List<Warranty> _warranties = [];
  String _filter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _db.getWarranties();
    setState(() {
      _warranties = data;
      _loading = false;
    });
  }

  List<Warranty> get _filtered {
    switch (_filter) {
      case 'expiring':
        return _warranties.where((w) => w.status == 'expiring').toList();
      case 'active':
        return _warranties.where((w) => w.status == 'active').toList();
      default:
        return _warranties;
    }
  }

  Future<void> _delete(Warranty w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Изтриване'),
        content: Text('Изтриване на "${w.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отказ')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Изтрий', style: TextStyle(color: AppTheme.accentRed))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteWarranty(w.id!);
      await NotificationService().scheduleAllNotifications();
      _load();
    }
  }

  Future<void> _openForm({Warranty? warranty}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => WarrantyFormScreen(warranty: warranty)),
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
                            itemBuilder: (_, i) =>
                                _WarrantyCard(
                              warranty: _filtered[i],
                              onEdit: () => _openForm(warranty: _filtered[i]),
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
        label: const Text('Нова гаранция'),
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
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('Няма гаранции',
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

class _WarrantyCard extends StatelessWidget {
  final Warranty warranty;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WarrantyCard(
      {required this.warranty, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(warranty.status);
    final fmt = DateFormat('dd MMM yyyy', 'bg');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warranty.status == 'active'
              ? AppTheme.border
              : color.withOpacity(0.5),
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.receipt_long, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(warranty.title,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${warranty.category}${warranty.modelNumber != null ? ' • ${warranty.modelNumber}' : ''}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: warranty.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _InfoCol(
                            label: 'ДАТА НА ПОКУПКА',
                            value: fmt.format(warranty.purchaseDate))),
                    Expanded(
                        child: _InfoCol(
                            label: 'ИЗТИЧА НА',
                            value: fmt.format(warranty.expiryDate),
                            valueColor: warranty.status != 'active'
                                ? color
                                : null)),
                    Expanded(
                        child: _InfoCol(
                            label: 'ОСТАВАТ',
                            value: warranty.daysRemaining < 0
                                ? 'Изтекла'
                                : '${warranty.daysRemaining} дни',
                            valueColor: color)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: warranty.progressPercent,
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(warranty.progressPercent * 100).toInt()}% до изтичане',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11),
                ),
                if (warranty.status == 'expiring')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.accentOrange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Изтича след ${warranty.daysRemaining} дни!',
                          style: const TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: AppTheme.textSecondary, size: 20),
                  onPressed: () {},
                  tooltip: 'Снимка на касова бележка',
                ),
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

class _InfoCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCol(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor ?? AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
