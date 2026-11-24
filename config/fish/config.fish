source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
    # themectl setzt pokefetch_pokemon (Pokémon, deren Sprite-Farbe zum Theme passt)
    # und pokefetch_farben (grobe Farbklassen als Rückfall)
    # pokefetch_theme_aus (Kontextmenü > System) schaltet die Theme-Anpassung ab
    if set -q pokefetch_theme_aus
        pokefetch-kurz --shell-name fish show
    else if set -q pokefetch_pokemon[1]
        pokefetch-kurz --shell-name fish --pokemon (random choice $pokefetch_pokemon) show
    # Farbe wählen: set -U pokefetch_farben blau   (leer lassen = alle)
    else if set -q pokefetch_farben[1]; and set -l p (pokefetch-color $pokefetch_farben)
        pokefetch-kurz --shell-name fish --pokemon $p show
    else
        pokefetch-kurz --shell-name fish show
    end
end
starship init fish | source
