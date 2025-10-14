// lib/models/recipe.dart
import 'package:flutter/material.dart';

class Recipe {
  final String id;
  final String name;
  final int timeInSeconds;
  final int power; // 0-100%
  final String description;
  final IconData icon;
  final Color? color;

  Recipe({
    required this.id,
    required this.name,
    required this.timeInSeconds,
    required this.power,
    required this.description,
    required this.icon,
    this.color,
  });

  Recipe copyWith({
    String? id,
    String? name,
    int? timeInSeconds,
    int? power,
    String? description,
    IconData? icon,
    Color? color,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      timeInSeconds: timeInSeconds ?? this.timeInSeconds,
      power: power ?? this.power,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timeInSeconds': timeInSeconds,
      'power': power,
      'description': description,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      timeInSeconds: json['timeInSeconds'],
      power: json['power'],
      description: json['description'],
      icon: Icons.microwave,
    );
  }

  @override
  String toString() {
    return 'Recipe(name: $name, time: $timeInSeconds, power: $power)';
  }
}

class DefaultRecipes {
  static final List<Recipe> all = [
    Recipe(
      id: 'pipoca',
      name: 'Pipoca',
      timeInSeconds: 180,
      power: 80,
      description: 'Pipoca crocante em 3 minutos',
      icon: Icons.grain,
      color: Colors.amber,
    ),
    Recipe(
      id: 'aquecimento_rapido',
      name: 'Aquecimento Rápido',
      timeInSeconds: 60,
      power: 100,
      description: 'Aquecer comida rapidamente',
      icon: Icons.local_fire_department,
      color: Colors.red,
    ),
    Recipe(
      id: 'descongelar',
      name: 'Descongelar',
      timeInSeconds: 300,
      power: 30,
      description: 'Descongelamento suave',
      icon: Icons.ac_unit,
      color: Colors.blue,
    ),
    Recipe(
      id: 'pizza',
      name: 'Pizza',
      timeInSeconds: 120,
      power: 70,
      description: 'Reaquecimento de pizza',
      icon: Icons.local_pizza,
      color: Colors.orange,
    ),
    Recipe(
      id: 'bebida_quente',
      name: 'Bebida Quente',
      timeInSeconds: 90,
      power: 90,
      description: 'Aquecer bebidas',
      icon: Icons.local_cafe,
      color: Colors.brown,
    ),
  ];

  static Recipe? findById(String id) {
    try {
      return all.firstWhere((recipe) => recipe.id == id);
    } catch (e) {
      return null;
    }
  }
}