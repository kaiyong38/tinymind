import 'package:flutter/material.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
}
