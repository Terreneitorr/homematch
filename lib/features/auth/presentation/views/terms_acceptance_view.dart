import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class TermsAcceptanceView extends StatefulWidget {
  const TermsAcceptanceView({super.key});

  @override
  State<TermsAcceptanceView> createState() => _TermsAcceptanceViewState();
}

class _TermsAcceptanceViewState extends State<TermsAcceptanceView> {
  bool _accepted = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVM = context.read<AuthViewModel>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.gavel_rounded, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Términos y Condiciones',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      'Bienvenido a HomeMatch AI.\n\n'
                      'Al utilizar nuestra plataforma, aceptas que tratemos tus datos con el fin de ofrecerte las mejores recomendaciones inmobiliarias.\n\n'
                      '1. Uso de la cuenta: Eres responsable de mantener la seguridad de tu cuenta.\n'
                      '2. Privacidad: No compartiremos tus datos personales con terceros sin tu consentimiento explícito.\n'
                      '3. Contenido: Te comprometes a no publicar información falsa o engañosa.\n'
                      '4. Citas: El agendamiento de citas es un compromiso entre particulares.\n\n'
                      'Puedes consultar nuestra política de privacidad completa en cualquier momento desde tu perfil.',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                title: const Text('He leído y acepto los términos y condiciones de uso.'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: !_accepted || _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          try {
                            await authVM.acceptTerms();
                          } catch (_) {
                            setState(() => _loading = false);
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Comenzar a usar HomeMatch'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => authVM.logout(),
                  child: const Text('Cancelar y salir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
