import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Política de privacidad',
            style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Política de Privacidad',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Última actualización: Julio 2026',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            theme: theme,
            title: '1. Información que Recopilamos',
            content:
            'Cuando utilizas HomeMatch AI, recopilamos la siguiente información:\n\n• Información de cuenta de Google: nombre, correo electrónico y foto de perfil\n• Historial de búsquedas dentro de la aplicación\n• Propiedades guardadas como favoritas\n• Citas agendadas\n• Propiedades publicadas (si eres vendedor o inmobiliaria)\n• Datos de uso de la aplicación para mejorar nuestros servicios',
          ),
          _Section(
            theme: theme,
            title: '2. Cómo Usamos tu Información',
            content:
            'Utilizamos la información recopilada para:\n\n• Proporcionar y mejorar nuestros servicios\n• Generar recomendaciones personalizadas con IA\n• Facilitar la comunicación entre compradores y vendedores\n• Enviar notificaciones relevantes sobre propiedades y citas\n• Analizar el uso de la plataforma para mejoras\n• Prevenir fraudes y garantizar la seguridad',
          ),
          _Section(
            theme: theme,
            title: '3. Compartir tu Información',
            content:
            'No vendemos tu información personal a terceros. Podemos compartir información en los siguientes casos:\n\n• Con otros usuarios de la plataforma cuando sea necesario para las transacciones (ej: datos de contacto al agendar una cita)\n• Con proveedores de servicios que nos ayudan a operar la plataforma\n• Cuando sea requerido por ley o autoridad competente\n• Para proteger los derechos, propiedad o seguridad de HomeMatch AI o sus usuarios',
          ),
          _Section(
            theme: theme,
            title: '4. Seguridad de los Datos',
            content:
            'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información:\n\n• Autenticación segura mediante Google OAuth2\n• Tokens JWT con expiración para las sesiones\n• Comunicación cifrada mediante HTTPS\n• Base de datos protegida con acceso restringido\n• Almacenamiento seguro de credenciales en el dispositivo',
          ),
          _Section(
            theme: theme,
            title: '5. Tus Derechos',
            content:
            'Tienes derecho a:\n\n• Acceder a tu información personal almacenada\n• Corregir datos incorrectos desde tu perfil\n• Eliminar tu cuenta y datos asociados\n• Exportar tu historial de búsquedas\n• Optar por no recibir notificaciones\n\nPara ejercer estos derechos, contacta a soporte@homematch.ai',
          ),
          _Section(
            theme: theme,
            title: '6. Cookies y Tecnologías Similares',
            content:
            'La aplicación móvil utiliza almacenamiento local seguro para guardar tu sesión y preferencias. No utilizamos cookies de rastreo de terceros ni publicidad dirigida.',
          ),
          _Section(
            theme: theme,
            title: '7. Retención de Datos',
            content:
            'Conservamos tu información mientras tu cuenta esté activa o sea necesario para proporcionarte servicios. Si eliminas tu cuenta, eliminaremos tu información personal en un plazo de 30 días, excepto cuando sea necesario conservarla por obligaciones legales.',
          ),
          _Section(
            theme: theme,
            title: '8. Cambios en esta Política',
            content:
            'Podemos actualizar esta política periódicamente. Te notificaremos de cambios significativos a través de la aplicación. El uso continuado del servicio después de los cambios constituye tu aceptación de la nueva política.',
          ),
          _Section(
            theme: theme,
            title: '9. Contacto',
            content:
            'Si tienes preguntas sobre esta Política de Privacidad o deseas ejercer tus derechos, contáctanos:\n\nEmail: soporte@homematch.ai\nCentro de Ayuda: disponible en la aplicación',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String content;

  const _Section({
    required this.theme,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}