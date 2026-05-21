import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/core/theme/app_colors.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selectedPackage;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

    // Auto-select first package if none selected and offerings exist
    if (_selectedPackage == null && offerings.isNotEmpty) {
      _selectedPackage = offerings.first;
    }

    // Background gradient depending on dark/light theme
    final backgroundGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Navigation/Header
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
                        icon: const Icon(HeroIcons.cpu_chip, size: 16, color: AppColors.primaryAccent),
                        label: Text(
                          'Dev Bypass',
                          style: TextStyle(
                            color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
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
                            colors: [AppColors.primaryAccent, AppColors.tertiaryAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          HeroIcons.sparkles,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Headlines
                      Text(
                        'Upgrade to Premium',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock unlimited reagent scans, precise chemical analysis, and advanced laboratory safety recommendations.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Feature List
                      _buildFeatureItem(
                        context,
                        icon: Icons.all_inclusive,
                        title: 'Unlimited Reagent Scans',
                        subtitle: 'No scan limits or interruptions.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        icon: HeroIcons.bolt,
                        title: 'Priority AI Chemical Processing',
                        subtitle: 'Instant results using advanced vision analysis.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        icon: HeroIcons.shield_check,
                        title: 'Comprehensive Safety Reports',
                        subtitle: 'Full warnings, handling info & lab protocols.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        icon: HeroIcons.cloud_arrow_up,
                        title: 'Multi-Device Sync',
                        subtitle: 'Sync counts and results across all platforms.',
                      ),

                      const SizedBox(height: 36),

                      // Dynamic Offerings List
                      if (premiumService.isPurchasePending)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                            ),
                          ),
                        )
                      else if (offerings.isEmpty)
                        _buildEmptyOfferingsCard(context)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offerings.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final package = offerings[index];
                            final isSelected = _selectedPackage == package;
                            return _buildOfferingCard(context, package, isSelected);
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
                              color: isDarkMode
                                  ? AppColors.statusError.withOpacity(0.1)
                                  : AppColors.lightStatusError.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode ? AppColors.statusError : AppColors.lightStatusError,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  HeroIcons.exclamation_triangle,
                                  color: isDarkMode ? AppColors.statusError : AppColors.lightStatusError,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    premiumService.errorMessage!,
                                    style: TextStyle(
                                      color: isDarkMode ? AppColors.statusError : AppColors.lightStatusError,
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
                      if (offerings.isNotEmpty) ...[
                        GestureDetector(
                          onTap: () {
                            if (_selectedPackage != null) {
                              premiumService.buyPremium(_selectedPackage!);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAccent.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Continue to Payment',
                                style: TextStyle(
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
                            : () => premiumService.restorePurchases(),
                        child: Text(
                          'Restore Purchases',
                          style: TextStyle(
                            color: isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Compliance Links
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        children: [
                          _buildLink('Terms of Service', 'https://colorstest.com/en/safety/'),
                          _buildLink('Privacy Policy', 'https://colorstest.com/en/privacy/'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Medical / Scientific Disclaimer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.03)
                              : Colors.black.withOpacity(0.03),
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
                              color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Scientific Disclaimer: ReagentKit AI analysis is an educational aid. It does not replace certified laboratory testing or chemical safety protocols. Verify results manually.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? AppColors.primaryAccent : AppColors.lightPrimaryAccent,
            size: 22,
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfferingCard(BuildContext context, Package package, bool isSelected) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final product = package.storeProduct;

    // Standardize title representation
    final cleanTitle = product.title.split('(').first.trim();
    
    // Check type for badge overlay
    final isLifetime = package.packageType == PackageType.lifetime || cleanTitle.toLowerCase().contains('lifetime');
    final isAnnual = package.packageType == PackageType.annual || cleanTitle.toLowerCase().contains('annual');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? AppColors.surfaceElevated : Colors.white)
              : (isDarkMode ? AppColors.surfaceBase : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccent
                : (isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.12),
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
                        cleanTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (isLifetime || isAnnual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryAccent, AppColors.tertiaryAccent],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isLifetime ? 'BEST VALUE' : 'SAVE 50%',
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
                    product.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
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
                  product.priceString,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  isLifetime ? 'one-time' : (isAnnual ? '/year' : '/month'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOfferingsCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceBase : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? AppColors.borderSubtle : AppColors.lightBorderSubtle,
        ),
      ),
      child: Column(
        children: [
          Icon(
            HeroIcons.shopping_bag,
            size: 40,
            color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Store Unavailable Offline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Could not load offerings from App Store/Google Play. You can bypass using the simulation button for development.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              ref.read(premiumServiceProvider).simulatePremiumUnlock();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Simulate Purchase (Bypass)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
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
