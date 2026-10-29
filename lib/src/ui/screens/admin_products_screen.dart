import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _service = ProductService();
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = _service.getManagedProducts();
  }

  void _reload() => setState(() => _products = _service.getManagedProducts());

  Future<void> _edit({Product? product}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.name ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final price = TextEditingController(text: product?.price.toString() ?? '');
    final image = TextEditingController(text: product?.imageUrl ?? '');
    final stock = TextEditingController(text: product?.stock.toString() ?? '1');
    final category =
        TextEditingController(text: product?.category ?? 'General');
    final variants = TextEditingController(
        text: product == null
            ? ''
            : product.variantOptions.entries
                .map((entry) => '${entry.key}=${entry.value.join(',')}')
                .join('; '));
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product == null ? 'Nuevo producto' : 'Editar producto'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(name, 'Nombre', required: true),
                _field(description, 'Descripción', required: true, maxLines: 3),
                _field(price, 'Precio en USD', required: true, number: true),
                _field(stock, 'Existencias', required: true, integer: true),
                _field(category, 'Categoría', required: true),
                _field(image, 'URL de imagen', required: true),
                _field(variants, 'Opciones (Talla=S,M; Color=Negro,Blanco)',
                    maxLines: 2),
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      try {
        await _service.saveProduct(Product(
          id: product?.id ?? '',
          name: name.text.trim(),
          description: description.text.trim(),
          price: double.parse(price.text.trim()),
          imageUrl: image.text.trim(),
          category: category.text.trim(),
          stock: int.parse(stock.text.trim()),
          variantOptions: _parseVariants(variants.text),
        ));
        _reload();
      } catch (error) {
        _showError(error);
      }
    }
    name.dispose();
    description.dispose();
    price.dispose();
    image.dispose();
    stock.dispose();
    category.dispose();
    variants.dispose();
  }

  Map<String, List<String>> _parseVariants(String value) {
    final parsed = <String, List<String>>{};
    for (final part in value.split(';')) {
      if (part.trim().isEmpty) continue;
      final separator = part.indexOf('=');
      if (separator <= 0) {
        throw const FormatException('Formato de opciones inválido.');
      }
      final name = part.substring(0, separator).trim();
      final options = part
          .substring(separator + 1)
          .split(',')
          .map((option) => option.trim())
          .where((option) => option.isNotEmpty)
          .toSet()
          .toList();
      if (name.isEmpty || options.isEmpty) {
        throw const FormatException(
            'Cada opción debe tener al menos un valor.');
      }
      parsed[name] = options;
    }
    return parsed;
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false,
      bool number = false,
      bool integer = false,
      int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number || integer
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return 'Este campo es obligatorio.';
          if (number &&
              (double.tryParse(text) == null || double.parse(text) <= 0)) {
            return 'Ingresa un precio mayor a cero.';
          }
          if (integer && (int.tryParse(text) == null || int.parse(text) < 0)) {
            return 'Ingresa un número entero no negativo.';
          }
          if (label == 'URL de imagen') {
            final uri = Uri.tryParse(text);
            if (uri == null ||
                !uri.hasScheme ||
                !['http', 'https'].contains(uri.scheme)) {
              return 'Ingresa una URL http o https.';
            }
          }
          return null;
        },
      ),
    );
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Quieres eliminar ${product.name} del catálogo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteProduct(product.id);
      _reload();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'No se pudo guardar el producto. Comprueba tu conexión y rol de administrador.')),
    );
    debugPrint('Product admin error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar catálogo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo cargar el catálogo.'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return const Center(child: Text('Todavía no hay productos.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                  child: ListTile(
                leading: CircleAvatar(
                    child: Text(product.name.characters.first.toUpperCase())),
                title: Text(product.name),
                subtitle: Text(
                    '${product.category} · \$${product.price.toStringAsFixed(2)} · ${product.stock} unidades'),
                trailing: Wrap(children: [
                  IconButton(
                      tooltip: 'Editar',
                      onPressed: () => _edit(product: product),
                      icon: const Icon(Icons.edit_outlined)),
                  IconButton(
                      tooltip: 'Eliminar',
                      onPressed: () => _delete(product),
                      icon: const Icon(Icons.delete_outline)),
                ]),
              ));
            },
          );
        },
      ),
    );
  }
}
