import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../reagent_testing/presentation/providers/reagent_testing_providers.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final premiumService = ref.watch(premiumServiceProvider);

    // Auto-dismiss if purchased
    if (premiumService.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(HeroIcons.x_mark, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.indigo.shade500],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(HeroIcons.sparkles, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 32),
              
              // Titles
              Text(
                'Unlock Unlimited\nAI Analysis',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Get unlimited medical AI image analysis with lifetime access.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              
              // Features List
              _buildFeatureRow(context, 'Unlimited scans'),
              const SizedBox(height: 12),
              _buildFeatureRow(context, 'Faster AI analysis'),
              const SizedBox(height: 12),
              _buildFeatureRow(context, 'Future updates included'),
              const SizedBox(height: 12),
              _buildFeatureRow(context, 'No subscriptions'),
              
              const SizedBox(height: 40),
              
              // Purchase Button
              premiumService.errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      premiumService.errorMessage!,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
                
              premiumService.isPurchasePending
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () => premiumService.buyPremium(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Unlock Now - $4.99 One-Time',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
              const SizedBox(height: 16),
              
              // Restore Purchases
              TextButton(
                onPressed: premiumService.isPurchasePending ? null : () => premiumService.restorePurchases(),
                child: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Store Compliance Links
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  _buildLink('Privacy Policy', 'https://colorstest.com/en/privacy/'),
                  _buildLink('Safety Info', 'https://colorstest.com/en/safety/'),
                  _buildLink('Help Center', 'https://colorstest.com/en/help/'),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Medical Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(HeroIcons.information_circle, size: 16, color: isDarkMode ? Colors.white54 : Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disclaimer: This app does not provide medical diagnosis. Always consult a healthcare professional.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(HeroIcons.check_circle, color: Colors.green.shade400, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
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
        ),
      ),
    );
  }
}
