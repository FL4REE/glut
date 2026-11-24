function pokefetch-kurz --description 'pokefetch mit kurzer OS-Zeile'
    set -l exe (command -v pokefetch)
    set -l py
    if test -n "$exe"
        set py (string split ' ' -- (string replace -r '^#!\s*' '' -- (head -n1 $exe)))
    end
    if string match -q '*python*' -- "$py"
        $py $__fish_config_dir/pokefetch-kurz.py $argv
    else
        command pokefetch $argv
    end
end
