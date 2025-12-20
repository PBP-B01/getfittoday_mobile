import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/product.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';
import 'package:getfittoday_mobile/widgets/product_form_dialog.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;
  final Function() onRefresh;

  const ProductDetailDialog({super.key, required this.product, required this.onRefresh});

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final auth = context.watch<AuthState>();
    final loggedIn = auth.isLoggedIn;
    final isAdmin = auth.isAdmin;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.all(0),

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

      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              Text(
                widget.product.fields.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B2B5A)),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.store, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text("Dijual oleh: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Expanded(
                    child: Text(
                      widget.product.fields.storeName, 
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              Text(
                "Rp${widget.product.fields.price}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),

              const SizedBox(height: 12),

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

      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), foregroundColor: Colors.black54),
          child: const Text("Tutup"),
        ),
      ],
    );
  }


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
        child: const Text("Login untuk beli"),
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
          final response = await request.post("$djangoBaseUrl/store/product/${widget.product.pk}/add-to-cart/", {"quantity": "1"});
          if (mounted) {
            if (response['success'] == true) {
              widget.onRefresh();
              _showCartSuccessDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menambahkan"), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  void _showCartSuccessDialog(BuildContext context) {
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
              decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Berhasil Ditambahkan!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('"${widget.product.fields.name}" ditambahkan ke keranjang.', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.black, side: const BorderSide(color: Colors.grey)),
            child: const Text("Tutup"),
          ),
        ],
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
              showDialog(
                context: context,
                builder: (context) => ProductFormDialog(
                  product: widget.product,
                  onSave: () {
                    Navigator.pop(context); 
                    widget.onRefresh();
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
              _showDeleteConfirmDialog(context, request);
            },
            child: const Text("Delete"),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, CookieRequest request) {
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
              
              final response = await request.post("$djangoBaseUrl/store/product/${widget.product.pk}/delete/", {});
              
              if (response['success'] == true) {
                if(mounted) {
                   _showSuccessDeleteDialog(context);
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
      barrierDismissible: false,
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
                    'Produk "${widget.product.fields.name}" berhasil dihapus.',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onRefresh();
            },
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
}
