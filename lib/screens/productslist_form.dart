import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/screens/home.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = "";
  int _price = 0;
  String _imageUrl = "";
  String _rating = "";
  String _unitsSold = "";
  String _storeId = "";

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Tambah Produk (Admin)')),
        backgroundColor: const Color(0xFF0E5A64),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Nama Produk",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _name = val,
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Harga (Angka)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) => _price = int.tryParse(val) ?? 0,
                validator: (val) => (int.tryParse(val!) == null) ? "Harus angka" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "URL Gambar",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _imageUrl = val,
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "ID Toko (Angka)",
                  hintText: "Contoh: 1",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) => _storeId = val,
                validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0E5A64), foregroundColor: Colors.white),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final response = await request.postJson(
                        "http://10.0.2.2:8000/store/create-flutter/",
                        jsonEncode({
                            "name": _name,
                            "price": _price,
                            "image_url": _imageUrl,
                            "rating": _rating,
                            "units_sold": _unitsSold,
                            "store": int.parse(_storeId)
                        }),
                    );
                    if (context.mounted) {
                        if (response['status'] == 'success') {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil!")));
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                        } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${response['message']}")));
                        }
                    }
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
