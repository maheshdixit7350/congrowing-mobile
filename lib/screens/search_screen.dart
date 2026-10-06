import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_colors.dart';
import '../utils/nav_utils.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../main.dart' show supabaseInitialized;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<UserModel> _searchResults = [];
  final Set<String> _followingIds = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
    _searchUsers(''); // Load initial users
  }

  Future<void> _loadFollowing() async {
    if (!supabaseInitialized) return;
    try {
      final myUid = UserService.instance.currentUser?.id;
      if (myUid == null) return;
      
      final res = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', myUid);
      
      if (mounted) {
        setState(() {
          _followingIds.addAll(res.map((r) => r['following_id'] as String));
        });
      }
    } catch (_) {}
  }

  Future<void> _searchUsers(String query) async {
    if (!supabaseInitialized) return;
    
    setState(() => _loading = true);
    try {
      final myUid = UserService.instance.currentUser?.id;
      
      var queryBuilder = Supabase.instance.client.from('users').select();
      
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or('name.ilike.%$query%,username.ilike.%$query%');
      }
      
      final res = await queryBuilder.limit(20);
      
      final users = res
          .map((m) => UserModel.fromJson(m))
          .where((u) => u.id != myUid) // exclude self
          .toList();
          
      if (mounted) {
        setState(() {
          _searchResults = users;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(UserModel user) async {
    final targetUid = user.id;
    final isFollowing = _followingIds.contains(targetUid);
    
    setState(() {
      if (isFollowing) {
        _followingIds.remove(targetUid);
      } else {
        _followingIds.add(targetUid);
      }
    });

    if (isFollowing) {
      await UserService.instance.unfollowUser(targetUid);
    } else {
      await UserService.instance.followUser(targetUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => safeNavigateBack(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _ctrl,
            onChanged: _searchUsers,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _searchResults.isEmpty
              ? Center(child: Text('No users found', style: GoogleFonts.inter(color: AppColors.textSecondaryLight)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, i) {
                    final u = _searchResults[i];
                    final isFollowing = _followingIds.contains(u.id);
                    final initial = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: u.avatarUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 18),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 18),
                                ),
                              ),
                            ),
                      title: Text(u.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('@${u.username}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondaryLight)),
                      trailing: GestureDetector(
                        onTap: () => _toggleFollow(u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: isFollowing ? Colors.transparent : AppColors.primary,
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: GoogleFonts.inter(
                              color: isFollowing ? AppColors.primary : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
