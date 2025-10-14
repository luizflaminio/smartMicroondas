// lib/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';

class RecipeListScreen extends StatefulWidget {
  final Function(Recipe) onRecipeSelected;
  final bool isEnabled;

  const RecipeListScreen({
    Key? key,
    required this.onRecipeSelected,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  _RecipeListScreenState createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final List<Recipe> _recipes = DefaultRecipes.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Receitas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Selecione uma receita para iniciar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recipes.length,
            itemBuilder: (context, index) {
              final recipe = _recipes[index];
              return RecipeCard(
                recipe: recipe,
                isEnabled: widget.isEnabled,
                onStart: widget.isEnabled
                    ? () {
                        widget.onRecipeSelected(recipe);
                        _showRecipeStartedSnackBar(recipe);
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecipeStartedSnackBar(Recipe recipe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('${recipe.name} iniciado!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Tela completa de receitas (alternativa)
class RecipeListFullScreen extends StatelessWidget {
  final Function(Recipe) onRecipeSelected;

  const RecipeListFullScreen({
    Key? key,
    required this.onRecipeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipes = DefaultRecipes.all;

    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Receita'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeCard(
            recipe: recipe,
            onStart: () {
              onRecipeSelected(recipe);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}