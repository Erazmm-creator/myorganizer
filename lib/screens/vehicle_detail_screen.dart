// lib/screens/vehicle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../theme.dart';
import 'document_form_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _db = DatabaseService();
  late Vehicle _vehicle;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _reload();
  }

  Future<void> _reload() async {
    final vehicles = await _db.getVehicles();
    final updated =
        vehicles.where((v) => v.id == _vehicle.id).firstOrNull;
    if (updated != null && mounted) {
      setState(() => _vehicle = updated);
    }
  }

  Future<void> _openDocForm({VehicleDocument? doc}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              DocumentFormScreen(vehicleId: _vehicle.id!, document: doc)),
    );
    if (result == true) {
      _changed = true;
      await _reload();
    }
  }

  Future<void> _deleteDoc(VehicleDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Изтриване'),
        content: Text('Изтриване на "${doc.type}"?'),
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
      await _db.deleteDocument(doc.id!);
      _changed = true;
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_vehicle.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vehicle info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.directions_car,
                        color: AppTheme.accent, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_vehicle.name,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text(_vehicle.licensePlate,
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      if (_vehicle.brand != null || _vehicle.year != null)
                        Text(
                          [
                            if (_vehicle.brand != null) _vehicle.brand!,
                            if (_vehicle.model != null) _vehicle.model!,
                            if (_vehicle.year != null)
                              _vehicle.year.toString(),
                          ].join(' '),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Документи',
                    style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () => _openDocForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Добави'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_vehicle.documents.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_outlined,
                        size: 48, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text('Няма добавени документи',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Натисни "Добави" за да добавиш',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            else
              ..._vehicle.documents.map(
                (doc) => _DocumentCard(
                  doc: doc,
                  fmt: fmt,
                  onEdit: () => _openDocForm(doc: doc),
                  onDelete: () => _deleteDoc(doc),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final VehicleDocument doc;
  final DateFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentCard(
      {required this.doc,
      required this.fmt,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(doc.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: doc.status == 'active'
              ? AppTheme.border
              : color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.article_outlined, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(doc.type,
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                    ),
                    _StatusBadge(status: doc.status, days: doc.daysRemaining),
                  ],
                ),
                if (doc.validFrom != null || doc.validTo != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (doc.validFrom != null)
                        Expanded(
                          child: _InfoCol(
                              label: 'ВАЛИДНО ОТ',
                              value: fmt.format(doc.validFrom!)),
                        ),
                      if (doc.validTo != null)
                        Expanded(
                          child: _InfoCol(
                              label: 'ВАЛИДНО ДО',
                              value: fmt.format(doc.validTo!),
                              valueColor: doc.status != 'active' ? color : null),
                        ),
                      if (doc.validTo != null)
                        Expanded(
                          child: _InfoCol(
                              label: 'ОСТАВАТ',
                              value: doc.daysRemaining < 0
                                  ? 'Изтекъл'
                                  : '${doc.daysRemaining} дни',
                              valueColor: color),
                        ),
                    ],
                  ),
                ],
                if (doc.status == 'expiring')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppTheme.accentOrange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Изтича след ${doc.daysRemaining} дни!',
                          style: const TextStyle(
                              color: AppTheme.accentOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                if (doc.notes != null && doc.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(doc.notes!,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
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
                  tooltip: 'Снимка',
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
  final int days;
  const _StatusBadge({required this.status, required this.days});

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
