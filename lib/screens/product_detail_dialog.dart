import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/product.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';
import 'package:getfittoday_mobile/widgets/product_form_dialog.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;
  final Function() onRefresh; // Callback untuk refresh list jika ada perubahan (Edit/Delete)

  const ProductDetailDialog({super.key, required this.product, required this.onRefresh});

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  
  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final loggedIn = request.loggedIn;
    final isAdmin = context.watch<AuthState>().isAdmin;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.all(0),
      
      // --- HEADER DIALOG (Judul + Tombol X) ---
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Detail Produk", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2B5A))
            ),
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.grey),
            ),
          ],
        ),
      ),

      // --- ISI KONTEN ---
      content: SizedBox(
        width: 500, // Atur lebar agar tidak terlalu kecil di Tablet/Web
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GAMBAR
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.product.fields.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.product.fields.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, _) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 2. DETAIL TEXT
              Text(
                widget.product.fields.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2B5A)),
              ),
              const SizedBox(height: 8),
              
              // Toko
              Row(
                children: [
                  const Icon(Icons.store, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text("Dijual oleh: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(widget.product.fields.storeName, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Harga
              Text(
                "Rp${widget.product.fields.price}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)), // Indigo
              ),

              const SizedBox(height: 12),

              // Rating & Terjual
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(widget.product.fields.rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Text("Rating", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  
                  const SizedBox(width: 16),
                  
                  const Icon(Icons.shopping_cart_outlined, color: Colors.grey, size: 18),
                  const SizedBox(width: 4),
                  Text(widget.product.fields.unitsSold, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),

              const SizedBox(height: 24),

              // 3. TOMBOL AKSI (ADMIN / USER / GUEST)
              if (!loggedIn)
                _buildLoginButton()
              else if (isAdmin)
                _buildAdminButtons(context, request)
              else
                _buildUserButton(context, request),
            ],
          ),
        ),
      ),

      // --- FOOTER (Tombol Tutup) ---
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), foregroundColor: Colors.black54),
          child: const Text("Tutup"),
        ),
      ],
    );
  }

  // === WIDGET TOMBOL SAMA SEPERTI SEBELUMNYA ===

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEEF2FF), foregroundColor: const Color(0xFF4F46E5)),
        onPressed: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.pushNamed('/login');
        },
        child: const Text("Login untuk Beli"),
      ),
    );
  }

  Widget _buildUserButton(BuildContext context, CookieRequest request) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text("Tambah ke Keranjang"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white),
        onPressed: () async {
          final response = await request.post("http://127.0.0.1:8000/store/product/${widget.product.pk}/add-to-cart/", {"quantity": "1"});
          if (mounted) {
            if (response['success'] == true) {
              Navigator.pop(context); // Tutup Pop-up Detail
              widget.onRefresh(); // Refresh Cart Count di Parent
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil masuk keranjang"), backgroundColor: Colors.green));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menambahkan"), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  Widget _buildAdminButtons(BuildContext context, CookieRequest request) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              // Buka Dialog Edit, tumpuk di atas dialog detail
              showDialog(
                context: context,
                builder: (context) => ProductFormDialog(
                  product: widget.product,
                  onSave: () {
                    Navigator.pop(context); // Tutup Form Edit
                    Navigator.pop(context); // Tutup Detail juga agar refresh list utama
                    widget.onRefresh(); 
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk berhasil diupdate!")));
                  },
                ),
              );
            },
            child: const Text("Edit"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              // Konfirmasi Hapus
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
                        Navigator.pop(ctx); // Tutup Konfirmasi
                        final response = await request.post("$djangoBaseUrl/store/product/${widget.product.pk}/delete/", {});
                        if (response['success'] == true) {
                          if(mounted) {
                             Navigator.pop(context); // Tutup Detail Pop-up
                             widget.onRefresh(); // Refresh List Utama
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk dihapus!")));
                          }
                        }
                      },
                      child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ),
      ],
    );
  }
}
