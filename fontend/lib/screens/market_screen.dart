import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../providers/auth_provider.dart';
import 'category_management_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _service = ProductService();
  final _categoryService = CategoryService();
  late Future<List<Product>> _future;
  int? _selectedCategoryId; // null = show all products

  @override
  void initState() {
    super.initState();
    _future = _service.fetchProducts();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchProducts();
    });
    await _future;
  }

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageController = TextEditingController();
    final descController = TextEditingController();

    // Load categories
    List<Category> categories = [];
    int? selectedCategoryId;
    try {
      categories = await _categoryService.fetchCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải danh mục: $e')));
      }
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm sản phẩm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Không có danh mục'),
                    ),
                    ...categories.map(
                      (cat) => DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL hình ảnh',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      if (nameController.text.isEmpty || priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập tên và giá sản phẩm')),
        );
        return;
      }

      try {
        final product = Product(
          id: 0,
          name: nameController.text,
          price: double.tryParse(priceController.text) ?? 0,
          image: imageController.text.isEmpty ? null : imageController.text,
          description: descController.text.isEmpty ? null : descController.text,
          categoryId: selectedCategoryId,
        );

        await _service.addProduct(product);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm sản phẩm thành công')),
          );
          _reload();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Future<void> _showEditProductDialog(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final imageController = TextEditingController(text: product.image ?? '');
    final descController = TextEditingController(
      text: product.description ?? '',
    );

    // Load categories
    List<Category> categories = [];
    int? selectedCategoryId = product.categoryId;
    try {
      categories = await _categoryService.fetchCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải danh mục: $e')));
      }
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sửa sản phẩm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Không có danh mục'),
                    ),
                    ...categories.map(
                      (cat) => DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Text(cat.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL hình ảnh',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        final updatedProduct = Product(
          id: product.id,
          name: nameController.text,
          price: double.tryParse(priceController.text) ?? 0,
          image: imageController.text.isEmpty ? null : imageController.text,
          description: descController.text.isEmpty ? null : descController.text,
          categoryId: selectedCategoryId,
        );

        await _service.updateProduct(updatedProduct);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật sản phẩm thành công')),
          );
          _reload();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _service.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa sản phẩm thành công')),
          );
          _reload();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  void _showProductOptions(Product product, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Sửa sản phẩm'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditProductDialog(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa sản phẩm'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(product);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.info, color: Colors.grey),
              title: const Text('Xem chi tiết'),
              onTap: () {
                Navigator.pop(context);
                _showProductDetails(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.image != null && product.image!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: product.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 12),
              Text(
                'Giá: ${_formatPrice(product.price)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              if (product.categoryName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Danh mục: ${product.categoryName}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (product.description != null &&
                  product.description!.isNotEmpty)
                Text('Mô tả: ${product.description}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    final v = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    return '$v ₫';
  }

  Future<void> _showFilterDialog() async {
    List<Category> categories = [];
    try {
      categories = await _categoryService.fetchCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tải danh mục: $e')));
      }
      return;
    }

    if (!mounted) return;

    final selected = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo danh mục'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _selectedCategoryId == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Tất cả sản phẩm'),
                onTap: () => Navigator.pop(context, -1), // -1 means "all"
              ),
              const Divider(),
              ...categories.map(
                (cat) => ListTile(
                  leading: Icon(
                    _selectedCategoryId == cat.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(cat.name),
                  subtitle: cat.description != null
                      ? Text(cat.description!)
                      : null,
                  onTap: () => Navigator.pop(context, cat.id),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedCategoryId = selected == -1 ? null : selected;
      });
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_selectedCategoryId == null) {
      return products;
    }
    return products
        .where((product) => product.categoryId == _selectedCategoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin || authProvider.isManager;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market'),
        actions: [
          IconButton(
            icon: Icon(
              _selectedCategoryId == null
                  ? Icons.filter_list_outlined
                  : Icons.filter_list,
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Lọc theo danh mục',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryManagementScreen(),
                  ),
                );
              },
              tooltip: 'Quản lý danh mục',
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showAddProductDialog,
              tooltip: 'Thêm sản phẩm',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Product>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorView(error: snapshot.error, onRetry: _reload);
            }
            final allProducts = snapshot.data ?? const <Product>[];
            final items = _filterProducts(allProducts);
            if (items.isEmpty) {
              return _selectedCategoryId != null
                  ? _EmptyFilterView(
                      onClear: () {
                        setState(() {
                          _selectedCategoryId = null;
                        });
                      },
                      onRetry: _reload,
                    )
                  : _EmptyView(onRetry: _reload);
            }
            return Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final p = items[index];
                  return _ProductCard(
                    product: p,
                    onLongPress: () => _showProductOptions(p, isAdmin),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              tooltip: 'Thêm sản phẩm',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onLongPress});
  final Product product;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () {},
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: product.image == null || product.image!.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (product.categoryName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.categoryName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    _formatPrice(product.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    // Simple currency formatting (VND)
    final v = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    return '$v ₫';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.error, required this.onRetry});
  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Không thể tải dữ liệu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              error?.toString() ?? 'Đã xảy ra lỗi không xác định',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Chưa có sản phẩm',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFilterView extends StatelessWidget {
  const _EmptyFilterView({required this.onClear, required this.onRetry});
  final VoidCallback onClear;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Không có sản phẩm trong danh mục này',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Xóa bộ lọc'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
