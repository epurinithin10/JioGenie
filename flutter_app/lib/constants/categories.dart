import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String label;
  final IconData icon;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class CategoryPrompt {
  final String title;
  final String subtitle;
  final String prompt;
  final IconData icon;

  const CategoryPrompt({
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.icon,
  });
}

class Categories {
  static const List<CategoryItem> items = [
    CategoryItem(id: 'all', label: 'All Services', icon: Icons.layers_outlined),
    CategoryItem(id: 'mobile', label: 'Mobile Plans', icon: Icons.phone_android_outlined),
    CategoryItem(id: '5g', label: 'True 5G', icon: Icons.wifi_outlined),
    CategoryItem(id: 'fiber', label: 'JioFiber', icon: Icons.router_outlined),
    CategoryItem(id: 'airfiber', label: 'JioAirFiber', icon: Icons.cell_tower_outlined),
    CategoryItem(id: 'support', label: 'eSIM & Support', icon: Icons.help_outline),
  ];

  static const Map<String, List<CategoryPrompt>> prompts = {
    'all': [
      CategoryPrompt(
        title: 'Best 84-Day 5G Plans',
        subtitle: 'Compare ₹859, ₹1029, ₹1199 tariffs',
        prompt: 'What is the best 84-day Jio plan with Unlimited 5G?',
        icon: Icons.wifi_outlined,
      ),
      CategoryPrompt(
        title: 'Activate Jio eSIM',
        subtitle: 'Step-by-step EID / IMEI guide',
        prompt: 'How do I convert my physical SIM to Jio eSIM on iPhone and Android?',
        icon: Icons.sim_card_outlined,
      ),
      CategoryPrompt(
        title: 'JioFiber vs AirFiber',
        subtitle: 'Wireline vs 5G FWA comparison',
        prompt: 'Compare JioFiber vs JioAirFiber: speeds, prices, and installation.',
        icon: Icons.compare_arrows_outlined,
      ),
      CategoryPrompt(
        title: 'International Roaming',
        subtitle: 'In-flight and country travel packs',
        prompt: 'What are the best International Roaming packs for USA and UAE?',
        icon: Icons.flight_takeoff_outlined,
      ),
    ],
    'mobile': [
      CategoryPrompt(
        title: 'Popular 28-Day Plans',
        subtitle: '₹349 2GB/day + Unlimited 5G details',
        prompt: 'Explain the best 28-day Jio prepaid plans with True 5G.',
        icon: Icons.phone_android_outlined,
      ),
      CategoryPrompt(
        title: '365-Day Annual Plans',
        subtitle: '₹3599 Flagship 2.5GB/day plan',
        prompt: 'What are the details of the Jio ₹3599 1-year annual plan?',
        icon: Icons.calendar_today_outlined,
      ),
      CategoryPrompt(
        title: 'True 5G Upgrade Vouchers',
        subtitle: '₹51, ₹101, ₹151 booster packs',
        prompt: 'How do the ₹51 and ₹101 True 5G Upgrade vouchers work?',
        icon: Icons.bolt_outlined,
      ),
      CategoryPrompt(
        title: 'Postpaid Plus Family',
        subtitle: '₹699 plan with 3 add-on SIM cards',
        prompt: 'Explain Jio Postpaid Plus ₹699 and ₹999 family plans.',
        icon: Icons.people_outline,
      ),
    ],
    '5g': [
      CategoryPrompt(
        title: 'True 5G Welcome Offer',
        subtitle: 'Eligibility & activation rules',
        prompt: 'What are the eligibility criteria for Jio True 5G Welcome Offer?',
        icon: Icons.wifi_outlined,
      ),
      CategoryPrompt(
        title: '5G Spectrum & SA Network',
        subtitle: '700MHz, 3300MHz, 26GHz details',
        prompt: 'Explain Jio True 5G Standalone network and frequency bands.',
        icon: Icons.memory_outlined,
      ),
      CategoryPrompt(
        title: 'iPhone 5G Settings',
        subtitle: 'Enable Standalone 5G in iOS',
        prompt: 'How do I enable Jio True 5G on Apple iPhone 12 to 16?',
        icon: Icons.settings_phone_outlined,
      ),
      CategoryPrompt(
        title: 'What is VoNR?',
        subtitle: 'Native Voice over 5G technology',
        prompt: 'What is VoNR (Voice over New Radio) in Jio True 5G?',
        icon: Icons.ring_volume_outlined,
      ),
    ],
    'fiber': [
      CategoryPrompt(
        title: 'JioFiber ₹999 Plan',
        subtitle: '150 Mbps + 14 OTTs + 4K STB',
        prompt: 'What are the benefits of the JioFiber ₹999 plan?',
        icon: Icons.tv_outlined,
      ),
      CategoryPrompt(
        title: 'JioFiber Speeds & Tiers',
        subtitle: '30 Mbps up to 1 Gbps options',
        prompt: 'List all JioFiber broadband speed tiers and monthly costs.',
        icon: Icons.speed_outlined,
      ),
      CategoryPrompt(
        title: 'Free 4K Set Top Box',
        subtitle: 'Voice remote & JioTV+ live channels',
        prompt: 'How does the JioFiber 4K Set Top Box work and what OTT apps are included?',
        icon: Icons.desktop_windows_outlined,
      ),
      CategoryPrompt(
        title: 'Installation & Router',
        subtitle: 'Zero installation booking terms',
        prompt: 'How can I get free installation and dual-band router for JioFiber?',
        icon: Icons.build_outlined,
      ),
    ],
    'airfiber': [
      CategoryPrompt(
        title: 'JioAirFiber ₹599 Plan',
        subtitle: '30 Mbps wireless home broadband',
        prompt: 'What is included in the JioAirFiber ₹599 monthly plan?',
        icon: Icons.cell_tower_outlined,
      ),
      CategoryPrompt(
        title: 'JioAirFiber ₹899 Plan',
        subtitle: '100 Mbps best-seller with OTTs',
        prompt: 'Tell me about the JioAirFiber ₹899 plan and OTT subscriptions.',
        icon: Icons.star_outline,
      ),
      CategoryPrompt(
        title: 'AirFiber Technology',
        subtitle: 'Fixed Wireless Access over 5G',
        prompt: 'How does JioAirFiber work without physical roadside cables?',
        icon: Icons.sensors_outlined,
      ),
      CategoryPrompt(
        title: 'AirFiber Max Speeds',
        subtitle: '300 Mbps to 1000 Mbps gigabit',
        prompt: 'What are the JioAirFiber Max high-speed plans?',
        icon: Icons.bolt_outlined,
      ),
    ],
    'support': [
      CategoryPrompt(
        title: 'Official APN Settings',
        subtitle: 'jionet configuration for 4G/5G',
        prompt: 'What are the official Jio APN internet settings for Android and iOS?',
        icon: Icons.settings_suggest_outlined,
      ),
      CategoryPrompt(
        title: 'Port to Jio (MNP)',
        subtitle: 'PORT SMS to 1900 & UPC code',
        prompt: 'What is the step-by-step process to port my number to Jio?',
        icon: Icons.swap_horiz_outlined,
      ),
      CategoryPrompt(
        title: 'Customer Helplines',
        subtitle: '198, 199 & WhatsApp 70007 70007',
        prompt: 'List all official Jio customer care numbers and WhatsApp support.',
        icon: Icons.phone_in_talk_outlined,
      ),
      CategoryPrompt(
        title: 'JioBharat ₹123 Plan',
        subtitle: '₹999 4G phone with UPI payments',
        prompt: 'What is the JioBharat phone and what are the benefits of the ₹123 plan?',
        icon: Icons.smartphone_outlined,
      ),
    ],
  };
}
