import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Términos y condiciones',
            style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Términos y Condiciones de Uso',
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
            title: '1. Aceptación de los Términos',
            content:
            'Al acceder y utilizar HomeMatch AI, aceptas estar sujeto a estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de estos términos, no podrás acceder al servicio. Esta aplicación es un proyecto académico desarrollado por estudiantes de Ingeniería en Desarrollo de Software de la Universidad Politécnica de Chiapas.',
          ),
          _Section(
            theme: theme,
            title: '2. Uso del Servicio',
            content:
            'HomeMatch AI es una plataforma de búsqueda y publicación de propiedades inmobiliarias. El servicio incluye:\n\n• Búsqueda y filtrado de propiedades\n• Publicación de propiedades para venta o renta\n• Sistema de recomendaciones basado en IA\n• Agenda de citas para visitas\n• Chat entre usuarios y vendedores\n\nEl uso del servicio está sujeto a tener una cuenta válida y respetar las normas de la comunidad.',
          ),
          _Section(
            theme: theme,
            title: '3. Cuentas de Usuario',
            content:
            'Para acceder a las funciones completas de la plataforma, debes crear una cuenta usando tu cuenta de Google. Eres responsable de mantener la confidencialidad de tu cuenta y de todas las actividades que ocurran bajo ella.\n\nExisten cuatro tipos de cuenta:\n\n• Comprador: para buscar y agendar visitas\n• Vendedor: para publicar y gestionar propiedades\n• Inmobiliaria: para gestionar múltiples propiedades y agentes\n• Administrador: para gestionar la plataforma',
          ),
          _Section(
            theme: theme,
            title: '4. Publicación de Propiedades',
            content:
            'Los usuarios con cuenta de Vendedor o Inmobiliaria pueden publicar propiedades. Al publicar una propiedad, declaras que:\n\n• La información proporcionada es veraz y precisa\n• Tienes autorización para publicar dicha propiedad\n• Las fotos corresponden a la propiedad real\n• El precio indicado es el precio real de venta o renta\n\nHomeMatch AI se reserva el derecho de eliminar publicaciones que no cumplan con estas condiciones.',
          ),
          _Section(
            theme: theme,
            title: '5. Inteligencia Artificial',
            content:
            'HomeMatch AI utiliza algoritmos de Machine Learning para clasificar propiedades y generar recomendaciones personalizadas. Estos resultados son orientativos y no constituyen asesoramiento financiero o inmobiliario profesional. La clasificación automática puede no reflejar con exactitud las características de la propiedad.',
          ),
          _Section(
            theme: theme,
            title: '6. Limitación de Responsabilidad',
            content:
            'HomeMatch AI actúa como intermediario entre compradores/arrendatarios y vendedores/arrendadores. No somos responsables de:\n\n• La exactitud de la información publicada por los usuarios\n• Las transacciones realizadas entre usuarios\n• El estado real de las propiedades\n• Disputas entre usuarios de la plataforma',
          ),
          _Section(
            theme: theme,
            title: '7. Cambios en los Términos',
            content:
            'Nos reservamos el derecho de modificar estos términos en cualquier momento. Las modificaciones entrarán en vigor inmediatamente después de su publicación en la aplicación. El uso continuado del servicio después de dichos cambios constituye tu aceptación de los nuevos términos.',
          ),
          _Section(
            theme: theme,
            title: '8. Contacto',
            content:
            'Si tienes preguntas sobre estos Términos y Condiciones, puedes contactarnos a través del Centro de Ayuda de la aplicación o escribirnos a soporte@homematch.ai',
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