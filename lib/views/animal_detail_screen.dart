import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../controllers/comment_controller.dart';
import '../data/bird_repository.dart';
import '../providers/favorites_provider.dart';
import 'edit_animal_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> animalData;
  final String? animalId;

  const AnimalDetailScreen({super.key, required this.animalData, this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  static const Color _primary = Color(0xFF00A86B);
  final TextEditingController _commentController = TextEditingController();
  bool _sending = false;
  late final CommentController _commentControllerLogic;

  @override
  void initState() {
    super.initState();
    _commentControllerLogic = CommentController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (widget.animalId == null) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _commentControllerLogic.addComment(animalId: widget.animalId!, text: text);
      _commentController.clear();
    } on StateError catch (e) {
      if (mounted) {
        final msg = e.message == 'require_login' ? 'Bạn cần đăng nhập để bình luận' : 'Không gửi được bình luận';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không gửi được bình luận')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final isFav = widget.animalId != null && favorites.isAnimalFavorite(widget.animalId!);
    final name = (widget.animalData['name'] ?? '') as String;
    final species = (widget.animalData['species'] ?? '') as String;

    final birdInfo = birdRepository[species];

    final rawDescription = (widget.animalData['description'] ?? '') as String;
    final description = (rawDescription.isEmpty || rawDescription == 'No description available')
        ? (birdInfo?.description.isNotEmpty == true ? birdInfo!.description : 'Không có mô tả chi tiết.')
        : rawDescription;

    final scientificName = birdInfo?.scientificName ?? '';
    final imageUrl = (widget.animalData['imageUrl'] ?? '') as String;
    final observer = (widget.animalData['observer'] ?? '') as String;
    final observedOn = (widget.animalData['observedOn'] ?? '') as String;
    final location = widget.animalData['location'] as GeoPoint?;

    final double? lat = location?.latitude;
    final double? lng = location?.longitude;

    String locationText = 'Không rõ vị trí';
    if (lat != null && lng != null) {
      locationText = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Chi tiết động vật (chim)'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.animalId != null)
            IconButton(
              tooltip: isFav ? 'Bỏ yêu thích' : 'Yêu thích',
              icon: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.pinkAccent : Colors.white,
              ),
              onPressed: () => favorites.toggleAnimal(widget.animalId!),
            ),
          if (widget.animalId != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAnimalScreen(
                      animalId: widget.animalId!,
                      initialData: widget.animalData,
                      fallbackLat: lat,
                      fallbackLng: lng,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name.isNotEmpty ? name : '(Không có tên)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                if (species.isNotEmpty)
                  Text(
                    species,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                if (scientificName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    scientificName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Mô tả',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thông tin quan sát',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                if (observer.isNotEmpty) Text('Người quan sát: $observer'),
                if (observedOn.isNotEmpty) Text('Thời gian quan sát: $observedOn'),
                const SizedBox(height: 4),
                Text(locationText),
                const SizedBox(height: 12),
                if (lat != null && lng != null)
                  SizedBox(
                    height: 240,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 12,
                        interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.rotate),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_firebase_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                _CommentsSection(
                  animalId: widget.animalId,
                  controller: _commentController,
                  sending: _sending,
                  onSend: _submitComment,
                  controllerLogic: _commentControllerLogic,
                ),
              ],
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final String? animalId;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final CommentController controllerLogic;

  const _CommentsSection({
    required this.animalId,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.controllerLogic,
  });

  @override
  Widget build(BuildContext context) {
    if (animalId == null) return const SizedBox.shrink();
    final auth = FirebaseAuth.instance;
    final commentsStream = controllerLogic.streamComments(animalId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bình luận', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Nhập bình luận...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: sending ? null : onSend,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: commentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('Chưa có bình luận', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final text = (data['text'] ?? '').toString();
                final userName = (data['userName'] ?? 'Người dùng').toString();
                final ts = data['createdAt'] as Timestamp?;
                final date = ts?.toDate();
                final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '';
                final List<dynamic> likeArr = List<dynamic>.from(data['likes'] ?? const []);
                final List<dynamic> dislikeArr = List<dynamic>.from(data['dislikes'] ?? const []);
                final userId = auth.currentUser?.uid;
                final liked = userId != null && likeArr.contains(userId);
                final disliked = userId != null && dislikeArr.contains(userId);

                Future<void> vote(bool isLike) async {
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bạn cần đăng nhập để bình chọn')),
                    );
                    return;
                  }
                  try {
                    await controllerLogic.vote(
                      animalId: animalId!,
                      commentId: d.id,
                      isLike: isLike,
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể bình chọn')),
                    );
                  }
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.thumb_up_alt,
                              size: 18,
                              color: liked ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => vote(true),
                          ),
                          Text(likeArr.length.toString(), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.thumb_down_alt,
                              size: 18,
                              color: disliked ? Colors.redAccent : Colors.grey,
                            ),
                            onPressed: () => vote(false),
                          ),
                          Text(dislikeArr.length.toString(), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
