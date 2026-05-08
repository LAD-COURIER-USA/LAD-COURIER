import 'package:flutter/material.dart';

// Este es un widget de UI simple y reutilizable.
// Su única misión es mostrar un círculo de color que representa
// el estado de disponibilidad de un mensajero.
// Verde para 'disponible', Gris para 'no disponible', consistente con
// la retroalimentación visual en otras partes de la app.
class MessengerStatusIndicator extends StatelessWidget {
  final bool isAvailable;

  const MessengerStatusIndicator({
    super.key,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade400 : Colors.grey.shade400,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
    );
  }
}
