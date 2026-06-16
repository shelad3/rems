import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class LateFeeSettingsScreen extends StatefulWidget {
  const LateFeeSettingsScreen({super.key});

  @override
  State<LateFeeSettingsScreen> createState() => _LateFeeSettingsScreenState();
}

class _LateFeeSettingsScreenState extends State<LateFeeSettingsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();

  String _lateFeeType = 'percentage';
  final _lateFeeValueCtrl = TextEditingController(text: '5');
  final _gracePeriodCtrl = TextEditingController(text: '3');
  final _reminderDaysCtrl = TextEditingController(text: '3');
  bool _autoApply = false;
  final _dueDayCtrl = TextEditingController(text: '5');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _lateFeeValueCtrl.dispose();
    _gracePeriodCtrl.dispose();
    _reminderDaysCtrl.dispose();
    _dueDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.getAllSettings();
    setState(() {
      _lateFeeType = settings['late_fee_type'] ?? 'percentage';
      _lateFeeValueCtrl.text = settings['late_fee_value'] ?? '5';
      _gracePeriodCtrl.text = settings['grace_period_days'] ?? '3';
      _reminderDaysCtrl.text = settings['reminder_days_before_due'] ?? '3';
      _autoApply = settings['auto_apply_late_fees'] == 'true';
      _dueDayCtrl.text = settings['default_due_day'] ?? '5';
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await _db.setSetting('late_fee_type', _lateFeeType);
    await _db.setSetting('late_fee_value', _lateFeeValueCtrl.text);
    await _db.setSetting('grace_period_days', _gracePeriodCtrl.text);
    await _db.setSetting('reminder_days_before_due', _reminderDaysCtrl.text);
    await _db.setSetting('auto_apply_late_fees', _autoApply.toString());
    await _db.setSetting('default_due_day', _dueDayCtrl.text);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Late Fee & Reminder Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Late Fee Configuration',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _lateFeeType,
                            decoration: const InputDecoration(
                              labelText: 'Late Fee Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'percentage',
                                  child: Text('Percentage of Rent')),
                              DropdownMenuItem(
                                  value: 'flat', child: Text('Flat Amount')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _lateFeeType = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lateFeeValueCtrl,
                            decoration: InputDecoration(
                              labelText: _lateFeeType == 'percentage'
                                  ? 'Late Fee Percentage (%)'
                                  : 'Late Fee Amount (KSH)',
                              border: const OutlineInputBorder(),
                              suffixText:
                                  _lateFeeType == 'percentage' ? '%' : 'KSH',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Required';
                              }
                              final n = double.tryParse(v);
                              if (n == null || n < 0) {
                                return 'Enter a valid number';
                              }
                              if (_lateFeeType == 'percentage' &&
                                  (n < 0 || n > 100)) {
                                return 'Must be 0-100';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _gracePeriodCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Grace Period (days)',
                              hintText: 'Days after due date before late fee',
                              border: OutlineInputBorder(),
                              suffixText: 'days',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 0) return 'Enter a valid number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rent Reminder Settings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _reminderDaysCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reminder Before Due (days)',
                              hintText: 'Send reminder X days before due',
                              border: OutlineInputBorder(),
                              suffixText: 'days',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 0) return 'Enter a valid number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _dueDayCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Default Due Day of Month',
                              hintText: 'e.g., 5 for 5th',
                              border: OutlineInputBorder(),
                              suffixText: 'day',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 1 || n > 31) {
                                return 'Enter 1-31';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Auto-apply Late Fees'),
                            subtitle: const Text(
                                'Automatically apply late fees on overdue rent'),
                            value: _autoApply,
                            onChanged: (v) =>
                                setState(() => _autoApply = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'These settings are stored locally. Cloud sync coming soon.',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
