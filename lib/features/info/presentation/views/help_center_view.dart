import 'package:flutter/material.dart';

class HelpCenterView extends StatefulWidget {
  const HelpCenterView({super.key});

  @override
  State<HelpCenterView> createState() => _HelpCenterViewState();
}

class _HelpCenterViewState extends State<HelpCenterView> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': '¿Cómo puedo publicar una propiedad?',
      'answer':
      'Para publicar una propiedad necesitas tener una cuenta de Vendedor o Inmobiliaria. Ve a la sección de Propiedades, toca el botón "+" en la parte superior derecha y completa el formulario con los datos de tu propiedad incluyendo fotos, precio, ubicación y características.',
    },
    {
      'question': '¿Cómo funciona la clasificación con IA?',
      'answer':
      'HomeMatch AI utiliza un algoritmo de Machine Learning (K-Means) para clasificar automáticamente las propiedades en segmentos como "Casa Familiar", "Departamento Económico", "Residencia Premium" o "Propiedad de Inversión", basándose en precio, tamaño, habitaciones y tipo de propiedad.',
    },
    {
      'question': '¿Cómo agendo una visita a una propiedad?',
      'answer':
      'Entra al detalle de cualquier propiedad tocando su card. En la parte inferior encontrarás el botón "Agendar visita". Selecciona el tipo de visita (presencial, virtual o telefónica), elige la fecha y hora y confirma. El vendedor recibirá tu solicitud.',
    },
    {
      'question': '¿Puedo guardar propiedades como favoritos?',
      'answer':
      'Sí. En cualquier card de propiedad encontrarás un ícono de corazón en la esquina superior derecha. Tócalo para guardar la propiedad en tu sección de Favoritos. Puedes acceder a tus favoritos desde la barra de navegación inferior.',
    },
    {
      'question': '¿Cómo cambio mi tipo de cuenta?',
      'answer':
      'El tipo de cuenta (Comprador, Vendedor, Inmobiliaria) se asigna al momento de registrarte. Si necesitas cambiar tu tipo de cuenta, contacta a soporte desde esta sección.',
    },
    {
      'question': '¿Los datos de mi búsqueda son privados?',
      'answer':
      'Sí. Tu historial de búsquedas es completamente privado y solo tú puedes verlo. Lo usamos únicamente para mejorar tus recomendaciones personalizadas con IA.',
    },
    {
      'question': '¿Cómo funciona el sistema de recomendaciones?',
      'answer':
      'HomeMatch AI analiza tus propiedades favoritas y tu historial de búsquedas para recomendarte propiedades similares usando embeddings y similitud coseno. Mientras más uses la app, mejores serán tus recomendaciones.',
    },
    {
      'question': '¿Puedo usar la app sin crear una cuenta?',
      'answer':
      'Puedes ver propiedades públicas sin cuenta, pero para guardar favoritos, agendar visitas, chatear con vendedores y recibir recomendaciones personalizadas necesitas iniciar sesión con tu cuenta de Google.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Centro de ayuda', style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Buscador de ayuda
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search,
                    color: theme.colorScheme.outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  '¿En qué podemos ayudarte?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contacto rápido
          Text('Contacto rápido',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ContactCard(
                  theme: theme,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: 'soporte@homematch.ai',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactCard(
                  theme: theme,
                  icon: Icons.chat_outlined,
                  label: 'Chat',
                  value: 'En la app',
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FAQs
          Text('Preguntas frecuentes',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...List.generate(
            _faqs.length,
                (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _expandedIndex == i
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: false,
                onExpansionChanged: (expanded) =>
                    setState(() =>
                    _expandedIndex = expanded ? i : null),
                tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 16),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  _faqs[i]['question']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                iconColor: theme.colorScheme.primary,
                collapsedIconColor: theme.colorScheme.outline,
                children: [
                  Text(
                    _faqs[i]['answer']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Versión
          Center(
            child: Text(
              'HomeMatch AI v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ContactCard({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              )),
          const SizedBox(height: 2),
          Text(value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}