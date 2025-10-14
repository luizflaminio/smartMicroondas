// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../utils/formatters.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onStart;
  final bool isEnabled;

  const RecipeCard({
    Key? key,
    required this.recipe,
    this.onStart,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isEnabled ? onStart : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(),
              SizedBox(width: 16),
              Expanded(
                child: _buildContent(),
              ),
              if (onStart != null) _buildStartButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: (recipe.color ?? Colors.blue).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        recipe.icon,
        color: recipe.color ?? Colors.blue,
        size: 28,
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          recipe.description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              TimeFormatter.formatTimeReadable(recipe.timeInSeconds),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(width: 16),
            Icon(Icons.power, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              PowerFormatter.format(recipe.power),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: isEnabled ? onStart : null,
      child: Text('Iniciar'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(80, 40),
      ),
    );
  }
}

// Variante compacta para lista
class RecipeCardCompact extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final bool isSelected;

  const RecipeCardCompact({
    Key? key,
    required this.recipe,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (recipe.color ?? Colors.blue).withOpacity(0.2),
          child: Icon(recipe.icon, color: recipe.color ?? Colors.blue),
        ),
        title: Text(
          recipe.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 14),
            SizedBox(width: 4),
            Text(TimeFormatter.formatTimeReadable(recipe.timeInSeconds)),
            SizedBox(width: 12),
            Icon(Icons.power, size: 14),
            SizedBox(width: 4),
            Text(PowerFormatter.format(recipe.power)),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue)
            : Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}