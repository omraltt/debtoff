import 'package:flutter/material.dart';

Color getBankBrandColor(String bankName, [Color defaultColor = const Color(0xff3b82f6)]) {
  final name = bankName.toLowerCase();
  if (name.contains('akbank')) return const Color(0xffe11d48); // Rose/Red
  if (name.contains('garanti')) return const Color(0xff10b981); // Emerald Green
  if (name.contains('enpara')) return const Color(0xff8b5cf6); // Purple
  if (name.contains('qnb') || name.contains('finansbank')) return const Color(0xff06b6d4); // Cyan
  if (name.contains('yapı') || name.contains('yapi') || name.contains('ykb')) return const Color(0xff2563eb); // Blue
  if (name.contains('iş') || name.contains('is bank') || name.contains('isbank')) return const Color(0xff1d4ed8); // Dark Blue
  if (name.contains('vakıf') || name.contains('vakif')) return const Color(0xffd97706); // Gold/Amber
  if (name.contains('halk')) return const Color(0xff0284c7); // Light Blue
  if (name.contains('ziraat')) return const Color(0xffdc2626); // Crimson Red
  if (name.contains('deniz')) return const Color(0xff0f172a); // Slate Navy
  return defaultColor;
}
