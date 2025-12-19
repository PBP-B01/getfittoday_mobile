import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/models/product.dart';
import 'package:getfittoday_mobile/screens/cart_page.dart';
import 'package:getfittoday_mobile/screens/home.dart';
import 'package:getfittoday_mobile/widgets/products_entry_card.dart';
import 'package:getfittoday_mobile/widgets/product_form_dialog.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

// =====PERUBAHAN BARU=====
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/widgets/site_navbar.dart';
// =====PERUBAHAN BARU=====

class ProductEntryListPage extends StatefulWidget {
  const ProductEntryListPage({super.key});

  @override
  State<ProductEntryListPage> createState() => _ProductEntryListPageState();
}

class _ProductEntryListPageState extends State<ProductEntryListPage> {
  // Search & Filter State
  String _uiSearchQuery = "";
  String _uiSortOption = "terbaru";
  final TextEditingController _searchController = TextEditingController();
  String _appliedSearchQuery = "";
  String _appliedSortOption = "terbaru";
  
  // Data & Pagination State
  List<Product> _products = [];
  bool _isLoading = true;
  int _cartCount = 0;
  
  // Variabel Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrevious = false;

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
      _updateCartCount();
      _fetchProducts(); // Panggil fetch pertama kali
    });
  }

  void refreshList() {
    _fetchProducts(page: _currentPage); // Refresh halaman saat ini
    _updateCartCount(); 
  }

  Future<void> _updateCartCount() async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.get('http://127.0.0.1:8000/store/api/cart/');
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

  // Method baru untuk fetch dengan pagination
  Future<void> _fetchProducts({int page = 1}) async {
    setState(() {
      _isLoading = true;
    });

    final request = context.read<CookieRequest>();
    
    // URL dengan parameter page
    final url = Uri.parse('http://127.0.0.1:8000/store/api/products/').replace(queryParameters: {
      'q': _appliedSearchQuery,
      'sort': _appliedSortOption,
      'page': page.toString(),
    });

    try {
      final response = await request.get(url.toString());
      
      if (response != null) {
        // Parsing data produk dari key 'products'
        List<Product> listProduct = [];
        for (var d in response['products']) {
          if (d != null) listProduct.add(Product.fromJson(d));
        }

        if (mounted) {
          setState(() {
            _products = listProduct;
            // Update metadata pagination
            _currentPage = response['current_page'];
            _totalPages = response['total_pages'];
            _hasNext = response['has_next'];
            _hasPrevious = response['has_previous'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching products: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Method untuk ganti halaman
  void _changePage(int newPage) {
    if (newPage >= 1 && newPage <= _totalPages) {
      _fetchProducts(page: newPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();
    
    // === MODE ADMIN: UBAH JADI TRUE UNTUK LIHAT HASIL ===
    final bool isAdmin = true;
    // ===================================================

    // =====PERUBAHAN BARU=====
    return Scaffold(
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
              // Tambahkan SiteNavBar
              const SiteNavBar(active: NavDestination.store), // =====PERUBAHAN BARU=====
              
              // Konten utama
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

  Widget _buildStoreContent(BuildContext context, CookieRequest request, bool isAdmin) {
    return Column(
      children: [
        // Header & Title
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

        // Search & Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Cari produk...",
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), 
                    ),
                    onChanged: (val) => _uiSearchQuery = val,
                    onSubmitted: (val) {
                      setState(() {
                        _uiSearchQuery = val;
                        _appliedSearchQuery = val;
                      });
                      _fetchProducts(page: 1); // Reset ke halaman 1 saat search
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
                    });
                    _fetchProducts(page: 1); // Reset ke halaman 1 saat filter
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

        // Grid Produk (Menggunakan State _products, bukan FutureBuilder lagi)
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
              ? const Center(child: Text("Produk tidak ditemukan."))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.50,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (_, index) {
                    return ProductEntryCard(
                      product: _products[index],
                      onRefresh: refreshList,
                    );
                  },
                ),
        ),

        // ===== PAGINATION CONTROLS =====
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.transparent, // Transparan agar menyatu dengan background
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Previous
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hasPrevious ? Colors.grey.shade400 : Colors.grey.shade200),
                ),
                child: IconButton(
                  onPressed: _hasPrevious ? () => _changePage(_currentPage - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  color: _hasPrevious ? const Color(0xFF1B2B5A) : Colors.grey.shade300,
                  tooltip: "Halaman Sebelumnya",
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Info Halaman
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ]
                ),
                child: Text(
                  "Halaman $_currentPage dari $_totalPages",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Color(0xFF1B2B5A),
                    fontSize: 14
                  ),
                ),
              ),
              
              const SizedBox(width: 12),

              // Tombol Next
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hasNext ? Colors.grey.shade400 : Colors.grey.shade200),
                ),
                child: IconButton(
                  onPressed: _hasNext ? () => _changePage(_currentPage + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                  color: _hasNext ? const Color(0xFF1B2B5A) : Colors.grey.shade300,
                  tooltip: "Halaman Selanjutnya",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}