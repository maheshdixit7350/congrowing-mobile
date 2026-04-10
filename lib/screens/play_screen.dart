import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/bottom_nav_bar.dart';

class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  static const _videos = [
    {
      'user': 'Neha S.',
      'handle': '@nehash',
      'caption': 'Morning mindfulness session 🌅 #growth #mindfulness',
      'likes': '2.4K',
      'comments': '128',
      'shares': '89',
      'thumb': 'https://lh3.googleusercontent.com/aida-public/AB6AXuD8UrqwOBfbsCf5lrDTpS9D6QgZO_txqpyUXyixMZGgOfoElyGryLBMX-IxttJ7yLIJjXjh5N5tKzeey_qC4VcXsSi3rD7-OJ54kgn4MuZ3ULxpeD-bcquqqIbOYS6nA8jfUyhpQDKTpRRqFfqNxwtfbLpFjsQnvNaNSNZ4nZoOR-7BLM9cdy_f2QDgEV2R8l_u5geyhXfS7z8ldlLw-g5A4M5Kz9aCAC0qos7iUWUKKWz_BWWhkM16-x5f5ABz-ZLsc0CPII7x3Eo',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDwUlzZTpEppXDkzGQXTpVsFTIPI-l6L8fBPZbDaXzjVer9-iKxt5aXElMcdxw1KNyU1d3aKUaJ8L0xYVBqdhVgzIZtdUQr6axSah9SlPjCLSZBq9bxEDL5gwFEyNQf9qC-JfSkEOagHbygY7YGqpofmAE2w2FdT_uAeBaUBuYWzeQn9Qs81Jz4RsbUuwz1iqhb5cajpe9GIseqkZ0ZZfp3SnAsnHt2x2k8J3E2Er5-AB-jCZQcuwz1JRPMBd4wTPfRMzLyHnI0ui4',
    },
    {
      'user': 'Yash V.',
      'handle': '@yashv',
      'caption': 'Study with me – 2 hours focus session 📚 #studygrind',
      'likes': '1.8K',
      'comments': '94',
      'shares': '56',
      'thumb': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDAL2d3jCWd61PuNeE5_AP1HxIIFc9XRovdGVD22H5vgMAuPakbHFwuk4nomQRhx5II7CPcFeb2nTBG6TqMhpx_OPJzsKwvYCCDp-2I2WcXerK6tGBg1jEoSI2kwmZerBlZJqbBZzoh2GIcF3RZD4pQmfG0mhOOXx35o7zdX5Qtv-H7l4b2cBQRSlI6IASI_5yUZr6RRmJWd6U8fcs98dgnTFWflfnrMSzNj-UVt2JCguAkHN2S228yETcbFkXhwPBHKEe--A-8Gt0',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNtt_wYgFTJxKDSxoIDe7i6JqU92xxzbjtCGgwtezQZBRakLxLj0PU8b5U9rZcYjB77rhNTOKvgdYVrrcROwDCIb2adTFXXxquIyYKAkIDub7mACH911QYYB6oJhw8yCYE10fFqB89m1dtd0youkatWJrSUmTbcUqj0ssaTSPeUjNy_kbVh-Bn74eVnc1bbUuo7d3yWLzzmE4i_lP10qvxqbQETzg6rpb9llMYYf29taPrR7zMZYJtp-IPQpMSdLcCtKLs0gMHkgw',
    },
    {
      'user': 'Jatin M.',
      'handle': '@jatinm',
      'caption': 'College life moments 🎓 #campuslife #collegediaries',
      'likes': '3.1K',
      'comments': '200',
      'shares': '112',
      'thumb': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCac3tg7f2AEtqWzXRNnAXsKnCSJexgo987SZs6M0dBjya_yBJzHvkXPfegxAkZLRdgVhVMRY9T-RJgRJb2yg0QwoKCJUSHKkMxDC2UVUZTh_5IJj-TzsSLeCWHz9OR9XQG-_WoT_XrBRaAKDkORrQ6nZ4W4zH5EeQpXOmL5nTDn8KqdAsuQVj19SH_xtahmJ8qKF7jFTYGgRYjz-kExJYPqch0vSeoYE83SUY0d1aJ9Gb8w3YGwlgT-S6WIlTCKWd4Ol2gYAs7AzY',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCvzpxNzlkNMl4OMTuvqM1f2kxHuWXIhkKNvq_2PhHmotMpL880kJZ69JJZ0d6bsLaMpnoi-LJyBvQ_PI79pO3RDrSPUvCUSsm2-snro_qApZhPPkPUUmfceFh08bLGVVPUXS_k1VY9R-PDH82h6RByM6zMaGTrJHQ_zyicnrtXBk4exltnf4jmRW20cvNs6TV-nLfy_XdmP9YPfnrE_xyfX93uES6-QQ9shV7bJJsvrzZlVU2It1HPapHXLf4eLbisZzq__YGFrss',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: _videos.length,

          itemBuilder: (ctx, i) {
            final v = _videos[i];
            return Stack(
              fit: StackFit.expand,
              children: [
                // Background image (thumbnail)
                CachedNetworkImage(imageUrl: v['thumb']!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                // Play icon
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded, color: Colors.white54, size: 70),
                ),
                // Right side actions
                Positioned(
                  right: 12,
                  bottom: 120,
                  child: Column(
                    children: [
                      _VideoAction(icon: Icons.favorite_rounded, label: v['likes']!, color: Colors.red),
                      const SizedBox(height: 20),
                      _VideoAction(icon: Icons.chat_bubble_rounded, label: v['comments']!),
                      const SizedBox(height: 20),
                      _VideoAction(icon: Icons.share_rounded, label: v['shares']!),
                      const SizedBox(height: 20),
                      ClipOval(
                        child: CachedNetworkImage(imageUrl: v['avatar']!, width: 44, height: 44, fit: BoxFit.cover),
                      ),
                    ],
                  ),
                ),
                // Bottom info
                Positioned(
                  left: 16,
                  right: 80,
                  bottom: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v['user']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(v['handle']!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(v['caption']!, style: GoogleFonts.inter(color: Colors.white, fontSize: 13), maxLines: 2),
                    ],
                  ),
                ),
                // Bottom nav
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BottomNavBar(currentIndex: 3),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VideoAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _VideoAction({required this.icon, required this.label, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
