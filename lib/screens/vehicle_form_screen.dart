// lib/screens/vehicle_form_screen.dart

import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';
import '../theme.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;
  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();

  late TextEditingController _nameCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _yearCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _nameCtrl = TextEditingController(text: v?.name ?? '');
    _plateCtrl = TextEditingController(text: v?.licensePlate ?? '');
    _brandCtrl = TextEditingController(text: v?.brand ?? '');
    _modelCtrl = TextEditingController(text: v?.model ?? '');
    _yearCtrl = TextEditingController(
        text: v?.year != null ? v!.year.toString() : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      name: _nameCtrl.text.trim(),
      licensePlate: _plateCtrl.text.trim().toUpperCase(),
      brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()),
    );

    if (widget.vehicle == null) {
      await _db.insertVehicle(vehicle);
    } else {
      await _db.updateVehicle(vehicle);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.vehicle != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактиране на кола' : 'Нов автомобил'),
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
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'напр. Skoda Fabia',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Моля въведи наименование' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Регистрационен номер *'),
            TextFormField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'напр. СВ 4223 ВТ',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Моля въведи номер' : null,
            ),
            const SizedBox(height: 16),

            _buildLabel('Марка (по желание)'),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                hintText: 'напр. Skoda',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel('Модел (по желание)'),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                hintText: 'напр. Fabia',
                prefixIcon: Icon(Icons.commute_outlined),
              ),
            ),
            const SizedBox(height: 16),

            _buildLabel('Година (по желание)'),
            TextFormField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'напр. 2020',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final year = int.tryParse(v);
                if (year == null || year < 1900 || year > 2100) {
                  return 'Невалидна година';
                }
                return null;
              },
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
                    : Text(isEdit ? 'Запази промените' : 'Добави автомобил'),
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
