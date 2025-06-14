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
      specialMultiplier: 3, // x3 за три семерки
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4, // x4 за три изумруда
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
    SlotSymbol(
      imagePath: 'assets/images/classic/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/classic/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> minecraft = [
    SlotSymbol(
      imagePath: 'assets/images/minecraft/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3, // x3 за три семерки
    ),
    SlotSymbol(
      imagePath: 'assets/images/minecraft/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4, // x4 за три изумруда
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

  static const List<SlotSymbol> fantasyGacha = [
    SlotSymbol(
      imagePath: 'assets/images/fantasy/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/fantasy/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> dresnya = [
    SlotSymbol(
      imagePath: 'assets/images/dresnya/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/dresnya/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> tokyopuk = [
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/tokyopuk/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> lego = [
    SlotSymbol(
      imagePath: 'assets/images/lego/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/lego/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> doka3 = [
    SlotSymbol(
      imagePath: 'assets/images/doka3/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/doka3/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> yamete = [
    SlotSymbol(
      imagePath: 'assets/images/japan/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/japan/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];

  static const List<SlotSymbol> hellokitty = [
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/7.png',
      name: 'seven',
      value: 100,
      specialMultiplier: 3,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/emerald.png',
      name: 'emerald',
      value: 80,
      specialMultiplier: 4,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/rubin.png',
      name: 'rubin',
      value: 60,
      specialMultiplier: 2,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/bonus.png',
      name: 'bonus',
      value: 50,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/clover.png',
      name: 'clover',
      value: 40,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/watermelon.png',
      name: 'watermelon',
      value: 30,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/plome.png',
      name: 'plome',
      value: 25,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/cherry.png',
      name: 'cherry',
      value: 20,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/lemon.png',
      name: 'lemon',
      value: 15,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/grape.png',
      name: 'grape',
      value: 10,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/banana.png',
      name: 'banana',
      value: 5,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/coconut.png',
      name: 'coconut',
      value: 35,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/apple.png',
      name: 'apple',
      value: 45,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/blueberry.png',
      name: 'blueberry',
      value: 55,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/lime.png',
      name: 'lime',
      value: 65,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/pear.png',
      name: 'pear',
      value: 75,
    ),
    SlotSymbol(
      imagePath: 'assets/images/hellokitty/strawberry.png',
      name: 'strawberry',
      value: 85,
    ),
  ];
} 