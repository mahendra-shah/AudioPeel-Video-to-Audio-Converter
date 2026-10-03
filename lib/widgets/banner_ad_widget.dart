import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/ad_provider.dart';

/// Displays a Google Mobile Ads [BannerAd] (320 × 50).
///
/// Returns [SizedBox.shrink] when [AdProvider.enabled] is false (consent not
/// yet granted, or ads disabled for this session).
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adProvider = context.read<AdProvider>();
    if (adProvider.enabled && _ad == null) {
      _load(adProvider);
    }
  }

  void _load(AdProvider adProvider) {
    _ad = adProvider.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
    );
    _ad!.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = context.watch<AdProvider>();

    if (!adProvider.enabled || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
