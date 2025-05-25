import 'package:flutter/material.dart';

class SlotReel extends StatelessWidget {
  final String imageUrl; // URL изображения символа для отображения
  final double size; // Размер барабана/символа

  const SlotReel({
    Key? key,
    required this.imageUrl,
    this.size = 100.0, // Размер по умолчанию
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2.0), // Пример границы
        borderRadius: BorderRadius.circular(8.0), // Пример закругления углов
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.0), // Закругление углов изображения
        child: imageUrl.startsWith('assets/') // Проверяем, является ли imageUrl путем к изображению
            ? Image.asset(
                imageUrl,
                fit: BoxFit.cover, // Растягиваем изображение на весь контейнер
                errorBuilder: (context, error, stackTrace) {
                  // Обработка ошибок загрузки изображения
                  return Center(child: Icon(Icons.error));
                },
              )
            : Center(
                child: Text(
                  imageUrl, // Отображаем эмодзи
                  style: TextStyle(fontSize: size * 0.6), // Размер эмодзи
                ),
              ),
      ),
    );
  }
} 