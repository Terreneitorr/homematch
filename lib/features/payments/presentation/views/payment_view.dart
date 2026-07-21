import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/security/inactivity_manager.dart';

class PaymentView extends StatefulWidget {
  final String? preSelectedPlan;
  const PaymentView({super.key, this.preSelectedPlan});

  @override
  State<PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<PaymentView> {
  List<dynamic> _plans = [];
  bool _loading = true;
  bool _paying = false;
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final res = await DioClient().dio.get('/payments/plans');
      setState(() {
        _plans = res.data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pay(String planId) async {
    setState(() { _paying = true; _selectedPlan = planId; });
    final theme = Theme.of(context);

    // El PaymentSheet de Stripe es una UI nativa (no widgets de Flutter), así
    // que el InactivityDetector no puede detectar los toques del usuario ahí
    // dentro. Pausamos el timer aquí para no cerrarle la sesión a medio pago.
    final inactivityManager = context.read<InactivityManager>();
    inactivityManager.stopTimer();

    try {
      final res = await DioClient().dio.post(
        '/payments/create-subscription',
        data: {'plan': planId},
      );
      final clientSecret = res.data['client_secret'] as String;
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'HomeMatch AI',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // El webhook de Stripe confirma el pago de forma asíncrona — puede
      // tardar más de un par de segundos (sobre todo en el plan gratuito de
      // Railway). En vez de refrescar una sola vez, reintentamos varias
      // veces hasta que el rol del usuario realmente cambie, o hasta
      // agotar los intentos.
      final expectedRole = planId == 'agency' ? 'AGENCY' : 'SELLER';
      bool confirmed = false;
      for (int attempt = 0; attempt < 6; attempt++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        await context.read<AuthViewModel>().refreshUser();
        if (!mounted) break;
        final currentRole = context.read<AuthViewModel>().user?.role;
        if (currentRole == expectedRole) {
          confirmed = true;
          break;
        }
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Row(children: [
              Icon(
                confirmed ? Icons.check_circle : Icons.hourglass_top,
                color: confirmed
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Text(confirmed ? '¡Pago exitoso!' : 'Pago recibido'),
            ]),
            content: Text(
              confirmed
                  ? 'Tu suscripción ha sido activada. Por seguridad, vuelve '
                  'a iniciar sesión para continuar con tu cuenta actualizada.'
                  : 'Tu pago se procesó correctamente. Vuelve a iniciar '
                  'sesión en unos momentos para ver tu cuenta actualizada.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (mounted) {
          await context.read<AuthViewModel>().logout();
        }
      }
    } on StripeException catch (e) {
      if (e.error.code != FailureCode.Canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.error.localizedMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      // Se reactiva el timer de inactividad sin importar si el pago fue
      // exitoso, falló, o el usuario canceló el PaymentSheet.
      inactivityManager.resetTimer();
      if (mounted) {
        setState(() { _paying = false; _selectedPlan = null; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Suscripción Premium', style: theme.textTheme.titleLarge),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header premium
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primaryContainer,
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Icon(Icons.workspace_premium, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              Text('HomeMatch AI Premium',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Desbloquea todas las funciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85))),
            ]),
          ),
          const SizedBox(height: 24),
          if (widget.preSelectedPlan != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.info_outline,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.preSelectedPlan == 'agency'
                        ? 'Para publicar como Inmobiliaria, primero activa esta suscripción.'
                        : 'Para publicar como Vendedor, primero activa esta suscripción.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer),
                  ),
                ),
              ]),
            ),
          // Planes
          ..._plans.map((plan) {
            final isSelected = _selectedPlan == plan['id'];
            final isRequired = widget.preSelectedPlan == plan['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected || isRequired
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected || isRequired ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(plan['name'],
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600))),
                    Text('\$${plan['price']} ${plan['currency']}',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20, fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                  ]),
                  if (isRequired) ...[
                    const SizedBox(height: 4),
                    Text('Requerido para tu tipo de cuenta',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 4),
                  Text(plan['description'],
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _paying ? null : () => _pay(plan['id']),
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      child: (_paying && isSelected)
                          ? SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: theme.colorScheme.onPrimary))
                          : const Text('Suscribirse'),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Center(child: Text(
            'Pagos procesados de forma segura por Stripe.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline),
          )),
          if (widget.preSelectedPlan != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _paying
                    ? null
                    : () => context.read<AuthViewModel>().clearPendingUpgradeRole(),
                child: const Text('Continuar como comprador (gratis)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}