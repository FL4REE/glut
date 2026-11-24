-- DMS Window Rules — managed by Dux Shell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=wr_1787093043689183460, name=org.gnome.Nautilus
hl.window_rule({ match = { class = "^org.gnome.Nautilus$" }, tile = true })

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, float = true })

-- DMS-RULE: id=dms-window-opaque, name=DMS Window Opaque
hl.window_rule({ match = { class = "^(dev\\.duxlabs\\.shell|com\\.danklinux\\.dms)$" }, opaque = true })
