import 'package:flutter/material.dart';
import 'package:getfittoday_mobile/constants.dart';
import 'package:getfittoday_mobile/models/fitness_spot.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationSidebar extends StatefulWidget {
  final List<FitnessSpot> spots;
  final Function(FitnessSpot) onSpotSelected;
  final FitnessSpot? selectedSpot;
  final bool isMobile;

  const LocationSidebar({
    super.key,
    required this.spots,
    required this.onSpotSelected,
    this.selectedSpot,
    this.isMobile = false,
  });

  @override
  State<LocationSidebar> createState() => _LocationSidebarState();
}

class _LocationSidebarState extends State<LocationSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<FitnessSpot> _filteredSpots = [];
  bool _isInternalSelection = false; // Flag to track source of selection

  @override
  void initState() {
    super.initState();
    _filteredSpots = widget.spots;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(LocationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spots != oldWidget.spots) {
      _onSearchChanged();
    }
    
    // Scroll to selected spot if it changed and wasn't selected from the sidebar itself
    if (widget.selectedSpot != oldWidget.selectedSpot && widget.selectedSpot != null) {
      if (_isInternalSelection) {
        // Reset flag and don't scroll
        _isInternalSelection = false;
      } else {
        // Selection came from map (or elsewhere), so scroll to it
        _scrollToSelectedSpot();
      }
    }
  }

  void _scrollToSelectedSpot() {
    if (widget.selectedSpot == null) return;
    
    final index = _filteredSpots.indexWhere((s) => s.placeId == widget.selectedSpot!.placeId);
    if (index != -1) {
      // Use a slight delay to ensure list is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // Simple approximation:
          const double itemHeight = 80.0; // Approximate height of ListTile + padding
          final double targetOffset = index * itemHeight;
          
          // Clamp offset
          final double maxScroll = _scrollController.position.maxScrollExtent;
          final double offset = targetOffset.clamp(0.0, maxScroll);

          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSpots = widget.spots;
      } else {
        _filteredSpots = widget.spots.where((spot) {
          return spot.name.toLowerCase().contains(query) ||
                 spot.address.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isMobile ? double.infinity : 350,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isMobile 
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.isMobile 
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.zero,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryNavColor,
              ),
              child: Center(
                child: Text(
                  'Sport Centers',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Search
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari spot di daftar ini...',
                  hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ),

            // List
            Expanded(
              child: _filteredSpots.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          widget.spots.isEmpty 
                            ? 'No spots found in this area.\nTry panning the map.'
                            : 'No spots match your search.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredSpots.length,
                      itemBuilder: (context, index) {
                        final spot = _filteredSpots[index];
                        final isSelected = widget.selectedSpot?.placeId == spot.placeId;
                        
                        return InkWell(
                          onTap: () {
                            // Set internal selection flag
                            _isInternalSelection = true;
                            widget.onSpotSelected(spot);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : Colors.white,
                              border: Border.all(
                                color: isSelected ? primaryNavColor : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  spot.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: inputTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  spot.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: inkWeakColor,
                                  ),
                                ),
                                if (spot.rating != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${spot.rating} (${spot.ratingCount} reviews)',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: inputTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
