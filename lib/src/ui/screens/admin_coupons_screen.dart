import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _coupons;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _coupons = FirebaseFirestore.instance.collection('coupons').get();

  Future<void> _edit(
      {QueryDocumentSnapshot<Map<String, dynamic>>? coupon}) async {
    final form = GlobalKey<FormState>();
    final existing = coupon?.data() ?? {};
    final code = TextEditingController(text: coupon?.id ?? '');
    final value = TextEditingController(text: '${existing['value'] ?? ''}');
    final minimum =
        TextEditingController(text: '${existing['minSubtotal'] ?? 0}');
    final maxUses = TextEditingController(text: '${existing['maxUses'] ?? 0}');
    var type = (existing['discountType'] ?? 'percent').toString();
    var active = existing['active'] != false;
    final rawExpiry = existing['expiresAt'];
    DateTime? expires = rawExpiry is Timestamp ? rawExpiry.toDate() : null;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: Text(coupon == null ? 'Nuevo cupón' : 'Editar cupón'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: code,
                    enabled: coupon == null,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Código'),
                    validator: (text) => !RegExp(r'^[A-Z0-9_-]{3,32}$')
                            .hasMatch((text ?? '').trim().toUpperCase())
                        ? 'Usa 3–32 letras, números, guion o guion bajo.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Descuento'),
                    items: const [
                      DropdownMenuItem(
                          value: 'percent', child: Text('Porcentaje')),
                      DropdownMenuItem(
                          value: 'fixed', child: Text('Monto fijo en USD')),
                    ],
                    onChanged: (value) =>
                        dialogSetState(() => type = value ?? type),
                  ),
                  TextFormField(
                    controller: value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: type == 'percent'
                            ? 'Porcentaje (hasta 100)'
                            : 'Monto USD'),
                    validator: (text) {
                      final amount = double.tryParse(text ?? '');
                      if (amount == null ||
                          amount <= 0 ||
                          (type == 'percent' && amount > 100)) {
                        return 'Ingresa un valor válido.';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: minimum,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Compra mínima en USD'),
                    validator: (text) => (double.tryParse(text ?? '') ?? -1) < 0
                        ? 'Ingresa un monto no negativo.'
                        : null,
                  ),
                  TextFormField(
                    controller: maxUses,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Usos máximos (0 = ilimitado)'),
                    validator: (text) => (int.tryParse(text ?? '') ?? -1) < 0
                        ? 'Ingresa un entero no negativo.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Cupón activo'),
                    value: active,
                    onChanged: (value) => dialogSetState(() => active = value),
                  ),
                  Row(children: [
                    Expanded(
                        child: Text(expires == null
                            ? 'Sin fecha de vencimiento'
                            : 'Vence: ${expires!.day}/${expires!.month}/${expires!.year}')),
                    TextButton(
                      onPressed: () async {
                        final chosen = await showDatePicker(
                          context: dialogContext,
                          initialDate: expires == null ||
                                  expires!.isBefore(DateTime.now())
                              ? DateTime.now().add(const Duration(days: 1))
                              : expires!,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (chosen != null) {
                          dialogSetState(() => expires = DateTime(chosen.year,
                              chosen.month, chosen.day, 23, 59, 59, 999));
                        }
                      },
                      child: const Text('Elegir fecha'),
                    ),
                    if (expires != null)
                      IconButton(
                          onPressed: () => dialogSetState(() => expires = null),
                          icon: const Icon(Icons.clear)),
                  ]),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      final normalizedCode = code.text.trim().toUpperCase();
      final data = <String, dynamic>{
        'code': normalizedCode,
        'discountType': type,
        'value': double.parse(value.text),
        'minSubtotal': double.parse(minimum.text),
        'maxUses': int.parse(maxUses.text),
        'active': active,
        'expiresAt': expires == null ? null : Timestamp.fromDate(expires!),
      };
      if (coupon == null) {
        data['usedCount'] = 0;
        data['reservedUses'] = 0;
      }
      try {
        await FirebaseFirestore.instance
            .collection('coupons')
            .doc(normalizedCode)
            .set(data, SetOptions(merge: true));
        setState(_reload);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('No se pudo guardar. Revisa el rol de administrador.')));
        }
      }
    }
    code.dispose();
    value.dispose();
    minimum.dispose();
    maxUses.dispose();
  }

  Future<void> _delete(String code) async {
    try {
      await FirebaseFirestore.instance.collection('coupons').doc(code).delete();
      if (mounted) setState(_reload);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No se puede eliminar mientras haya usos reservados.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cupones y promociones')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo cupón'),
        ),
        body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _coupons,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('No se pudieron cargar los cupones.'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('Todavía no hay cupones.'));
            }
            return RefreshIndicator(
              onRefresh: () async => setState(_reload),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final value = (data['value'] as num?)?.toDouble() ?? 0;
                  final suffix =
                      data['discountType'] == 'percent' ? '%' : ' USD';
                  return Card(
                      child: ListTile(
                    leading: Icon(data['active'] == true
                        ? Icons.local_offer
                        : Icons.block),
                    title: Text(doc.id),
                    subtitle: Text(
                        '${value.toStringAsFixed(2)}$suffix · ${data['usedCount'] ?? 0}/${data['maxUses'] == 0 ? '∞' : data['maxUses']} usos'),
                    trailing: Wrap(children: [
                      IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _edit(coupon: doc),
                          icon: const Icon(Icons.edit_outlined)),
                      IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => _delete(doc.id),
                          icon: const Icon(Icons.delete_outline)),
                    ]),
                  ));
                },
              ),
            );
          },
        ),
      );
}
