import 'package:flutter/material.dart';

import '../app/theme/theme.dart';

class JobIconData {
  const JobIconData(this.icon, this.color);
  final IconData icon;
  final Color color;
}

JobIconData getJobIcon(String title, BuildContext context) {
  final c = context.jm;
  final t = title.toLowerCase();

  // Helper to check keywords
  bool has(List<String> keywords) {
    return keywords.any((k) => t.contains(k));
  }

  // 1. Engineering / IT
  if (has(['developer', 'engineer', 'programmer', 'ios', 'android', 'fullstack', 'frontend', 'backend', 'software', 'devops', 'tech lead'])) {
    return JobIconData(Icons.code_rounded, c.ocean);
  }
  // 2. Data / AI
  if (has(['data', 'analyst', 'scientist', 'machine learning', 'ai', 'analytics', 'statistic'])) {
    return JobIconData(Icons.insights_rounded, c.match);
  }
  // 3. Design / UI/UX
  if (has(['design', 'artist', 'creative', 'ui', 'ux', 'animator', 'illustrator', 'art director'])) {
    return JobIconData(Icons.design_services_rounded, const Color(0xFFE91E63)); // Pinkish
  }
  // 4. Product / Project Management
  if (has(['product manager', 'scrum', 'agile', 'project manager', 'program manager'])) {
    return JobIconData(Icons.view_kanban_rounded, const Color(0xFFFF9800)); // Orange
  }
  // 5. Marketing / Growth
  if (has(['marketing', 'seo', 'content', 'social media', 'growth', 'brand', 'copywriter'])) {
    return JobIconData(Icons.campaign_rounded, const Color(0xFF9C27B0)); // Purple
  }
  // 6. Sales / Business Development
  if (has(['sales', 'account executive', 'business development', 'bdr', 'sdr', 'account manager'])) {
    return JobIconData(Icons.handshake_rounded, const Color(0xFF4CAF50)); // Green
  }
  // 7. Customer Support
  if (has(['support', 'customer success', 'service', 'helpdesk'])) {
    return JobIconData(Icons.support_agent_rounded, const Color(0xFF00BCD4)); // Cyan
  }
  // 8. HR / Recruiting
  if (has(['hr ', 'human resources', 'talent', 'recruiter', 'people', 'hiring'])) {
    return JobIconData(Icons.people_alt_rounded, const Color(0xFFFF5722)); // Deep Orange
  }
  // 9. Finance / Accounting
  if (has(['finance', 'accountant', 'bookkeeper', 'tax', 'audit', 'accounting', 'payroll'])) {
    return JobIconData(Icons.account_balance_rounded, const Color(0xFF3F51B5)); // Indigo
  }
  // 10. Legal / Law Firm
  if (has(['law', 'legal', 'attorney', 'paralegal', 'counsel', 'lawyer'])) {
    return JobIconData(Icons.gavel_rounded, const Color(0xFF795548)); // Brown
  }
  // 11. Healthcare / Medical
  if (has(['nurse', 'doctor', 'medical', 'health', 'clinic', 'therapist', 'caregiver', 'dental', 'pharm'])) {
    return JobIconData(Icons.medical_services_rounded, const Color(0xFFF44336)); // Red
  }
  // 12. Education / Teaching
  if (has(['teacher', 'tutor', 'professor', 'instructor', 'education', 'school'])) {
    return JobIconData(Icons.school_rounded, const Color(0xFFFFC107)); // Amber
  }
  // 13. Hospitality / Food & Beverage
  if (has(['bartender', 'barista', 'waiter', 'server', 'host'])) {
    return JobIconData(Icons.local_bar_rounded, const Color(0xFF8D6E63)); // Light Brown
  }
  if (has(['chef', 'cook', 'culinary', 'kitchen', 'restaurant'])) {
    return JobIconData(Icons.restaurant_rounded, const Color(0xFFD84315)); // Burnt Orange
  }
  // 14. Logistics / Warehouse / Driving
  if (has(['driver', 'delivery', 'warehouse', 'logistics', 'shipping', 'inventory'])) {
    return JobIconData(Icons.local_shipping_rounded, const Color(0xFF607D8B)); // Blue Grey
  }
  // 15. Retail / Store
  if (has(['retail', 'store', 'shop', 'merchandiser', 'cashier'])) {
    return JobIconData(Icons.storefront_rounded, const Color(0xFF009688)); // Teal
  }
  // 16. Office / Admin / General Management
  if (has(['admin', 'office', 'receptionist', 'clerk', 'assistant'])) {
    return JobIconData(Icons.desk_rounded, const Color(0xFF9E9E9E)); // Grey
  }
  if (has(['manager', 'director', 'vp', 'president', 'executive', 'chief'])) {
    return JobIconData(Icons.business_center_rounded, const Color(0xFF1565C0)); // Deep Blue
  }
  
  // Default fallback
  return JobIconData(Icons.work_outline_rounded, c.faint);
}
