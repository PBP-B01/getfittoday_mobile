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
    bool loggedIn = true;
    bool isAdmin = true;

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
        children: [
          // === GAMBAR PRODUK (Gunakan Expanded agar fleksibel) ===
          Expanded( // <--- GANTI INI DARI FIXED HEIGHT KE EXPANDED
            flex: 6, // Porsi gambar 60%
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: product.fields.imageUrl.isNotEmpty
                  ? Image.network(
                      product.fields.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image),
                    ),
            ),
          ),

          // === DETAIL & TOMBOL ===
          Expanded( // <--- KONTEN BAWAH JUGA EXPANDED
            flex: 8, // Porsi teks 80% (total 14 bagian)
            child: Padding(
              padding: const EdgeInsets.all(10.0), // Padding agak dikecilkan dikit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Biar tombol mentok bawah
                children: [
                  // Detail Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Produk
                      Text(
                        product.fields.name,
                        style: const TextStyle(
                          fontSize: 14, // Kecilkan dikit biar muat
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Lokasi
                      Row(
                        children: [
                          const Icon(Icons.store_mall_directory, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.fields.storeName,
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Harga
                      Text(
                        "Rp ${product.fields.price}",
                        style: const TextStyle(
                          fontSize: 16,
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
                    ],
                  ),

                  // Tombol (Spacer agar selalu di bawah)
                  const SizedBox(height: 4),
                  if (!loggedIn)
                    // =====PERUBAHAN BARU=====
                    SizedBox(
                      width: double.infinity,
                      height: 32, // Tinggi tombol fix
                      child: ElevatedButton(
                        onPressed: () {
                          // Arahkan ke halaman login — gunakan route named '/login' (suaikan jika route berbeda)
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0EBFF), // ungu-pucat background
                          foregroundColor: const Color(0xFF6B46C1), // teks ungu
                          elevation: 0,
                          padding: EdgeInsets.zero, // Hilangkan padding internal
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Login untuk Beli", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
      children: [
        SizedBox(
          width: double.infinity,
          height: 28, // Tombol lebih tipis
          child: ElevatedButton.icon(
            icon: const Icon(Icons.visibility, size: 12),
            label: const Text("View Product", style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ProductDetailDialog(product: product, onRefresh: onRefresh),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 28,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 12),
            label: const Text("Keranjang", style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: () async {
               // ... logic add cart ...
               final response = await request.post(
                "http://127.0.0.1:8000/store/product/${product.pk}/add-to-cart/",
                {"quantity": "1"},
              );
              if (context.mounted && response['success'] == true) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil masuk keranjang!")));
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
      // ... (Sesuaikan tinggi tombol jadi 28 dan font 11 agar muat) ...
      // Sama seperti logika _buildUserButtons di atas
      return Column(
        children: [
            // View Product
            SizedBox(
                width: double.infinity, height: 28,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white, padding: EdgeInsets.zero),
                    onPressed: (){
                        showDialog(
                            context: context,
                            builder: (context) => ProductDetailDialog(product: product, onRefresh: onRefresh),
                        );
                    }, 
                    child: const Text("View Product", style: TextStyle(fontSize: 11))
                )
            ),
            const SizedBox(height: 4),
            Row(
                children: [
                    Expanded(child: SizedBox(height: 28, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white, padding: EdgeInsets.zero), onPressed: (){
                        showDialog(context: context, builder: (context) => ProductFormDialog(product: product, onSave: onRefresh));
                    }, child: const Text("Edit", style: TextStyle(fontSize: 11))))),
                    const SizedBox(width: 4),
                    Expanded(child: SizedBox(height: 28, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white, padding: EdgeInsets.zero), onPressed: (){
                        showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                title: const Text("Konfirmasi Hapus"),
                                content: const Text("Yakin hapus produk ini?"),
                                actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                        onPressed: () async {
                                            Navigator.pop(ctx);
                                            final response = await request.post("http://127.0.0.1:8000/store/product/${product.pk}/delete/", {});
                                            if (response['success'] == true) {
                                                onRefresh();
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk dihapus!")));
                                            }
                                        },
                                        child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                                    ),
                                ],
                            ),
                        );
                    }, child: const Text("Delete", style: TextStyle(fontSize: 11))))),
                ]
            )
        ]
      );
  }
}