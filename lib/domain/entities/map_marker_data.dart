/// Dữ liệu 1 marker trên bản đồ
class MapMarkerData {
  final String title;
  final String location;
  final String planName;
  final int planId;
  final double lat;
  final double lng;

  const MapMarkerData({
    required this.title,
    required this.location,
    required this.planName,
    required this.planId,
    required this.lat,
    required this.lng,
  });
}
