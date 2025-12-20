import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/product.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final Function() onSave;

  const ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _price;
  late String _imageUrl;
  late double _rating; 
  late String _unitsSold;
  String? _selectedStoreId;
  bool _isSuccess = false;

  List<dynamic> _fitnessSpots = [];

  @override
  void initState() {
    super.initState();
    _name = widget.product?.fields.name ?? "";
    _price = widget.product?.fields.price.toString() ?? "";
    _imageUrl = widget.product?.fields.imageUrl ?? "";
    _rating = double.tryParse(widget.product?.fields.rating ?? "0") ?? 0.0;
    _unitsSold = widget.product?.fields.unitsSold ?? "";
    _selectedStoreId = widget.product?.fields.store?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFitnessSpots();
    });
  }

  Future<void> _fetchFitnessSpots() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$djangoBaseUrl/store/api/spots/');
      if (mounted) {
        setState(() {
          _fitnessSpots = response;
        });
      }
    } catch (e) {
      print("Gagal fetch toko: $e");
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                "Sukses!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              const Text(
                "Produk berhasil diperbarui!",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                    widget.onSave();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Tutup", style: TextStyle(color: Colors.black87)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final bool isEdit = widget.product != null;

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Center(
        child: Column(
          children: [
            Text(
              isEdit ? "Edit Produk" : "Tambah Produk Baru",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B2B5A)),
            ),
            if (isEdit)
              Text(
                "${widget.product!.fields.name} (ID: ${widget.product!.pk})",
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("Nama Produk"),
                TextFormField(
                  initialValue: _name,
                  decoration: _inputDecoration("Masukkan nama produk"),
                  onChanged: (val) => _name = val,
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 12),

                _buildLabel("Harga (Rp)"),
                TextFormField(
                  initialValue: _price,
                  decoration: _inputDecoration("Masukkan harga produk (contoh: 50000)"),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _price = val,
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 12),

                _buildLabel("Rating"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _rating.toStringAsFixed(1).replaceAll('.', ','),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_rating < 5.0) {
                                  _rating += 0.1;
                                  _rating = double.parse(_rating.toStringAsFixed(1));
                                }
                              });
                            },
                            child: const Icon(Icons.arrow_drop_up, size: 24, color: Colors.grey),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_rating > 0.0) {
                                  _rating -= 0.1;
                                  _rating = double.parse(_rating.toStringAsFixed(1));
                                }
                              });
                            },
                            child: const Icon(Icons.arrow_drop_down, size: 24, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),

                _buildLabel("Jumlah Terjual"),
                TextFormField(
                  initialValue: _unitsSold,
                  decoration: _inputDecoration("Opsional (contoh: 100 atau 1rb+)"),
                  onChanged: (val) => _unitsSold = val,
                ),
                const SizedBox(height: 12),

                _buildLabel("URL Gambar"),
                TextFormField(
                  initialValue: _imageUrl,
                  decoration: _inputDecoration("https://example.com/image.jpg"),
                  onChanged: (val) => _imageUrl = val,
                  validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                ),
                const SizedBox(height: 12),

                _buildLabel("Toko (Fitness Spot)"),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("-- Pilih Toko --"),
                  value: _selectedStoreId,
                  isExpanded: true,
                  items: _fitnessSpots.map<DropdownMenuItem<String>>((spot) {
                    return DropdownMenuItem<String>(
                      value: spot['id'].toString(),
                      child: Text(
                        spot['name'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedStoreId = val;
                    });
                  },
                  validator: (val) => val == null ? "Pilih toko" : null,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text("Batal"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final Map<String, dynamic> dataPayload = {
                            "name": _name,
                            "price": int.tryParse(_price) ?? 0,
                            "image_url": _imageUrl,
                            "rating": _rating.toStringAsFixed(1), 
                            "units_sold": _unitsSold,
                            "store": _selectedStoreId,
                          };

                          dynamic response;
                          try {
                            if (isEdit) {
                              response = await request.postJson(
                                "$djangoBaseUrl/store/api/product/${widget.product!.pk}/edit/",
                                jsonEncode(dataPayload),
                              );
                            } else {
                              response = await request.postJson(
                                "$djangoBaseUrl/store/create-flutter/",
                                jsonEncode(dataPayload),
                              );
                            }

                            if (context.mounted) {
                              if (response['success'] == true || response['status'] == 'success') {
                                setState(() {
                                  _isSuccess = true;
                                });
                                await Future.delayed(const Duration(milliseconds: 800));

                                if (context.mounted) {
                                  _showSuccessDialog();
                                }
                                
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Gagal: ${response['message'] ?? response['error']}"),
                                    backgroundColor: Colors.red,
                                  )
                                );
                              }
                            }
                          } catch (e) {
                            if(context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.red),
                               );
                            }
                          }
                        }
                      },
                      child: Text(isEdit ? "Simpan Perubahan" : "Simpan Produk"),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (_isSuccess)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        "Produk berhasil diperbarui!",
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5C6B89)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}