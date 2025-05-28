class SlotSymbol {
  final String imagePath;
  final String name;
  final int value;
  final int? specialMultiplier; // Специальный множитель для определенных комбинаций

  const SlotSymbol({
    required this.imagePath,
    required this.name,
    required this.value,
    this.specialMultiplier,
  });
}

class SlotSymbols {
  static const List<SlotSymbol> classic = [
    SlotSymbol(
      imagePath: 'assets/images/classic/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 2, // x2 за три семерки
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 3, // x3 за три изумруда
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2, // x2 за три рубина
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/banana.png',
      name: 'banana',
      value: 5,
    ),
  ];

  static const List<SlotSymbol> minecraft = [
    SlotSymbol(
      imagePath: 'assets/images/minecraft/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 2, // x2 за три семерки
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 3, // x3 за три изумруда
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2, // x2 за три рубина
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/apple.png',
      name: 'apple',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/strawberry.png',
      name: 'strawberry',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/coconut.png',
      name: 'coconut',
      value: 85,
    ),
  ];
} 