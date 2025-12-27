class BirdInfo {
  final String commonName;
  final String scientificName;
  final String description;
  final String observer;
  final DateTime observedAt;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  BirdInfo({
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.observer,
    required this.observedAt,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });
}
