import 'package:flutter/material.dart';
import 'package:clinic_go/core/themes/app_colors.dart';

class HealthData {
  const HealthData({required this.conditions, required this.allergies});
  final List<String> conditions;
  final List<String> allergies;
}

class HealthConditionsScreen extends StatefulWidget {
  const HealthConditionsScreen({
    super.key,
    required this.conditions,
    required this.allergies,
  });

  final List<String> conditions;
  final List<String> allergies;

  @override
  State<HealthConditionsScreen> createState() => _HealthConditionsScreenState();
}

class _HealthConditionsScreenState extends State<HealthConditionsScreen> {
  late final List<String> _conditions;
  late final List<String> _allergies;

  @override
  void initState() {
    super.initState();
    _conditions = List.from(widget.conditions);
    _allergies = List.from(widget.allergies);
  }

  HealthData get _result =>
      HealthData(conditions: _conditions, allergies: _allergies);

  void _pop() => Navigator.of(context).pop(_result);

  Future<void> _addItem(List<String> list, String hint) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text(
          'Adicionar $hint',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.ink,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.ink, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.lemon, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text(
              'Adicionar',
              style: TextStyle(
                color: AppColors.lemon,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      setState(() => list.add(value));
    }
  }

  void _remove(List<String> list, int index) =>
      setState(() => list.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pop,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: BrutalDecor.border,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: BrutalDecor.shadowSm,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.ink,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Condições e alergias',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConditionSection(
                        label: 'Condições de saúde',
                        emptyLabel: 'condição de saúde',
                        iconBg: AppColors.sky,
                        icon: Icons.medical_information_outlined,
                        items: _conditions,
                        onAdd: () =>
                            _addItem(_conditions, 'Ex: Diabetes tipo 2'),
                        onRemove: (i) => _remove(_conditions, i),
                      ),
                      const SizedBox(height: 24),
                      _ConditionSection(
                        label: 'Alergias',
                        emptyLabel: 'alergia',
                        iconBg: AppColors.coral,
                        icon: Icons.warning_amber_outlined,
                        items: _allergies,
                        onAdd: () => _addItem(_allergies, 'Ex: Penicilina'),
                        onRemove: (i) => _remove(_allergies, i),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────

class _ConditionSection extends StatelessWidget {
  const _ConditionSection({
    required this.label,
    required this.emptyLabel,
    required this.iconBg,
    required this.icon,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  final String label;
  final String emptyLabel;
  final Color iconBg;
  final IconData icon;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.ink,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lemon,
                  border: BrutalDecor.border,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: BrutalDecor.shadowSm,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Adicionar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            border: BrutalDecor.border,
            borderRadius: BorderRadius.circular(16),
            boxShadow: BrutalDecor.shadow,
          ),
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Text(
                    'Nenhuma $emptyLabel adicionada',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1.5,
                          color: AppColors.paper,
                          indent: 56,
                        ),
                      _ItemRow(
                        iconBg: iconBg,
                        icon: icon,
                        label: items[i],
                        onRemove: () => onRemove(i),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.onRemove,
  });

  final Color iconBg;
  final IconData icon;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: const Border.fromBorderSide(
                BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
            child: Icon(icon, color: AppColors.card, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.errorBgLight,
                borderRadius: BorderRadius.circular(8),
                border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.coral, width: 1.5),
                ),
              ),
              child: const Icon(Icons.close, color: AppColors.coral, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
