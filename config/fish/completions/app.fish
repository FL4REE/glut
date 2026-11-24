# Vervollstaendigung fuer `app` (Kurznamen aus ~/.config/app/apps.conf)
complete -c app -f -a "(app --complete 2>/dev/null)"
complete -c app -f -l list -d "Alle Kurznamen anzeigen"
complete -c app -f -l help -d "Hilfe"
