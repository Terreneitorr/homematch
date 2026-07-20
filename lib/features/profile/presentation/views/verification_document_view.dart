import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/upload_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class VerificationDocumentView extends StatefulWidget {
  const VerificationDocumentView({super.key});

  @override
  State<VerificationDocumentView> createState() => _VerificationDocumentViewState();
}

class _VerificationDocumentViewState extends State<VerificationDocumentView> {
  File? _pickedFile;
  bool _uploading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _pickedFile = File(picked.path);
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_pickedFile == null) return;
    setState(() { _uploading = true; _error = null; });

    try {
      final uploadService = UploadService();
      final url = await uploadService.uploadImage(_pickedFile!);
      if (url == null) {
        throw Exception('No se pudo subir el documento, intenta de nuevo');
      }

      await DioClient().dio.post(
        '/users/me/verification-document',
        data: {'document_url': url},
      );

      if (mounted) {
        await context.read<AuthViewModel>().refreshUser();
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Documento enviado'),
            content: const Text(
              'Tu documento quedó en revisión. Te notificaremos cuando el '
                  'equipo de HomeMatch confirme tu verificación.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authVM = context.watch<AuthViewModel>();
    final status = authVM.user?.verificationStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text('Verificar inmobiliaria', style: theme.textTheme.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (status == 'pending')
              _StatusBanner(
                theme: theme,
                icon: Icons.hourglass_top,
                color: theme.colorScheme.tertiary,
                text: 'Tu documento está en revisión.',
              )
            else if (status == 'approved')
              _StatusBanner(
                theme: theme,
                icon: Icons.verified,
                color: theme.colorScheme.secondary,
                text: 'Tu cuenta ya está verificada.',
              )
            else if (status == 'rejected')
                _StatusBanner(
                  theme: theme,
                  icon: Icons.error_outline,
                  color: theme.colorScheme.error,
                  text: 'Tu documento fue rechazado. Sube uno nuevo.',
                ),
            const SizedBox(height: 16),
            Text(
              'Sube una foto legible de tu RFC o cédula que acredite tu '
                  'inmobiliaria. El equipo de HomeMatch la revisará.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _uploading ? null : _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_pickedFile!, fit: BoxFit.cover,
                      width: double.infinity),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file,
                        size: 40, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text('Toca para elegir una foto',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_pickedFile == null || _uploading) ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: _uploading
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar para revisión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final Color color;
  final String text;

  const _StatusBanner({
    required this.theme, required this.icon,
    required this.color, required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color))),
      ]),
    );
  }
}