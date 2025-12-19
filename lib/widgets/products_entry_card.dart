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
          // === 1. GAMBAR PRODUK (Compact: Flex 5) ===
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

          // === 2. KONTEN (Compact: Flex 9) ===
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Produk
                  Text(
                    product.fields.name,
                    style: const TextStyle(
                      fontSize: 13, // Ukuran font pas di HP kecil
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),

                  // Toko
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

                  // Harga
                  Text(
                    "Rp ${product.fields.price}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2B5A),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Rating & Terjual
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

                  const Spacer(), // Mendorong tombol ke paling bawah

                  // === TOMBOL AKSI ===
                  if (!loggedIn)
                    _buildCompactButton(
                      context,
                      label: "Login utk Beli",
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

  // Helper untuk tombol compact (tinggi 30px)
  Widget _buildCompactButton(BuildContext context, {
    required String label, 
    required Color color, 
    required Color textColor, 
    required VoidCallback onPressed,
    IconData? icon
  }) {
    return SizedBox(
      width: double.infinity,
      height: 30, // Hemat tempat
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: EdgeInsets.zero, // Hilangkan padding bawaan
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

  // Tombol User Biasa
  Widget _buildUserButtons(BuildContext context, CookieRequest request) {
    return Column(
      children: [
        _buildCompactButton(
          context,
          label: "View",
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Masuk keranjang!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  // Tombol Admin
  Widget _buildAdminButtons(BuildContext context, CookieRequest request) {
    return Column(
      children: [
        _buildCompactButton(
          context,
          label: "View",
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Konfirmasi Hapus"),
                      content: const Text(
                        "Apakah Anda yakin menghapus produk ini?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Batal",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final response = await request.post(
                              "$djangoBaseUrl/store/product/${product.pk}/delete/",
                              {},
                            );

                            if (!context.mounted) return;

                            final success = response['success'] == true;
                            if (success) {
                              onRefresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Produk berhasil dihapus!"),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    response['error']?.toString() ??
                                        response['message']?.toString() ??
                                        "Gagal menghapus produk.",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text("Ya, hapus"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
