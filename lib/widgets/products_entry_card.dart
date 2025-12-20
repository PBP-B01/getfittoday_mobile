import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/product.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/widgets/product_form_dialog.dart';
import 'package:getfittoday_mobile/screens/product_detail_dialog.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class ProductEntryCard extends StatelessWidget {
  final Product product;
  final Function() onRefresh;

  const ProductEntryCard({
    super.key,
    required this.product,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final auth = context.watch<AuthState>();
    final loggedIn = auth.isLoggedIn;
    final isAdmin = auth.isAdmin;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.fields.imageUrl.isNotEmpty
                  ? Image.network(
                      product.fields.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
            ),
          ),

          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.fields.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(Icons.store_mall_directory, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.fields.storeName,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Rp ${product.fields.price}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2B5A),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(product.fields.rating, style: const TextStyle(fontSize: 10)),
                      const Spacer(),
                      Text(
                        "${product.fields.unitsSold}",
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),

                  const Spacer(),

                  if (!loggedIn)
                    _buildCompactButton(
                      context,
                      label: "Login untuk beli",
                      color: const Color(0xFFF0EBFF),
                      textColor: const Color(0xFF6B46C1),
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                    )
                  else if (isAdmin)
                    _buildAdminButtons(context, request)
                  else
                    _buildUserButtons(context, request),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, CookieRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Konfirmasi Hapus",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "Apakah Anda yakin untuk menghapus produk ini? Aksi ini tidak bisa dibatalkan.",
          style: TextStyle(color: Colors.black54),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              
              final response = await request.post(
                "$djangoBaseUrl/store/product/${product.pk}/delete/",
                {},
              );

              if (response['success'] == true) {
                onRefresh();
                
                if (context.mounted) {
                  _showSuccessDeleteDialog(context);
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal menghapus produk"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("Ya, hapus"),
          ),
        ],
      ),
    );
  }

  void _showSuccessDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Berhasil Dihapus!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Produk "${product.fields.name}" berhasil dihapus.',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton(BuildContext context, {
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    IconData? icon
  }) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 12), const SizedBox(width: 4)],
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserButtons(BuildContext context, CookieRequest request) {
    return Column(
      children: [
        _buildCompactButton(
          context,
          label: "View Product",
          icon: Icons.visibility,
          color: Colors.purple,
          textColor: Colors.white,
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ProductDetailDialog(product: product, onRefresh: onRefresh),
          ),
        ),
        const SizedBox(height: 4),
        _buildCompactButton(
          context,
          label: "Keranjang",
          icon: Icons.add,
          color: const Color(0xFF3F51B5),
          textColor: Colors.white,
          onPressed: () async {
            final response = await request.post(
              "$djangoBaseUrl/store/product/${product.pk}/add-to-cart/",
              {"quantity": "1"},
            );
            if (context.mounted && response['success'] == true) {
              onRefresh();
              
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Berhasil Ditambahkan!",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '"${product.fields.name}" ditambahkan ke keranjang.',
                              style: const TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text("Tutup"),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildAdminButtons(BuildContext context, CookieRequest request) {
    return Column(
      children: [
        _buildCompactButton(
          context,
          label: "View Product",
          icon: Icons.visibility,
          color: Colors.purple,
          textColor: Colors.white,
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ProductDetailDialog(product: product, onRefresh: onRefresh),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildCompactButton(
                context,
                label: "Edit",
                color: Colors.blue[700]!,
                textColor: Colors.white,
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => ProductFormDialog(product: product, onSave: onRefresh),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildCompactButton(
                context,
                label: "Delete",
                icon: Icons.delete,
                color: Colors.red[700]!,
                textColor: Colors.white,
                onPressed: () => _showDeleteConfirmation(context, request),
              ),
            ),
          ],
        ),
      ],
    );
  }
}