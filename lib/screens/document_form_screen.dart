// lib/screens/document_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../theme.dart';

class DocumentFormScreen extends StatefulWidget {
  final int vehicleId;
  final VehicleDocument? document;
  const DocumentFormScreen(
      {super.key, required this.vehicleId, this.document});

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();

  late TextEditingController _typeCtrl;
  late TextEditingController _notesCtrl;
  DateTime? _validFrom;
  DateTime? _validTo;
  bool _saving = false;

  final List<String> _docTypes = [
    'Гражданска отговорност',
    'Каско',
    'ГТП',
    'Винетка',
    'Карта СБА',
    'Друг документ',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _typeCtrl = TextEditingController(text: d?.type ?? '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');
    _validFrom = d?.validFrom;
    _validTo = d?.validTo;
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom
        ? (_validFrom ?? DateTime.now())
        : (_validTo ?? DateTime.now().add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
        } else {
          _validTo = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final doc = VehicleDocument(
      id: widget.document?.id,
      vehicleId: widget.vehicleId,
      type: _typeCtrl.text.trim(),
      validFrom: _validFrom,
      validTo: _validTo,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      imagePath: widget.document?.imagePath,
    );

    if (widget.document == null) {
      await _db.insertDocument(doc);
    } else {
      await _db.updateDocument(doc);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    final isEdit = widget.document != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактиране на документ' : 'Нов документ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildLabel('Вид документ *'),
            TextFormField(
              controller: _typeCtrl,
              decoration: InputDecoration(
                hintText: 'напр. Гражданска отговорност',
                prefixIcon: const Icon(Icons.article_outlined),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  color: AppTheme.cardDark,
                  onSelected: (val) =>
                      setState(() => _typeCtrl.text = val),
                  itemBuilder: (_) => _docTypes
                      .map((t) =>
                          PopupMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Моля въведи вид документ' : null,
            ),
            const SizedBox(height: 24),

            _buildLabel('Валидно от'),
            _DateButton(
              label: _validFrom != null
                  ? fmt.format(_validFrom!)
                  : 'Избери дата',
              onTap: () => _pickDate(true),
              hasValue: _validFrom != null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Валидно до'),
            _DateButton(
              label: _validTo != null
                  ? fmt.format(_validTo!)
                  : 'Избери дата',
              onTap: () => _pickDate(false),
              hasValue: _validTo != null,
              color: AppTheme.accentOrange,
            ),
            const SizedBox(height: 16),

            _buildLabel('Бележки (по желание)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'напр. полица номер, компания...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(isEdit ? 'Запази промените' : 'Добави документ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5)),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool hasValue;
  final Color? color;

  const _DateButton(
      {required this.label,
      required this.onTap,
      required this.hasValue,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardDarker,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: hasValue ? c : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: hasValue ? AppTheme.textPrimary : AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
