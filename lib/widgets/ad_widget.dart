import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget customizado para exibir anúncios reais do Google AdMob
class CustomAdWidget extends StatefulWidget {
  final double height;
  final String? placeholderText;
  final bool isProduction;

  const CustomAdWidget({
    super.key,
    this.height = 80,
    this.placeholderText,
    this.isProduction = false,
  });

  @override
  State<CustomAdWidget> createState() => _CustomAdWidgetState();
}

class _CustomAdWidgetState extends State<CustomAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isProduction) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Falha ao carregar anúncio: $error');
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
        },
        onAdOpened: (ad) {
          debugPrint('📱 Anúncio aberto');
        },
        onAdClosed: (ad) {
          debugPrint('📱 Anúncio fechado');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se é produção e o anúncio carregou, mostrar anúncio real
    if (widget.isProduction && _isAdLoaded && _bannerAd != null) {
      return Container(
        width: double.infinity,
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AdWidget(ad: _bannerAd!), // Usar AdWidget do Google Mobile Ads
      );
    }
    
    // Caso contrário, mostrar placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isProduction 
                ? 'Carregando anúncio...' 
                : 'Modo de desenvolvimento - anúncio desabilitado'
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isProduction ? Icons.refresh : Icons.ads_click,
                color: Colors.grey.shade400,
                size: widget.height > 60 ? 28 : 20,
              ),
              const SizedBox(height: 4),
              Text(
                widget.isProduction 
                  ? 'Carregando...'
                  : widget.placeholderText ?? 'Anúncio (dev mode)',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: widget.height > 60 ? 13 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget especializado para banner ads
class BannerAdWidget extends CustomAdWidget {
  const BannerAdWidget({
    super.key,
    super.isProduction = false,
  }) : super(
    height: 80,
    placeholderText: 'Banner publicitário',
  );
}

/// Widget para anúncios intersticiais
class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;
  static int _showCount = 0;
  static const int _showFrequency = 3; // Mostrar a cada 3 vezes

  static void load() {
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
          debugPrint('✅ Anúncio intersticial carregado');
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Falha ao carregar intersticial: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  static void show() {
    _showCount++;
    
    // Só mostrar a cada X vezes
    if (_showCount % _showFrequency != 0) {
      return;
    }

    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isLoaded = false;
          load(); // Carregar próximo anúncio
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isLoaded = false;
          load(); // Tentar carregar novamente
        },
      );
      
      _interstitialAd!.show();
    } else {
      load(); // Se não carregou, tentar carregar
    }
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}

/// Configurações dos anúncios
class AdConfig {
  // IMPORTANTE: Substitua pelos seus IDs reais do AdMob
  
  // IDs de TESTE (use durante desenvolvimento)
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  
  // IDs REAIS (substitua pelos seus quando criar a conta AdMob)
  static const String realBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String realInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  static const String realRewardedId = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
  
  // Usar IDs de teste por enquanto
  static String get bannerId => testBannerId;
  static String get interstitialId => testInterstitialId;
  static String get rewardedId => testRewardedId;
  
  // Configurações
  static const bool enableAds = true;
  static const bool showInDevelopment = true;
}