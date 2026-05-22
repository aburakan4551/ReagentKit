import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';

class PaywallTier {
  final String identifier;
  final String title;
  final String description;
  final String priceString;
  final String periodSuffix;
  final String badge;
  final Package? package;

  const PaywallTier({
    required this.identifier,
    required this.title,
    required this.description,
    required this.priceString,
    required this.periodSuffix,
    required this.badge,
    this.package,
  });
}

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PaywallTier? _selectedTier;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final premiumService = ref.watch(premiumServiceProvider);
    final offerings = premiumService.activeOfferings;

    // Auto-dismiss if purchased
    if (premiumService.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    // Build tiers
    final List<PaywallTier> tiers = [];
    if (offerings.isNotEmpty) {
      for (final package in offerings) {
        final product = package.storeProduct;
        final cleanTitle = product.title.split('(').first.trim();
        final isLifetime = package.packageType == PackageType.lifetime || cleanTitle.toLowerCase().contains('lifetime');
        final isAnnual = package.packageType == PackageType.annual || cleanTitle.toLowerCase().contains('annual');
        tiers.add(PaywallTier(
          identifier: package.identifier,
          title: cleanTitle,
          description: product.description,
          priceString: product.priceString,
          periodSuffix: isLifetime ? 'one-time' : (isAnnual ? '/year' : '/month'),
          badge: isLifetime ? 'BEST VALUE' : (isAnnual ? 'SAVE 50%' : ''),
          package: package,
        ));
      }
    } else {
      // Offline fallback / Mock tiers
      tiers.addAll([
        const PaywallTier(
          identifier: 'monthly',
          title: 'Monthly Subscription',
          description: 'Unlock unlimited reagent scans on a monthly basis.',
          priceString: '\$4.99',
          periodSuffix: '/month',
          badge: '',
        ),
        const PaywallTier(
          identifier: 'annual',
          title: 'Annual Subscription',
          description: 'Get unlimited reagent scans for a full year. Includes 3-day free trial.',
          priceString: '\$29.99',
          periodSuffix: '/year',
          badge: 'SAVE 50%',
        ),
        const PaywallTier(
          identifier: 'lifetime',
          title: 'Lifetime Access',
          description: 'One-time payment for perpetual unlimited reagent scans.',
          priceString: '\$59.99',
          periodSuffix: 'one-time',
          badge: 'BEST VALUE',
        ),
      ]);
    }

    // Auto-select preferred tier if none is selected
    if (_selectedTier == null && tiers.isNotEmpty) {
      _selectedTier = tiers.firstWhere(
        (t) => t.identifier == 'annual' || t.title.toLowerCase().contains('annual'),
        orElse: () => tiers.first,
      );
    }

    // Background gradient depending on dark/light theme
    final backgroundGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF0F1115), Color(0xFF161B22)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        HeroIcons.x_mark,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (offerings.isEmpty || kDebugMode)
                      TextButton.icon(
                        icon: const Icon(HeroIcons.cpu_chip, size: 16, color: Color(0xFF7C5CFF)),
                        label: Text(
                          isAr ? 'تخطي التطوير' : 'Dev Bypass',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () async {
                          await premiumService.simulatePremiumUnlock();
                        },
                      ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      // Animated Sparkle Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C5CFF), Color(0xFF50E3C2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C5CFF).withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          HeroIcons.sparkles,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Headlines
                      Text(
                        isAr ? 'الترقية إلى النسخة المدفوعة' : 'Upgrade to Premium',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr
                            ? 'افتح عمليات فحص الكواشف غير المحدودة، والتحليل الكيميائي الدقيق، والتوصيات العلمية المتقدمة لسلامة المختبرات.'
                            : 'Unlock unlimited reagent scans, precise chemical analysis, and advanced laboratory safety recommendations.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Feature List
                      _buildFeatureItem(
                        context,
                        icon: Icons.all_inclusive,
                        title: isAr ? 'عمليات فحص كواشف غير محدودة' : 'Unlimited Reagent Scans',
                        subtitle: isAr ? 'بدون حدود أو انقطاعات للفحوصات اليومية.' : 'No daily scan limits or interruptions.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        icon: HeroIcons.bolt,
                        title: isAr ? 'معالجة كيميائية فورية بالذكاء الاصطناعي' : 'Priority AI Chemical Processing',
                        subtitle: isAr ? 'نتائج فورية ودقيقة باستخدام تحليل الرؤية الحاسوبية.' : 'Instant, precise results using computer vision analysis.',
                      ),
                      _buildFeatureItem(
                        context,
                        icon: HeroIcons.shield_check,
                        title: isAr ? 'تقارير سلامة شاملة' : 'Comprehensive Safety Reports',
                        subtitle: isAr ? 'تحذيرات كاملة وبروتوكولات التعامل الآمن وطرق التخزين.' : 'Full chemical hazard warnings, handling info & lab protocols.',
                      ),
                      _buildFeatureItem(
                        context,
                        icon: HeroIcons.cloud_arrow_up,
                        title: isAr ? 'مزامنة سحابية آمنة' : 'Secure Cloud Sync',
                        subtitle: isAr ? 'تزامن سجل الفحوصات والإعدادات بين جميع أجهزتك.' : 'Sync scan history and configurations across all devices.',
                      ),

                      const SizedBox(height: 36),

                      // Subscriptions List
                      if (premiumService.isPurchasePending)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C5CFF)),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tiers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tier = tiers[index];
                            final isSelected = _selectedTier?.identifier == tier.identifier;
                            return _buildTierCard(context, tier, isSelected);
                          },
                        ),

                      const SizedBox(height: 24),

                      // Error message if any
                      if (premiumService.errorMessage != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF87171),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  HeroIcons.exclamation_triangle,
                                  color: Color(0xFFF87171),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    premiumService.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFF87171),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Action Button
                      if (tiers.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            if (_selectedTier != null) {
                              HapticFeedback.mediumImpact();
                              if (_selectedTier!.package != null) {
                                premiumService.buyPremium(_selectedTier!.package!);
                              } else {
                                premiumService.simulatePremiumUnlock();
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C5CFF), Color(0xFF6366F1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C5CFF).withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                isAr ? 'شراء وتفعيل الاشتراك' : 'Purchase Subscription',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Restore Purchases button
                      TextButton(
                        onPressed: premiumService.isPurchasePending
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                premiumService.restorePurchases();
                              },
                        child: Text(
                          isAr ? 'استعادة المشتريات السابقة' : 'Restore Purchases',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auto-renewal Terms info (Required by Apple guidelines)
                      if (_selectedTier != null && _selectedTier!.identifier != 'lifetime')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            isAr
                                ? 'يتم الدفع عبر حساب iTunes الخاص بك عند تأكيد الشراء. يتجدد الاشتراك تلقائيًا ما لم يتم إيقاف التجديد التلقائي قبل 24 ساعة على الأقل من نهاية الفترة الحالية. سيتم محاسبتك على التجديد في غضون 24 ساعة قبل نهاية الفترة الحالية بسعر الخطة المحددة. يمكنك إدارة الاشتراكات وإيقاف التجديد التلقائي من إعدادات حساب iTunes بعد الشراء.'
                                : 'Payment will be charged to your iTunes Account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. Account will be charged for renewal within 24 hours prior to the end of the current period. Subscriptions may be managed and auto-renewal may be turned off by going to your iTunes Account Settings after purchase.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white38 : Colors.black45,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),

                      // Compliance Links
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLink(isAr ? 'شروط الخدمة' : 'Terms of Service', 'https://colorstest.com/en/safety/'),
                          _buildLink(isAr ? 'سياسة الخصوصية' : 'Privacy Policy', 'https://colorstest.com/en/privacy/'),
                          _buildLink(isAr ? 'شروط استخدام أبل (EULA)' : 'Apple Terms (EULA)', 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Scientific Disclaimer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.02)
                              : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              HeroIcons.information_circle,
                              size: 20,
                              color: isDarkMode ? Colors.white38 : Colors.black45,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'تنبيه علمي: يمثل تحليل الذكاء الاصطناعي لكشف الألوان أداة تعليمية مساعدة. لا يغني عن الفحوصات المختبرية المعتمدة وبروتوكولات السلامة الكيميائية. تحقق من النتائج يدوياً دائماً.'
                                    : 'Scientific Disclaimer: Reagent ColorTest AI analysis is an educational aid. It does not replace certified laboratory testing or chemical safety protocols. Verify results manually.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode ? Colors.white38 : Colors.black45,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7C5CFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDarkMode ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, PaywallTier tier, bool isSelected) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTier = tier;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF1E222B) : Colors.white)
              : (isDarkMode ? const Color(0xFF161B22) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C5CFF)
                : (isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7C5CFF).withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (tier.badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C5CFF), Color(0xFF50E3C2)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tier.badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tier.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDarkMode ? Colors.white38 : Colors.black45,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tier.priceString,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  tier.periodSuffix,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLink(String text, String url) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Text(
        text,
        style: const TextStyle(
          decoration: TextDecoration.underline,
          fontSize: 12,
          color: Colors.blueGrey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
