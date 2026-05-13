import 'package:flutter/material.dart';
import 'package:clinic_go/core/di/service_locator.dart';
import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/models/medication.dart';
import 'package:clinic_go/features/medication/presentation/view_models/add_medication_view_model.dart';
import 'package:clinic_go/features/medication/presentation/view_models/edit_medication_view_model.dart';

/// Screen for editing or deleting an existing medication.
///
/// Accepts the current [medication] and pre-populates all form fields.
/// Pops with `true` when a successful save or delete completes.
class EditMedicationScreen extends StatefulWidget {
  const EditMedicationScreen({super.key, required this.medication});

  final Medication medication;

  @override
  State<EditMedicationScreen> createState() => _EditMedicationScreenState();
}

class _EditMedicationScreenState extends State<EditMedicationScreen> {
  late final EditMedicationViewModel _viewModel;
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _viewModel = EditMedicationViewModel(
      repository: getIt<MedicationRepository>(),
      medication: widget.medication,
    );
    _nameController = TextEditingController(text: widget.medication.name);
    _dosageController = TextEditingController(
      text: widget.medication.dosage ?? '',
    );
    _notesController = TextEditingController(
      text: widget.medication.notes ?? '',
    );

    _viewModel.addListener(_onViewModelChanged);
    _viewModel.loadReminders();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.wasDeleted
                ? 'Medication deleted.'
                : 'Medication updated successfully!',
          ),
          backgroundColor: _viewModel.wasDeleted
              ? const Color(0xFF757575)
              : const Color(0xFF43A047),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_viewModel.isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: const Text(
          'This will permanently delete all reminder history and logs. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _viewModel.deleteMedication();
    }
  }

  Future<void> _pickColor() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ColorPickerSheet(
        selected: _viewModel.selectedColor,
        onSelected: (c) {
          _viewModel.setColor(c);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _pickReminderTime(int index) async {
    final current = _viewModel.reminderSlots[index].time;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) _viewModel.setReminderTime(index, picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // ── Header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'edit med',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        // ── Form ──────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _viewModel.isLoadingReminders
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Colour picker column ──────────
                            Column(
                              children: [
                                GestureDetector(
                                  onTap: _pickColor,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: _viewModel.selectedColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const SizedBox(
                                  width: 60,
                                  child: Text(
                                    'tap to\nchange\nthe color',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // ── Fields column ─────────────────
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name
                                  _BlueField(
                                    key: const Key('edit_med_name_field'),
                                    label: 'name',
                                    controller: _nameController,
                                    errorText: _viewModel.nameError,
                                    onChanged: _viewModel.setName,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 10),

                                  // Dosage
                                  _BlueField(
                                    key: const Key('edit_med_dosage_field'),
                                    label: 'dosage',
                                    controller: _dosageController,
                                    errorText: _viewModel.dosageError,
                                    onChanged: _viewModel.setDosage,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 10),

                                  // Reminder time pickers
                                  ...List.generate(
                                    _viewModel.reminderSlots.length,
                                    (i) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _TimeTile(
                                        key: Key('edit_med_time_$i'),
                                        label:
                                            _viewModel.reminderSlots.length > 1
                                            ? 'when (${i + 1})'
                                            : 'when',
                                        time: _viewModel.reminderSlots[i].time,
                                        onTap: () => _pickReminderTime(i),
                                      ),
                                    ),
                                  ),

                                  // Reminder times note
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      'Changing times updates future reminders '
                                      'but preserves past logs.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black.withValues(
                                          alpha: 0.45,
                                        ),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),

                                  // Frequency dropdown
                                  _FrequencyDropdown(
                                    key: const Key('edit_med_freq_field'),
                                    value: _viewModel.frequency,
                                    options:
                                        AddMedicationViewModel.frequencyOptions,
                                    onChanged: _viewModel.setFrequency,
                                  ),
                                  const SizedBox(height: 10),

                                  // Notes (optional)
                                  _BlueField(
                                    label: 'notes (optional)',
                                    controller: _notesController,
                                    onChanged: _viewModel.setNotes,
                                    maxLines: 2,
                                  ),

                                  // Error message
                                  if (_viewModel.errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFECEC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _viewModel.errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFC62828),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // ── Delete button ──────────────────────────────
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('delete_medication_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      'Delete Medication',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: _viewModel.isLoading ? null : _confirmDelete,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        // ── Footer ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Row(
            children: [
              // Cancel
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    onPressed: _viewModel.isLoading
                        ? null
                        : () async {
                            if (await _confirmDiscard() && context.mounted) {
                              Navigator.of(context).pop(false);
                            }
                          },
                    child: const Text(
                      'cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save Changes
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const Key('edit_med_save_button'),
                  onPressed:
                      (_viewModel.isLoading || _viewModel.isLoadingReminders)
                      ? null
                      : _viewModel.submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4E84E5),
                    disabledBackgroundColor: const Color(0xFF4E84E5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _viewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable form widgets (mirrors add_medication_screen.dart) ──────

class _BlueField extends StatelessWidget {
  const _BlueField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.textInputAction,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: textInputAction,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFF4E84E5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            errorText: null,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = time.format(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4E84E5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              formatted,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4E84E5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF4E84E5),
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          hint: const Text('freq', style: TextStyle(color: Colors.white70)),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({required this.selected, required this.onSelected});

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a colour',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: AddMedicationViewModel.colorPalette
                .map(
                  (c) => GestureDetector(
                    onTap: () => onSelected(c),
                    child: Container(
                      key: Key('edit_color_${c.toARGB32().toRadixString(16)}'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: c == selected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
