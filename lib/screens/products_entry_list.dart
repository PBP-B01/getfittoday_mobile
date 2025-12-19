// products_entry_list.dart

import 'package:flutter/material.dart';

import 'package:getfittoday_mobile/models/product.dart';
import 'package:getfittoday_mobile/screens/cart_page.dart';
import 'package:getfittoday_mobile/screens/home.dart';
import 'package:getfittoday_mobile/widgets/products_entry_card.dart';
import 'package:getfittoday_mobile/widgets/product_form_dialog.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:getfittoday_mobile/state/auth_state.dart';

// =====PERUBAHAN BARU=====
// Import constants & SiteNavBar supaya background dan navbar Store sama dengan Home
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
// =====PERUBAHAN BARU=====


class ProductEntryListPage extends StatefulWidget {
  const ProductEntryListPage({super.key});

  @override
  State<ProductEntryListPage> createState() => _ProductEntryListPageState();
}

class _ProductEntryListPageState extends State<ProductEntryListPage> {
  String _uiSearchQuery = "";
  String _uiSortOption = "terbaru";
  final TextEditingController _searchController = TextEditingController();
  String _appliedSearchQuery = "";
  String _appliedSortOption = "terbaru";
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrevious = false;
  int _cartCount = 0; 

  final Map<String, String> _sortOptions = {
    "terbaru": "Terbaru",
    "price_asc": "Harga: Termurah",
    "price_desc": "Harga: Termahal",
    "rating_desc": "Rating: Tertinggi",
    "rating_asc": "Rating: Terendah",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSession();
      _updateCartCount();
    });
  }

  Future<void> _ensureSession() async {
    final request = context.read<CookieRequest>();
    if (request.loggedIn) return;
    try {
      final resp = await request.get('$djangoBaseUrl/auth/whoami/');
      final loggedIn = resp is Map &&
          (resp['logged_in'] == true ||
              resp['loggedIn'] == true ||
              resp['status'] == true ||
              resp['status'] == 'success');
      if (loggedIn) {
        request.loggedIn = true;
        request.jsonData = Map<String, dynamic>.from(resp);
        if (mounted) {
          context.read<AuthState>().setFromLoginResponse(
                Map<String, dynamic>.from(resp),
                fallbackUsername: resp['username']?.toString(),
              );
        }
      }
    } catch (_) {
      // ignore: avoid_print
      print('whoami check failed');
    }
  }

  void refreshList() {
    setState(() {});
    _updateCartCount(); 
  }

  Future<void> _updateCartCount() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('$djangoBaseUrl/store/api/cart/');
      if (response is Map<String, dynamic> && response['status'] == 'success') {
          final cart = Cart.fromJson(response);
          setState(() {
            _cartCount = cart.items.length;
          });
      }
    } catch (e) {
      print("Gagal ambil keranjang: $e");
    }
  }

  Future<ProductPage> fetchProduct(CookieRequest request) async {
    final url = Uri.parse('$djangoBaseUrl/store/api/products/').replace(queryParameters: {
      'q': _appliedSearchQuery,
      'sort': _appliedSortOption,
      'page': _currentPage.toString(),
    });

    final response = await request.get(url.toString());

    final List<dynamic> rawProducts;
    int currentPage = _currentPage;
    int totalPages = _totalPages;
    bool hasNext = _hasNext;
    bool hasPrevious = _hasPrevious;

    if (response is List) {
      rawProducts = response;
      currentPage = 1;
      totalPages = 1;
      hasNext = false;
      hasPrevious = false;
    } else if (response is Map<String, dynamic> && response['products'] is List) {
      rawProducts = response['products'] as List<dynamic>;
      currentPage = int.tryParse(response['current_page']?.toString() ?? '') ?? 1;
      totalPages = int.tryParse(response['total_pages']?.toString() ?? '') ?? 1;
      hasNext = response['has_next'] == true;
      hasPrevious = response['has_previous'] == true;
    } else {
      return ProductPage.empty();
    }

    final listProduct = rawProducts.where((d) => d != null).map((d) => Product.fromJson(d)).toList();

    // Simpan metadata pagination ke state.
    if (mounted) {
      setState(() {
        _currentPage = currentPage;
        _totalPages = totalPages;
        _hasNext = hasNext;
        _hasPrevious = hasPrevious;
      });
    }

    return ProductPage(
      products: listProduct,
      currentPage: currentPage,
      totalPages: totalPages,
      hasNext: hasNext,
      hasPrevious: hasPrevious,
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    final isAdmin = context.watch<AuthState>().isAdmin;

    // =====PERUBAHAN BARU=====
    // Gunakan Scaffold tanpa AppBar tapi dengan Container gradient agar sama seperti Home
    return Scaffold(
      // jangan atur backgroundColor di sini; gunakan Container dengan gradient seperti home.dart
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStartColor, gradientEndColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Tambahkan SiteNavBar dengan active: store
              const SiteNavBar(active: NavDestination.store), // =====PERUBAHAN BARU=====
              // Konten utama di bawah navbar
              Expanded(
                child: _buildStoreContent(context, request, isAdmin),
              ),
            ],
          ),
        ),
      ),
    );
    // =====PERUBAHAN BARU=====
  }

  // Dipisahkan ke method agar build lebih bersih
  Widget _buildStoreContent(BuildContext context, CookieRequest request, bool isAdmin) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const MyHomePage())
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("Kembali ke Home", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      "STORE",
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: Color(0xFF1B2B5A), 
                        letterSpacing: 1.0
                      ),
                    ),
                  ),

                  // === HANYA TAMPIL JIKA BUKAN ADMIN ===
                  if (!isAdmin) 
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                           Navigator.push(
                             context, 
                             MaterialPageRoute(builder: (context) => const CartPage())
                           ).then((_) => _updateCartCount()); 
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              )
                            ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Keranjang", 
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "$_cartCount", 
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),

        // SEARCH & FILTER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Cari produk...",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14), 
                    ),
                    onChanged: (val) => _uiSearchQuery = val,
                    onSubmitted: (val) {
                      setState(() {
                        _uiSearchQuery = val;
                        _appliedSearchQuery = val;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortOptions.containsKey(_uiSortOption) ? _uiSortOption : "terbaru",
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      items: _sortOptions.entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _uiSortOption = newValue!);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF1B2B5A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      _appliedSearchQuery = _searchController.text;
                      _appliedSortOption = _uiSortOption;
                      _currentPage = 1;
                    });
                  },
                  child: const Text("Filter", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              if (isAdmin) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ProductFormDialog(
                          product: null,
                          onSave: refreshList,
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 4),
                        Text("Tambah Produk", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: FutureBuilder(
            future: fetchProduct(context.read<CookieRequest>()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (!snapshot.hasData || snapshot.data!.products.isEmpty) {
                return const Center(child: Text("Produk tidak ditemukan."));
              }

              final page = snapshot.data!;
              final products = page.products;

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.50, 
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        return ProductEntryCard(
                          product: products[index],
                          onRefresh: refreshList,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaginationBar(page),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationBar(ProductPage page) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: page.hasPrevious
              ? () {
                  setState(() {
                    _currentPage = (_currentPage - 1).clamp(1, page.totalPages);
                  });
                }
              : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            "Halaman ${page.currentPage} dari ${page.totalPages}",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2B5A),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: page.hasNext
              ? () {
                  setState(() {
                    _currentPage = (_currentPage + 1).clamp(1, page.totalPages);
                  });
                }
              : null,
        ),
      ],
    );
  }
}

class ProductPage {
  final List<Product> products;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  ProductPage({
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory ProductPage.empty() => ProductPage(
        products: const [],
        currentPage: 1,
        totalPages: 1,
        hasNext: false,
        hasPrevious: false,
      );
}
