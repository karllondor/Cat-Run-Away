# Platformer expansion 0.2

34 nowe pliki graficzne: 16 kafelków terenu, zbiorczy atlas, 16 obiektów i jedno tło.
Stylem pasują do bohatera i psa z wersji 0.1. Arkusze źródłowe i prompty są w source/platformer/.

## Korzystanie w Godocie

Otwórz project.godot i uruchom F5. Domyślna scena pokazuje nowe assety złożone w parkour.
To podgląd kompozycji i animacji, bez sterowania postacią i bez ukończonego poziomu.
TAB przełącza na wcześniejszy podgląd labiryntu i animacji. Jest też przycisk powrotu.

Przypisz godot/platformer_tileset.tres do TileMapLayer.tile_set. Kafelki mają 64 x 64 px,
source_id=0, physics collision layer=1. Atlas ma siatkę 4 x 4, bez marginesów i odstępów.

| Wiersz atlasu | Kolumny 0, 1, 2, 3 |
| --- | --- |
| 0 | ziemia: góra lewa, góra środek, góra prawa, wypełnienie |
| 1 | ziemia: ściana lewa, ściana prawa, dół lewy, dół prawy |
| 2 | kamień: góra lewa, góra środek, góra prawa, wypełnienie |
| 3 | kamień: ściana lewa, ściana prawa, dół lewy, dół prawy |

Każdy kafelek ma kolizję. Trawa na górze jest dekoracją: na trawiastych górnych kafelkach
kolizja zaczyna się 8 px poniżej krawędzi. Pozostałe kafelki mają pełną kolizję 64 x 64.
To atlas do ręcznego układania, bez automatycznych masek terenu.

## Osobne platformy

W godot/platforms/ jest 11 scen StaticBody2D: trzy kamienie do skakania, filar,
trzy wiszące platformy trawiaste, drewniana półka i trzy segmenty mostku.
Przeciągnij scenę do poziomu. Zawiera Sprite2D i niezależny CollisionPolygon2D.
Kolizje są prostokątne, wyznaczone z górnej szerokiej części sprite'a. Przy mostku
górna lina znajduje się powyżej powierzchni kolizji i jest dekoracją.

Schody, jaskinia, krzak, trawa i znak są grafikami bez gotowych kolizji.
Schody wymagają osobnych stopni lub rampy przy budowie gry.

## Krawędzie i ograniczenia

Powtarzane kafelki wypełnienia oraz połączenia góra-lewa/środek/prawa i góra-wypełnienie
mają zgodne piksele na wspólnych granicach, co jest sprawdzane w docs/QA.json.
Pozostaje widoczna stylistyka bloków; nie oznacza to bezszwowości wszystkich dowolnych
połączeń. Dekoracyjne skrajne ściany i narożniki dobieraj ręcznie.
Tło 1280 x 720 px jest pojedynczym obrazem na skończony odcinek. Nie jest zapętlone
i nie ma oddzielnych warstw paralaksy.

Animacje postaci są z wersji 0.1. Nie wygenerowano na nowo bohatera, osobnego biegu
ani nowych stanów ruchu. Nie ma jeszcze fizyki gracza, AI psa, systemu ratowania
kotków ani APK. Układ podglądu nie jest testem zasięgu skoku.

## Walidacja

Import i sprawdzenie zasobów: Godot 4.6.3. Sprawdzane są 115 assetów,
odwołania do klatek, 16 kafelków z kolizjami, 11 scen platform oraz zgodność wskazanych
krawędzi. Uruchomienie podglądu w trybie headless potwierdza poprawność skryptów.
Podgląd kompozycji PNG został oceniony wizualnie; nie wykonano przeglądu renderu GPU.

Grafika powstała przez wbudowane OpenAI ImageGen; dokładny model obrazu nie jest ujawniony.
Przygotowanie: Codex, rodzina GPT-6; dokładny wariant wykonawczy nie jest ujawniony.
