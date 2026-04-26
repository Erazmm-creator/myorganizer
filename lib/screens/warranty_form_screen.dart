// lib/screens/warranty_form_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/warranty.dart';
import '../services/database_service.dart';
import '../theme.dart';

class WarrantyFormScreen extends StatefulWidget {
  final Warranty? warranty;
  const WarrantyFormScreen({super.key, this.warranty});

  @override
  State<WarrantyFormScreen> createState() => _WarrantyFormScreenState();
}

class _WarrantyFormScreenState extends State<WarrantyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();

  late TextEditingController _titleCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _modelCtrl;
  DateTime _purchaseDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  final List<String> _categories = [
    'Електроуреди',
    'Техника',
    'Мебели',
    'Автомобил',
    'Инструменти',
    'Друго',
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.warranty;
    _titleCtrl = TextEditingController(text: w?.title ?? '');
    _categoryCtrl = TextEditingController(text: w?.category ?? '');
    _modelCtrl = TextEditingController(text: w?.modelNumber ?? '');
    if (w != null) {
      _purchaseDate = w.purchaseDate;
      _expiryDate = w.expiryDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isPurchase) async {
    final initial = isPurchase ? _purchaseDate : _expiryDate;
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
        if (isPurchase) {
          _purchaseDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final warranty = Warranty(
      id: widget.warranty?.id,
      title: _titleCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      modelNumber:
          _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      purchaseDate: _purchaseDate,
      expiryDate: _expiryDate,
      imagePath: widget.warranty?.imagePath,
    );

    if (widget.warranty == null) {
      await _db.insertWarranty(warranty);
    } else {
      await _db.updateWarranty(warranty);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    final isEdit = widget.warranty != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактиране' : 'Нова гаранция'),
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
            _buildLabel('Наименование *'),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'напр. Телевизор Samsung',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Моля въведи наименование' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Категория *'),
            TextFormField(
              controller: _categoryCtrl,
              decoration: InputDecoration(
                hintText: 'напр. Електроуреди',
                prefixIcon: const Icon(Icons.category_outlined),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  color: AppTheme.cardDark,
                  onSelected: (val) =>
                      setState(() => _categoryCtrl.text = val),
                  itemBuilder: (_) => _categories
                      .map((c) =>
                          PopupMenuItem(value: c, child: Text(c)))
                      .toList(),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Моля въведи категория' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Модел номер (по желание)'),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                hintText: 'напр. QN65Q80C',
                prefixIcon: Icon(Icons.qr_code_outlined),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Дата на покупка'),
            _DateButton(
              label: fmt.format(_purchaseDate),
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 16),

            _buildLabel('Дата на изтичане'),
            _DateButton(
              label: fmt.format(_expiryDate),
              onTap: () => _pickDate(false),
              color: AppTheme.accentOrange,
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
                    : Text(isEdit ? 'Запази промените' : 'Добави гаранция'),
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
  final Color? color;

  const _DateButton({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
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
                color: color ?? AppTheme.accent, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color ?? AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
