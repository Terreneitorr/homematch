import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'usb_debug_detector.dart';

class SecurityCheckWrapper extends StatefulWidget {
  final Widget child;
  const SecurityCheckWrapper({super.key, required this.child});

  @override
  State<SecurityCheckWrapper> createState() => _SecurityCheckWrapperState();
}

class _SecurityCheckWrapperState extends State<SecurityCheckWrapper> {
  bool _checked = false;
  bool _blocked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    // Chequeo periódico cada 3 segundos para mayor reactividad
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _check();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final adbEnabled = await UsbDebugDetector.isUsbDebuggingEnabled();
    
    if (mounted && (_blocked != adbEnabled || !_checked)) {
      setState(() {
        _blocked = adbEnabled;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_blocked) {
      return _buildBlockedScreen();
    }

    return widget.child;
  }

  Widget _buildBlockedScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_update_warning,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Entorno Inseguro Detectado',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'La depuración USB está habilitada. Por seguridad, HomeMatch AI no puede ejecutarse en este estado.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '¿Cómo desbloquear?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ve a Ajustes → Opciones de desarrollador y desactiva "Depuración USB".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 16),
              Text(
                'Esperando a que desactives el USB...',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
