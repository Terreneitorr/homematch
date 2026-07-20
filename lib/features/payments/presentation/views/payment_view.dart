import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class PaymentView extends StatefulWidget {
  const PaymentView({super.key});

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

      // El webhook de Stripe confirma el pago y activa la suscripción en el
      // backend de forma asíncrona (puede tardar uno o dos segundos). Damos
      // un pequeño margen antes de refrescar al usuario para darle tiempo.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await context.read<AuthViewModel>().refreshUser();
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(children: [
              Icon(Icons.check_circle, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              const Text('¡Pago exitoso!'),
            ]),
            content: const Text('Tu suscripción ha sido activada.'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
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
          // Planes
          ..._plans.map((plan) {
            final isSelected = _selectedPlan == plan['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 2 : 1,
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
        ],
      ),
    );
  }
}