import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/product.dart';
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

    // SIMULASI LOGIN & ROLE
    // =====PERUBAHAN BARU=====
    // Ganti hardcoded true/false dengan deteksi dari CookieRequest:
    bool loggedIn = false;
    bool isAdmin = false;

    final data = request.jsonData;
    if (data is Map) {
      // contoh: request.jsonData mungkin berisi 'username' ketika login
      if ((data['username'] is String && (data['username'] as String).isNotEmpty) ||
          (request.cookies['username']?.value != null && request.cookies['username']!.value.isNotEmpty)) {
        loggedIn = true;
      }
      // jika backend mengirimkan informasi admin di jsonData (opsional)
      if (data['is_superuser'] == true || data['is_admin'] == true) {
        isAdmin = true;
      }
    } else {
      // fallback: cek cookie username
      final cookie = request.cookies['username'];
      if (cookie != null && cookie.value.isNotEmpty) loggedIn = true;
    }
    // =====PERUBAHAN BARU=====

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // BIAR CARD NGIKUTIN KONTEN, BUKAN MAKSA PANJANG
        children: [
          // === GAMBAR PRODUK ===
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: product.fields.imageUrl.isNotEmpty
                ? Image.network(
                    product.fields.imageUrl,
                    width: double.infinity,
                    height: 145, // tinggi gambar fix supaya card konsisten
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 145,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 145,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
          ),

          // === DETAIL & TOMBOL ===
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // supaya isi tidak maksa turun
              children: [
                // ===== NAMA PRODUK =====
                SizedBox(
                  height: 38, // kira-kira tinggi untuk max 2 baris teks
                  child: Text(
                    product.fields.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ===== LOKASI TOKO =====
                Row(
                  children: [
                    const Icon(Icons.store_mall_directory, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product.fields.storeName,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ===== HARGA =====
                Text(
                  "Rp ${product.fields.price}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2B5A),
                  ),
                ),

                const SizedBox(height: 6),

                // ===== RATING & JUMLAH TERJUAL (UPDATED) =====
                Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(product.fields.rating, style: const TextStyle(fontSize: 11)),
                    const Spacer(),
                    Text(
                      "${product.fields.unitsSold}",
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ===== BUTTONS SECTION =====
                // Jika guest (belum login) → tampilkan tombol "Login untuk Beli"
                if (!loggedIn)
                  // =====PERUBAHAN BARU=====
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        // Arahkan ke halaman login — gunakan route named '/login' (suaikan jika route berbeda)
                        Navigator.pushNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0EBFF), // ungu-pucat background
                        foregroundColor: const Color(0xFF6B46C1), // teks ungu
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        "Login untuk Beli",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                // =====PERUBAHAN BARU=====
                else if (isAdmin)
                  _buildAdminButtons(context, request)
                else
                  _buildUserButtons(context, request),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // =========== USER BUTTONS (UPDATED) ===============
  // ===================================================
  Widget _buildUserButtons(BuildContext context, CookieRequest request) {
    return Column(
      mainAxisSize: MainAxisSize.min, // supaya tidak nambah tinggi kosong
      children: [
        // 1. View Product (via DIALOG)
        SizedBox(
          width: double.infinity,
          height: 32,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility, size: 14),
            label: const Text("View Product", style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ProductDetailDialog(
                  product: product,
                  onRefresh: onRefresh,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // 2. Add to Cart
        SizedBox(
          width: double.infinity,
          height: 32,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 14),
            label: const Text("Keranjang", style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: () async {
              final response = await request.post(
                "http://127.0.0.1:8000/store/product/${product.pk}/add-to-cart/",
                {"quantity": "1"},
              );

              if (context.mounted) {
                if (response['success'] == true) {
                  onRefresh();

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 28),
                          SizedBox(width: 10),
                          Text(
                            "Berhasil Ditambahkan!",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      content: Text('"${product.fields.name}" ditambahkan ke keranjang.'),
                      actions: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Tutup", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal menambahkan ke keranjang.")),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  // ===================================================
  // =============== ADMIN BUTTONS (UPDATED) ===========
  // ===================================================
  Widget _buildAdminButtons(BuildContext context, CookieRequest request) {
    return Column(
      mainAxisSize: MainAxisSize.min, // biar tidak nambah space kosong
      children: [
        // VIEW PRODUCT
        SizedBox(
          width: double.infinity,
          height: 32,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility, size: 14),
            label: const Text("View Product", style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ProductDetailDialog(
                  product: product,
                  onRefresh: onRefresh,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),

        // EDIT + DELETE (UPDATED → 1 ROW)
        Row(
          children: [
            // EDIT
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text("Edit", style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ProductFormDialog(
                        product: product,
                        onSave: onRefresh,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // DELETE
            Expanded(
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text("Delete", style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Konfirmasi Hapus"),
                        content: const Text("Apakah Anda yakin menghapus produk ini?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              Navigator.pop(context);
                              final response = await request.post(
                                "http://127.0.0.1:8000/store/product/${product.pk}/delete/",
                                {},
                              );

                              if (response['success'] == true) {
                                onRefresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Produk berhasil dihapus!")),
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
            ),
          ],
        ),
      ],
    );
  }
}
