import 'package:flutter/material.dart';

ThemeData meadowMilesTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color.fromARGB(255, 92, 92, 92),
      primary: Color.fromARGB(255, 92, 92, 92),
      secondary: Color.fromARGB(255, 49, 49, 49),
    ),
    useMaterial3: true,
    fontFamily: 'Copperplate Gothic',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 18,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.normal,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.normal,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Copperplate Gothic',
      ),
    ),
  );
}
