import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:du_xuan/core/constants/app_colors.dart';
import 'package:du_xuan/core/constants/app_text_styles.dart';
import 'package:du_xuan/core/utils/maps_launcher.dart';
import 'package:du_xuan/domain/entities/map_marker_data.dart';
import 'package:du_xuan/viewmodels/map/map_viewmodel.dart';

class MapTab extends StatefulWidget {
  final MapViewModel viewModel;
  final int userId;

  const MapTab({super.key, required this.viewModel, required this.userId});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  static const LatLng _vnCenter = LatLng(16.0, 106.0);

  final MapController _mapController = MapController();
  MapMarkerData? _selectedMarker;

  @override
  void didUpdateWidget(covariant MapTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _selectedMarker = null;
    }
  }

  bool _isSelectedMarker(MapMarkerData marker) {
    final selected = _selectedMarker;
    if (selected == null) return false;

    return selected.planId == marker.planId &&
        selected.lat == marker.lat &&
        selected.lng == marker.lng &&
        selected.location == marker.location;
  }

  void _focusMarker(MapMarkerData marker) {
    setState(() => _selectedMarker = marker);
    _mapController.move(LatLng(marker.lat, marker.lng), 13);
  }

  void _resetView() {
    _mapController.move(_vnCenter, 5.5);
    setState(() => _selectedMarker = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgWarm, AppColors.bgCream],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final hasMarkers = widget.viewModel.markers.isNotEmpty;
            final canShowMap =
                !widget.viewModel.hasLoaded || widget.viewModel.hasOngoingPlans;

            if (!canShowMap) {
              return _buildNoOngoingOverlay();
            }

            return Stack(
              children: [
                _buildMap(),
                _buildHeader(),
                if (!widget.viewModel.isLoading && !hasMarkers)
                  _buildEmptyOverlay(),
                if (widget.viewModel.isLoading) _buildLoading(),
                _buildZoomControls(),
                if (_selectedMarker != null) _buildPopup(_selectedMarker!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap() {
    final markers = widget.viewModel.markers;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _vnCenter,
        initialZoom: 5.5,
        onTap: (_, _) {
          setState(() => _selectedMarker = null);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.du_xuan',
        ),
        MarkerLayer(
          markers: markers.map((marker) {
            final isSelected = _isSelectedMarker(marker);
            final markerColor = isSelected
                ? AppColors.goldDeep
                : AppColors.primary;

            return Marker(
              point: LatLng(marker.lat, marker.lng),
              width: 44,
              height: 56,
              child: GestureDetector(
                onTap: () => _focusMarker(marker),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: markerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: markerColor.withValues(alpha: 0.35),
                            blurRadius: isSelected ? 12 : 9,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelected ? Icons.place : Icons.place_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(10, 6),
                      painter: _TrianglePainter(color: markerColor),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final markerCount = widget.viewModel.markers.length;
    final unresolvedCount = widget.viewModel.unresolvedLocations.length;

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bản đồ hành trình',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _headerActionButton(
                      icon: Icons.refresh_rounded,
                      onTap: () =>
                          widget.viewModel.loadMarkers(widget.userId, force: true),
                    ),
                    const SizedBox(width: 6),
                    _headerActionButton(
                      icon: Icons.my_location_rounded,
                      onTap: _resetView,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _buildHeaderSubtitle(markerCount, unresolvedCount),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildHeaderSubtitle(int markerCount, int unresolvedCount) {
    if (widget.viewModel.isLoading) return 'Đang đồng bộ địa điểm...';

    final error = widget.viewModel.errorMessage;
    if (error != null && error.isNotEmpty) {
      return error;
    }

    if (widget.viewModel.hasLoaded && !widget.viewModel.hasOngoingPlans) {
      return 'Không có kế hoạch đang diễn ra để hiển thị bản đồ';
    }

    if (markerCount == 0 && unresolvedCount == 0) {
      return 'Chưa có điểm đến nào trên bản đồ';
    }

    if (markerCount == 0 && unresolvedCount > 0) {
      return 'Không định vị được $unresolvedCount địa điểm';
    }

    if (unresolvedCount > 0) {
      return '$markerCount điểm đến • $unresolvedCount địa điểm chưa định vị';
    }

    return '$markerCount điểm đến • Chạm marker để xem chi tiết';
  }

  Widget _headerActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.bgCream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          ),
          child: Icon(icon, size: 18, color: AppColors.textMedium),
        ),
      ),
    );
  }

  Widget _buildEmptyOverlay() {
    final unresolved = widget.viewModel.unresolvedLocations;
    final preview = unresolved.take(2).join(' • ');

    return Positioned.fill(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Chưa có địa điểm để hiển thị',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                unresolved.isEmpty
                    ? 'Hãy thêm địa điểm trong các hoạt động của bạn.'
                    : 'Một số địa điểm chưa định vị được. Kiểm tra lại tên địa chỉ chi tiết hơn.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () =>
                    widget.viewModel.loadMarkers(widget.userId, force: true),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'Tải lại',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Đang tìm địa điểm...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopup(MapMarkerData marker) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDeep],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.location,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        marker.title,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        marker.planName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _selectedMarker = null),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        '/itinerary',
                        arguments: marker.planId,
                      );

                      if (!mounted) return;
                      await widget.viewModel.loadMarkers(
                        widget.userId,
                        force: true,
                      );
                      if (!mounted) return;
                      setState(() => _selectedMarker = null);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(
                      'Mở kế hoạch',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      MapsLauncher.launchCoordinates(
                        context,
                        marker.lat,
                        marker.lng,
                        marker.location,
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primarySoft.withValues(
                        alpha: 0.15,
                      ),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: Text(
                      'Chỉ đường',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 14,
      bottom: _selectedMarker != null ? 174 : 24,
      child: Container(
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _zoomButton(
              icon: Icons.add_rounded,
              onTap: () {
                final zoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, zoom + 1);
              },
            ),
            Divider(color: AppColors.divider.withValues(alpha: 0.8), height: 1),
            _zoomButton(
              icon: Icons.remove_rounded,
              onTap: () {
                final zoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, zoom - 1);
              },
            ),
            Divider(color: AppColors.divider.withValues(alpha: 0.8), height: 1),
            _zoomButton(icon: Icons.my_location_rounded, onTap: _resetView),
          ],
        ),
      ),
    );
  }

  Widget _zoomButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 42,
          child: Icon(icon, color: AppColors.textMedium, size: 22),
        ),
      ),
    );
  }

  Widget _buildNoOngoingOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Không có kế hoạch đang diễn ra',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Bản đồ chỉ hiển thị địa điểm của kế hoạch đang diễn ra.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vẽ mũi nhọn dưới marker.
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final trianglePath = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(trianglePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
