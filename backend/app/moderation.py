"""
Filtro de lenguaje inapropiado para HomeMatch AI.

Enfoque deliberadamente simple (lista de palabras + normalización) en vez
de un modelo de NLP pesado: para el volumen y alcance de este proyecto,
un filtro de palabras es más rápido, 100% explicable, y no le agrega
dependencias/carga a ningún servicio. Se puede ampliar la lista sin tocar
la lógica.

Se usa en: nombre de usuario (registro y edición de perfil), título y
descripción de propiedades, y mensajes de chat.
"""

import unicodedata

# Mapeo de "leetspeak" — números/símbolos que la gente usa para reemplazar
# letras y evadir el filtro (ej. "3stupyd4" en vez de "estupida"). También
# incluye 'y' -> 'i', porque es un cambio fonético muy común en insultos
# en español ("estupyda" en vez de "estupida").
_LEET_MAP = str.maketrans({
    "0": "o", "1": "i", "3": "e", "4": "a", "5": "s",
    "7": "t", "8": "b", "@": "a", "$": "s", "!": "i",
    "y": "i",
})

# Caracteres que se insertan a propósito en medio de una palabra para
# partirla (ej. "pi-nche" en vez de "pinche"). Se quitan ANTES de separar
# por espacios, así "pi-nche" se vuelve una sola palabra: "pinche".
_EVASION_CHARS = str.maketrans("", "", "-_.*")

# Lista base — amplíala según lo que necesites cubrir. Están en minúsculas
# y sin acentos porque _normalize() les hace lo mismo al texto de entrada
# antes de compararlas.
BANNED_WORDS = {
    # --- Insultos generales ---
    "puto", "puta", "putos", "putas", "putazo",
    "pendejo", "pendeja", "pendejos", "pendejas", "pendejada", "pendejadas",
    "cabron", "cabrona", "cabrones", "cabronas",
    "idiota", "idiotas",
    "estupido", "estupida", "estupidos", "estupidas",
    "imbecil", "imbeciles",
    "maldito", "maldita", "malditos", "malditas",
    "menso", "mensa", "mensos", "mensas",
    "tarado", "tarada", "tarados", "taradas",
    "baboso", "babosa", "babosos", "babosas",
    "naco", "naca", "nacos", "nacas",
    "gonorrea",
    "cretino", "cretina",
    "imbecilidad",
    "pinche", "pinches",

    # --- Lenguaje vulgar / sexual ---
    "verga", "vergas", "vergazo",
    "chinga", "chingada", "chingado", "chingados", "chingadas", "chingar",
    "chingones", "chingona", "chingon",
    "culero", "culera", "culeros", "culeras",
    "perra", "perras",
    "zorra", "zorras",
    "pinche", "pinches",
    "mamada", "mamadas", "mamon", "mamones",
    "coger", "cogiendo",
    "pito", "pitos",
    "nalgas",

    # --- Insultos discriminatorios (para bloquearlos, no para usarlos) ---
    "joto", "jotos",
    "marica", "maricas", "maricon", "mariconez", "maricones",
    "nazi", "nazis",
    "retrasado", "retrasada", "retrasados", "retrasadas",
    "mongolico", "mongolica",

    # --- Groserías cortas comunes ---
    "mierda", "mierdas", "mierdero",
    "carajo", "carajos",
    "hijueputa", "hdp",
}


def _normalize(text: str) -> str:
    """minúsculas + sin acentos + sin trucos de leetspeak/separadores."""
    text = text.lower().strip()
    text = unicodedata.normalize("NFKD", text)
    text = "".join(c for c in text if not unicodedata.combining(c))
    text = text.translate(_EVASION_CHARS)  # quita guiones/puntos usados para partir palabras
    text = text.translate(_LEET_MAP)  # normaliza números/símbolos a letras
    return text


def contains_inappropriate_language(text: str) -> bool:
    """True si el texto contiene alguna palabra de la lista prohibida."""
    if not text:
        return False
    normalized = _normalize(text)
    # separamos por cualquier caracter que no sea letra, para detectar
    # la palabra aunque venga pegada a puntuación (ej. "pendejo!!")
    words = "".join(c if c.isalnum() else " " for c in normalized).split()
    return any(word in BANNED_WORDS for word in words)


def get_first_bad_word(text: str) -> str | None:
    """Regresa la primera palabra prohibida encontrada (o None)."""
    if not text:
        return None
    normalized = _normalize(text)
    words = "".join(c if c.isalnum() else " " for c in normalized).split()
    for word in words:
        if word in BANNED_WORDS:
            return word
    return None