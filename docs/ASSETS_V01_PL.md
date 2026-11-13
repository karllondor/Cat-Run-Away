# Cat, Run Away!: paczka assetów 0.1

Zestaw do małego prototypu: labirynt widziany z góry i parkour widziany z boku.
Poprawna nazwa gry to Cat, Run Away!. Nazwa we wcześniejszych paczkach zawierała literówkę.

## Co jest w paczce

- Rudy bohater: chód dół/góra/prawo/lewo, bezruch i cztery pozy skoku.
- Brązowy pies: ruch w czterech kierunkach, bezruch, czujność, szczekanie i siad.
- Mama i uratowany kotek: dwa widoki. Są to statyczne sprite'y.
- Klucz, zamknięte i otwarte drzwi, tunel.
- Trawa, ścieżka, ziemia, żywopłoty, kwiaty, drzewo, fontanna, głaz, znak.
- Platformy trawiaste i kamienne oraz wypełnienia terenu.
- Serduszka pełne/puste, znacznik zadania, łapka pomocy, przyciski kierunków, skoku i pauzy.
- Sześć oryginalnych syntetycznych dźwięków WAV.
- SpriteFrames do Godota, osobne PNG, arkusze PNG, manifest i podgląd GIF.

## Szybkie otwarcie

Otwórz project.godot w Godot 4 i uruchom F6/F5. To podgląd assetów i animacji, bez grywalnej logiki.
Klawisze 1-6 odtwarzają kolejno: klucz, skok, utrata zdrowia, ratunek kotka, drzwi, klik.

Do istniejącego projektu skopiuj assets/ i dwa pliki godot/hero_frames.tres oraz godot/dog_frames.tres.
Zachowaj ścieżki res://assets/. Przypisz zasób do AnimatedSprite2D.sprite_frames.
Ustaw filtrowanie tekstur Nearest, bez mipmap. Animacje walk_left mają już odbite klatki.
Nie włączaj dodatkowo flip_h dla walk_left, bo kierunek odwróci się ponownie.

## Rozmiary i kotwice

| Element | Rozmiar |
| --- | --- |
| Klatka bohatera i psa | 128 x 128 px |
| Arkusz postaci | 512 x 512 px, siatka 4 x 4 |
| Grunt i elementy platform | 64 x 64 px |
| Większe dekoracje, kotki, drzwi | 128 x 128 px |
| Ikony i przyciski | 64 x 64 px |

Postacie mają wspólną linię stóp y=122 i oś x=64. Dla węzła stojącego na ziemi
ustaw AnimatedSprite2D.offset = Vector2(0, -58), bo sprite jest wyśrodkowany.
Kolizje twórz osobno w silniku: mały obrys przy łapach w labiryncie i kapsuła w parkourze.
Grafika nie definiuje kolizji.

## Układ arkuszy

Wiersze 0-2: dół, góra, prawo; cztery kolejne fazy ruchu na wiersz.
Wiersz 3 bohatera: przygotowanie, wybicie, lot, lądowanie.
Wiersz 3 psa: bezruch, czujność, szczekanie, siad.
Lewa strona pochodzi z odbicia prawej. Skok powinien wybierać pozy zależnie od stanu fizyki,
a nie odtwarzać wszystkich czterech klatek w pętli przez cały lot.

## Ograniczenia prototypu

To krótka animacja czteroklatkowa z wygenerowanych klatek. Ruch łap i proporcje wymagają
oceny w grze; nie jest to zatwierdzona finalna animacja. Chód pełni również rolę biegu
po zmianie prędkości odtwarzania. Nie ma osobnego arkusza biegu, animacji mamy ani dialogów.
Kafelki gruntu są pełnymi prostokątami, ale nie są bezszwowymi teksturami ani kompletnym
autotilesetem. Żywopłoty i platformy są modułami dekoracyjnymi; niektóre mają przezroczyste
marginesy. Przy składaniu można je nakładać, a docelowy tileset wymaga jeszcze dopasowania
krawędzi. Nie ma gotowych map, kolizji, AI psa ani grywalnego poziomu.

## Pochodzenie

Grafika: wbudowane OpenAI ImageGen, dokładny identyfikator modelu obrazu nie jest ujawniony.
Przygotowanie i walidacja: Codex, model z rodziny GPT-6; dokładny wariant nie jest ujawniony.
Źródłowe arkusze i dokładne prompty zachowano w source/. Czyszczenie odłączonych szumów,
cięcie klatek, wspólna skala, wyrównanie stóp i eksport nie zmieniają zaprojektowanych póz.
Obrazy źródłowe faktycznie mają 1254 x 1254 px mimo zamówienia 1024 x 1024.
Nie użyto pobranych assetów innych autorów. Status prawny treści AI zależy od właściwych
warunków usługi i prawa; paczka nie przypisuje im niepotwierdzonej licencji CC0.
Kod pomocniczy i oryginalne dźwięki w tej paczce udostępniono na MIT (LICENSE_CODE_AUDIO.txt).

## Uwaga o aktualnej wersji

To instrukcja bazowego zestawu 0.1. Aktualny zestaw 0.2 ma dodatkowy TileSet,
kolizje platform oraz nowy podgląd parkouru. Patrz README.md i PLATFORMER_PL.md.

## Weryfikacja

Wynik sprawdzenia plików, wymiarów, przezroczystości i importu Godota jest w docs/QA.json.
SHA256SUMS.txt pozwala sprawdzić integralność paczki. Pliki .godot/ są pomijane w archiwum.
