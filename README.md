# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Calculadora Pro - Flutter

Esta es una calculadora avanzada desarrollada en Flutter, con soporte para tema claro/oscuro, animaciones modernas y una interfaz adaptativa.

## Tecnologías y librerías utilizadas

- **Flutter**: Framework principal para desarrollo multiplataforma.
- **Material Design 3**: Uso de `ThemeData` con `useMaterial3: true` para estilos modernos.
- **Animaciones**: Uso de `AnimationController`, `Tween`, `AnimatedBuilder`, `AnimatedContainer`, `AnimatedDefaultTextStyle`, `FadeTransition`, `SlideTransition` para transiciones suaves en la UI.
- **Haptic Feedback**: Uso de `flutter/services.dart` para retroalimentación táctil en botones.
- **SafeArea y LayoutBuilder**: Para adaptar la interfaz a diferentes tamaños de pantalla.
- **ColorScheme.fromSeed**: Para generar esquemas de color consistentes y vibrantes.

## Imports principales

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
```

## Características

- Operaciones básicas: suma, resta, multiplicación, división, porcentaje y cambio de signo.
- Animaciones en la pantalla y los botones.
- Tema claro/oscuro con botón de alternancia.
- Interfaz responsiva y adaptativa.
- Retroalimentación háptica en cada interacción.

## Estructura principal

- `main.dart`: Contiene toda la lógica de la calculadora y la interfaz.
- Componentes personalizados para el teclado y los botones.
- Uso extensivo de widgets de Flutter para una experiencia moderna.

## Requisitos

- Flutter SDK 3.x o superior.

## Ejecución

```bash
flutter run
```

---
