import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/product.dart';
import 'package:getfittoday_mobile/screens/products_entry_list.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Future<Cart> fetchCart(CookieRequest request) async {
    final response = await request.get('http://127.0.0.1:8000/store/api/cart/');
    return Cart.fromJson(response);
  }

  // Fungsi untuk refresh tampilan setelah update/delete
  void refreshCart() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0E5A64),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Cart>(
        future: fetchCart(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
            return const Center(
              child: Text("Keranjang kosong.", style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          } else {
            final cart = snapshot.data!;
            return Column(
              children: [
                // Header Tabel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.grey[100],
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text("PRODUK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                      Expanded(flex: 2, child: Text("HARGA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                      Expanded(flex: 2, child: Text("KUANTITAS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                      SizedBox(width: 40, child: Text("AKSI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                ),
                
                // List Item
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: Row(
                          children: [
                            // Nama Produk
                            Expanded(
                              flex: 3,
                              child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            // Harga Satuan
                            Expanded(
                              flex: 2,
                              child: Text("Rp ${item.product.price}", style: const TextStyle(color: Colors.grey)),
                            ),
                            // Tombol Kuantitas (+/-)
                            Expanded(
                              flex: 2,
                              child: Align( // Tambahkan Align agar tidak melar ke samping
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 100, // Batasi lebar kotak agar pas
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors.white, // Tambah warna background putih biar bersih
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Biar +/- ada di ujung
                                    children: [
                                      // Tombol Kurang
                                      InkWell(
                                        onTap: () async {
                                          int newQty = item.quantity - 1;
                                          if (newQty < 1) return;
                                          await request.postJson(
                                            'http://127.0.0.1:8000/store/cart/update/${item.product.pk}/',
                                            jsonEncode({"quantity": newQty})
                                          );
                                          refreshCart();
                                        },
                                        child: Container( // Bungkus icon biar area sentuh enak
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(Icons.remove, size: 16, color: Colors.grey),
                                        ),
                                      ),
                                      
                                      // Angka
                                      Text("${item.quantity}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      
                                      // Tombol Tambah
                                      InkWell(
                                        onTap: () async {
                                          int newQty = item.quantity + 1;
                                          await request.postJson(
                                            'http://127.0.0.1:8000/store/cart/update/${item.product.pk}/',
                                            jsonEncode({"quantity": newQty})
                                          );
                                          refreshCart();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(Icons.add, size: 16, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Tombol Hapus dengan Konfirmasi
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // POPUP KONFIRMASI HAPUS
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.white,
                                      title: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                                            child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text("Konfirmasi Hapus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      content: const Text("Apakah Anda yakin untuk menghapus produk ini dari keranjang?"),
                                      actions: [
                                        OutlinedButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Batal", style: TextStyle(color: Colors.black)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () async {
                                            Navigator.pop(ctx); // Tutup Dialog
                                            // API HAPUS
                                            await request.post('http://127.0.0.1:8000/store/cart/remove/${item.product.pk}/', {});
                                            refreshCart();
                                            
                                            // SNACKBAR HIJAU (Item berhasil dihapus)
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Row(
                                                    children: [
                                                      Icon(Icons.check_circle, color: Colors.white),
                                                      SizedBox(width: 8),
                                                      Text("Item berhasil dihapus"),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  action: SnackBarAction(
                                                    label: '✖',
                                                    textColor: Colors.white,
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                    },
                                                  ),
                                                )
                                              );
                                            }
                                          },
                                          child: const Text("Ya, Hapus", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Footer Total & Checkout
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border(top: BorderSide(color: Colors.blue.shade100)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text("Total: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("Rp ${cart.totalPrice}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B2B5A))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context), 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey)),
                            child: const Text("Kembali Belanja"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              // POPUP KONFIRMASI CHECKOUT
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  surfaceTintColor: Colors.white,
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.yellow[50], shape: BoxShape.circle),
                                        child: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text("Konfirmasi Checkout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: const Text("Apakah Anda yakin untuk checkout?"),
                                  actions: [
                                    OutlinedButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Batal", style: TextStyle(color: Colors.black)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                      onPressed: () async {
                                        Navigator.pop(ctx); 
                                        final response = await request.post('http://127.0.0.1:8000/store/cart/checkout/', {});
                                        if (context.mounted) {
                                          if (response['success'] == true) {
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (ctxSuccess) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                surfaceTintColor: Colors.white,
                                                title: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                                                      child: const Icon(Icons.check_circle, color: Colors.green),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Text("Checkout Berhasil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                                content: const Text("Selamat! Anda berhasil checkout."),
                                                actions: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                                    onPressed: () {
                                                      Navigator.pop(ctxSuccess); 
                                                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProductEntryListPage())); 
                                                    },
                                                    child: const Text("Kembali Belanja", style: TextStyle(color: Colors.black)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['error'] ?? "Gagal checkout")));
                                          }
                                        }
                                      },
                                      child: const Text("Ya, Checkout", style: TextStyle(color: Colors.black)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                            child: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}