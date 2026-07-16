class LocationsData {
  static const Map<String, List<String>> municipiosPorEstado = {
    'Chiapas': [
      'Tuxtla Gutiérrez',
      'San Cristóbal de las Casas',
      'Tapachula',
      'Comitán de Domínguez',
      'Palenque',
      'Ocosingo',
      'Tonalá',
      'Arriaga',
      'Chiapa de Corzo',
      'Villaflores',
      'Cintalapa',
      'Pichucalco',
      'Reforma',
      'Yajalón',
      'Simojovel',
      'Bochil',
      'Jiquipilas',
      'Berriozábal',
      'Acala',
      'Socoltenango',
      'Las Margaritas',
      'Altamirano',
      'Motozintla',
      'Huixtla',
      'Mapastepec',
      'Pijijiapan',
      'Acacoyagua',
      'Escuintla',
      'Suchiate',
      'Cacahoatán',
    ],
    'Tabasco': [
      'Villahermosa',
      'Cárdenas',
      'Comalcalco',
      'Macuspana',
      'Tenosique',
      'Jalpa de Méndez',
    ],
    'Oaxaca': [
      'Oaxaca de Juárez',
      'Tuxtepec',
      'Juchitán de Zaragoza',
      'Salina Cruz',
      'Huatulco',
    ],
    'Ciudad de México': [
      'Álvaro Obregón',
      'Azcapotzalco',
      'Benito Juárez',
      'Coyoacán',
      'Cuajimalpa',
      'Cuauhtémoc',
      'Gustavo A. Madero',
      'Iztacalco',
      'Iztapalapa',
      'Magdalena Contreras',
      'Miguel Hidalgo',
      'Milpa Alta',
      'Tláhuac',
      'Tlalpan',
      'Venustiano Carranza',
      'Xochimilco',
    ],
    'Jalisco': [
      'Guadalajara',
      'Zapopan',
      'Tlaquepaque',
      'Tonalá',
      'Tlajomulco de Zúñiga',
      'Puerto Vallarta',
      'Lagos de Moreno',
    ],
    'Nuevo León': [
      'Monterrey',
      'San Nicolás de los Garza',
      'Guadalupe',
      'Apodaca',
      'San Pedro Garza García',
      'Santa Catarina',
      'General Escobedo',
    ],
    'Veracruz': [
      'Veracruz',
      'Xalapa',
      'Coatzacoalcos',
      'Córdoba',
      'Orizaba',
      'Tuxpan',
      'Poza Rica',
    ],
    'Quintana Roo': [
      'Cancún',
      'Playa del Carmen',
      'Tulum',
      'Cozumel',
      'Chetumal',
    ],
    'Yucatán': [
      'Mérida',
      'Valladolid',
      'Progreso',
      'Izamal',
    ],
  };

  static const Map<String, List<String>> zonasPorMunicipio = {
    'Tuxtla Gutiérrez': [
      'Centro',
      'Norte',
      'Sur',
      'Oriente',
      'Poniente',
      'Terán',
      'Patria Nueva',
      'Las Granjas',
      'Xamaipak',
      'Colinas del Sur',
      'Fraccionamiento Los Pinos',
      'Colonia Moctezuma',
      'San Roque',
      'Jardines de Tuxtla',
      'Nuevo Horizonte',
      'Villa Real',
      'Copoya',
      'Boulevard',
    ],
    'San Cristóbal de las Casas': [
      'Centro Histórico',
      'Guadalupe',
      'Mexicanos',
      'El Cerrillo',
      'La Merced',
      'San Diego',
      'Tlaxcala',
      'Zona Hotelera',
    ],
    'Tapachula': [
      'Centro',
      'Norte',
      'Sur',
      'Col. Cívica',
      'La Chacara',
      'San Sebastián',
    ],
    'Comitán de Domínguez': [
      'Centro',
      'Norte',
      'Sur',
      'Las Delicias',
      'El Campanario',
    ],
    'Berriozábal': [
      'Centro',
      'Norte',
      'Sur',
      'Col. Guadalupe',
    ],
    'Chiapa de Corzo': [
      'Centro',
      'Norte',
      'Ribera',
      'Col. Nueva',
    ],
  };

  static List<String> getEstados() {
    return municipiosPorEstado.keys.toList()..sort();
  }

  static List<String> getMunicipios(String estado) {
    return municipiosPorEstado[estado] ?? [];
  }

  static List<String> getZonas(String municipio) {
    return zonasPorMunicipio[municipio] ?? [
      'Centro',
      'Norte',
      'Sur',
      'Oriente',
      'Poniente',
      'Zona Residencial',
      'Zona Comercial',
    ];
  }

  static List<String> searchMunicipios(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <String>[];
    for (final municipios in municipiosPorEstado.values) {
      for (final m in municipios) {
        if (m.toLowerCase().contains(q)) results.add(m);
      }
    }
    results.sort();
    return results;
  }

  static String? getEstadoFromMunicipio(String municipio) {
    for (final entry in municipiosPorEstado.entries) {
      if (entry.value.contains(municipio)) return entry.key;
    }
    return null;
  }
}