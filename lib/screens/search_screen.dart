import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  static const _users = [
    {'name': 'Neha Sharma', 'user': '@nehash', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDwUlzZTpEppXDkzGQXTpVsFTIPI-l6L8fBPZbDaXzjVer9-iKxt5aXElMcdxw1KNyU1d3aKUaJ8L0xYVBqdhVgzIZtdUQr6axSah9SlPjCLSZBq9bxEDL5gwFEyNQf9qC-JfSkEOagHbygY7YGqpofmAE2w2FdT_uAeBaUBuYWzeQn9Qs81Jz4RsbUuwz1iqhb5cajpe9GIseqkZ0ZZfp3SnAsnHt2x2k8J3E2Er5-AB-jCZQcuwz1JRPMBd4wTPfRMzLyHnI0ui4'},
    {'name': 'Yash Verma', 'user': '@yashv', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBNtt_wYgFTJxKDSxoIDe7i6JqU92xxzbjtCGgwtezQZBRakLxLj0PU8b5U9rZcYjB77rhNTOKvgdYVrrcROwDCIb2adTFXXxquIyYKAkIDub7mACH911QYYB6oJhw8yCYE10fFqB89m1dtd0youkatWJrSUmTbcUqj0ssaTSPeUjNy_kbVh-Bn74eVnc1bbUuo7d3yWLzzmE4i_lP10qvxqbQETzg6rpb9llMYYf29taPrR7zMZYJtp-IPQpMSdLcCtKLs0gMHkgw'},
    {'name': 'Jatin Malik', 'user': '@jatinm', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCvzpxNzlkNMl4OMTuvqM1f2kxHuWXIhkKNvq_2PhHmotMpL880kJZ69JJZ0d6bsLaMpnoi-LJyBvQ_PI79pO3RDrSPUvCUSsm2-snro_qApZhPPkPUUmfceFh08bLGVVPUXS_k1VY9R-PDH82h6RByM6zMaGTrJHQ_zyicnrtXBk4exltnf4jmRW20cvNs6TV-nLfy_XdmP9YPfnrE_xyfX93uES6-QQ9shV7bJJsvrzZlVU2It1HPapHXLf4eLbisZzq__YGFrss'},
    {'name': 'Kunal Mehta', 'user': '@kunalm', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCG_OXZML_Tq2-5z87ascMyUXY628UIlx1XxaSdZ5VxHkOO-2MbzJyepUZznH7mIpZDYYBM_fFhZU_SmGmbPnuXGHEp2EJKCfEpC-JKEgDQAXsWJ5ARyxri9i9TpR6mNYBH_jNSwuq_8aPFjRPaghfU99nD2m3DoXjdfwGOUzhZF_YCs9EruezXIcwTjMnUk8_xx_jEALXt2iVI4EN_FLbveWWxj6j3lU_p10JcuXNYiN3feHy5bc0BuTvyReOJONDn_N77dOk4E04'},
    {'name': 'David Lee', 'user': '@davidl', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAfuha8VGG0BPiBwuldEhiK9YAE0ZJIm3M8NQLRRMrpBGwNbyf7YYtzio6JXwwEC5SKcqFfjg7Aczu0Poy_GmrU4zm7YgZvO4m5vURKmgOtHqYqRKmWvzeO3ElnB_-erPhAy00ddbmEwdiv5Wz66YfB5PvjgK2S390u-8j9MFyWGS6n40kKzw2vCeDkDM6DY_9seyet1uzDAIXG9o12iUI5XSMn7uQ9EAvzJhX9pW6kwZCekMVnS5zMLADilTBQL7Nu3l_cUOtl9bY'},
    {'name': 'Maya Gupta', 'user': '@mayag', 'url': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAGGnQbm1ehPSo92cYwsOLK23IJyCBQwUDE4faKq-R_5y_o0uvALCRrvZ2dzUqSLPUuzco5VF-ax43xaE8bCJLzu0Fp6XRN-2gjZ1BZ5JImcyudet4ygoZ6I6mN5202iTnbQ4HAqCHh_-7_GbU_mythWdepWp7XpSNpdBTnWKurtRXr6xIoIKxflEb9lqQTHJ67--HtYI5aMI1bia6QGBMagllJYfo37AztM5vCcbGH6lO4G07HkfAwl2D-uxNOng6NLBYb0VsLL_I'},
  ];

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return List<Map<String, String>>.from(_users);
    return _users.where((u) => u['name']!.toLowerCase().contains(_query.toLowerCase())).toList().cast<Map<String, String>>();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => safeNavigateBack(context)),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search people...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondaryLight, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondaryLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      body: _filtered.isEmpty
          ? Center(child: Text('No users found', style: GoogleFonts.inter(color: AppColors.textSecondaryLight)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final u = _filtered[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: ClipOval(child: CachedNetworkImage(imageUrl: u['url']!, width: 50, height: 50, fit: BoxFit.cover)),
                  title: Text(u['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(u['user']!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Follow', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}
