import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'full_screen_image_view.dart';
import 'chat_coversation.dart';
import 'chat_screen.dart';
import 'other_user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemViewScreen extends StatefulWidget {
  final String itemName;
  final String description;
  final String category;
  final String contactInfo;
  final String location;
  final List<String> imageUrls;
  final String donorName;
  final String donorImageUrl;
  final String uid;

  const ItemViewScreen({
    super.key,
    required this.itemName,
    required this.description,
    required this.category,
    required this.contactInfo,
    required this.imageUrls,
    required this.location,
    required this.donorName,
    required this.donorImageUrl,
    required this.uid,
  });

  @override
  _ItemViewScreenState createState() => _ItemViewScreenState();
}

class _ItemViewScreenState extends State<ItemViewScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();

    // Initialize and load the banner ad
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4356788983865136/9996274476',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Failed to load a banner ad: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 29, 150, 122),
                Color.fromARGB(255, 102, 187, 153),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.itemName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),
                  // Image carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 260,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      viewportFraction: 0.9,
                    ),
                    items: widget.imageUrls.map((url) {
                      return Builder(
                        builder: (BuildContext context) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenImageViewer(
                                    imageUrls: widget.imageUrls,
                                    initialIndex: widget.imageUrls.indexOf(url),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset('assets/images/placeholder.png');
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Item Details
                  Center(
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.itemName,
                                style: theme.textTheme.titleLarge!
                                    .copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.category, size: 18),
                                  label: Text(widget.category),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                                Chip(
                                  avatar: const Icon(Icons.location_on, size: 18),
                                  label: Text(widget.location),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text('Description',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(widget.description, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Donor Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtherUserProfileScreen(userId: widget.uid),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: widget.donorImageUrl.isNotEmpty
                                ? NetworkImage(widget.donorImageUrl)
                                : const AssetImage('assets/images/default_avatar.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Donated by',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Text(
                                widget.donorName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // Contact Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                        if (currentUserId == widget.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("You can't chat with yourself.")),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversation: ChatConversation(
                                id: widget.uid,
                                name: widget.donorName,
                                imageUrl: widget.donorImageUrl,
                              ),
                              faqs: [
                                "Is this item still available?",
                                "Can you provide more details about the item?",
                                "What is the condition of the item?",
                                "Can I pick it up today?",
                              ], // Add your FAQs here
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 240, 186, 37),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        shadowColor: const Color.fromARGB(255, 240, 105, 159),
                      ),
                      icon: const Icon(Icons.message),
                      label: const Text('Contact Donator', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          // Banner Ad
          if (_isBannerAdLoaded)
            SizedBox(
              height: _bannerAd.size.height.toDouble(),
              width: _bannerAd.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }
}
