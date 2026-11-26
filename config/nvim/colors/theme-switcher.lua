-- Erzeugt von theme-switcher, Theme: spectra. Nicht von Hand bearbeiten.
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = "dark"
vim.g.colors_name = "theme-switcher"
vim.o.termguicolors = true

local c = {
  base00 = "#1a1b1e",
  base01 = "#232529",
  base02 = "#b2c3ff",
  base03 = "#828286",
  base04 = "#a1a2a6",
  base05 = "#eaeaef",
  base06 = "#f4f4f7",
  base07 = "#ffffff",
  base08 = "#ef5d67",
  base09 = "#f3915d",
  base0A = "#f7c553",
  base0B = "#8edb73",
  base0C = "#7dd8d3",
  base0D = "#ffffff",
  base0E = "#e29ef3",
  base0F = "#a4464d",
}

local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

hl("Normal", { fg = c.base05, bg = c.base00 })
hl("NormalFloat", { fg = c.base05, bg = c.base01 })
hl("NormalNC", { fg = c.base05, bg = c.base00 })
hl("FloatBorder", { fg = c.base03, bg = c.base01 })
hl("FloatTitle", { fg = c.base0D, bg = c.base01, bold=true })
hl("Cursor", { fg = c.base00, bg = c.base05 })
hl("CursorLine", { bg = c.base01 })
hl("CursorColumn", { bg = c.base01 })
hl("ColorColumn", { bg = c.base01 })
hl("CursorLineNr", { fg = c.base0D, bg = c.base01, bold=true })
hl("LineNr", { fg = c.base03 })
hl("SignColumn", { fg = c.base03, bg = c.base00 })
hl("FoldColumn", { fg = c.base03, bg = c.base00 })
hl("Folded", { fg = c.base04, bg = c.base01 })
hl("VertSplit", { fg = c.base02 })
hl("WinSeparator", { fg = c.base02 })
hl("EndOfBuffer", { fg = c.base01 })
hl("Visual", { bg = c.base02 })
hl("VisualNOS", { bg = c.base02 })
hl("Search", { fg = c.base00, bg = c.base0A })
hl("IncSearch", { fg = c.base00, bg = c.base09 })
hl("CurSearch", { fg = c.base00, bg = c.base09 })
hl("Substitute", { fg = c.base00, bg = c.base0A })
hl("MatchParen", { fg = c.base0A, bg = c.base02, bold=true })
hl("NonText", { fg = c.base03 })
hl("Whitespace", { fg = c.base02 })
hl("SpecialKey", { fg = c.base03 })
hl("Conceal", { fg = c.base0D })
hl("Directory", { fg = c.base0D })
hl("Title", { fg = c.base0D, bold=true })
hl("ErrorMsg", { fg = c.base08 })
hl("WarningMsg", { fg = c.base0A })
hl("ModeMsg", { fg = c.base0B })
hl("MoreMsg", { fg = c.base0B })
hl("Question", { fg = c.base0D })
hl("Pmenu", { fg = c.base05, bg = c.base01 })
hl("PmenuSel", { fg = c.base00, bg = c.base0D })
hl("PmenuSbar", { bg = c.base02 })
hl("PmenuThumb", { bg = c.base03 })
hl("WildMenu", { fg = c.base00, bg = c.base0D })
hl("StatusLine", { fg = c.base05, bg = c.base01 })
hl("StatusLineNC", { fg = c.base03, bg = c.base01 })
hl("TabLine", { fg = c.base03, bg = c.base01 })
hl("TabLineFill", { bg = c.base01 })
hl("TabLineSel", { fg = c.base0D, bg = c.base00, bold=true })
hl("WinBar", { fg = c.base05 })
hl("WinBarNC", { fg = c.base03 })
hl("QuickFixLine", { bg = c.base02 })
hl("SpellBad", { undercurl=true, sp=c.base08 })
hl("SpellCap", { undercurl=true, sp=c.base0D })
hl("DiffAdd", { fg = c.base0B, bg = c.base01 })
hl("DiffChange", { fg = c.base0A, bg = c.base01 })
hl("DiffDelete", { fg = c.base08, bg = c.base01 })
hl("DiffText", { fg = c.base0D, bg = c.base02 })
hl("Added", { fg = c.base0B })
hl("Changed", { fg = c.base0A })
hl("Removed", { fg = c.base08 })
hl("Comment", { fg = c.base03, italic=true })
hl("Constant", { fg = c.base09 })
hl("String", { fg = c.base0B })
hl("Character", { fg = c.base0B })
hl("Number", { fg = c.base09 })
hl("Boolean", { fg = c.base09 })
hl("Float", { fg = c.base09 })
hl("Identifier", { fg = c.base08 })
hl("Function", { fg = c.base0D })
hl("Statement", { fg = c.base0E })
hl("Conditional", { fg = c.base0E })
hl("Repeat", { fg = c.base0E })
hl("Label", { fg = c.base0A })
hl("Operator", { fg = c.base05 })
hl("Keyword", { fg = c.base0E })
hl("Exception", { fg = c.base08 })
hl("PreProc", { fg = c.base0A })
hl("Include", { fg = c.base0D })
hl("Define", { fg = c.base0E })
hl("Macro", { fg = c.base08 })
hl("Type", { fg = c.base0A })
hl("StorageClass", { fg = c.base0A })
hl("Structure", { fg = c.base0E })
hl("Typedef", { fg = c.base0A })
hl("Special", { fg = c.base0C })
hl("SpecialChar", { fg = c.base0F })
hl("Tag", { fg = c.base0A })
hl("Delimiter", { fg = c.base0F })
hl("Debug", { fg = c.base08 })
hl("Underlined", { fg = c.base0D, underline=true })
hl("Error", { fg = c.base08 })
hl("Todo", { fg = c.base00, bg = c.base0A, bold=true })
hl("@variable", { fg = c.base05 })
hl("@variable.builtin", { fg = c.base08 })
hl("@variable.parameter", { fg = c.base08 })
hl("@variable.member", { fg = c.base08 })
hl("@property", { fg = c.base08 })
hl("@constant", { fg = c.base09 })
hl("@constant.builtin", { fg = c.base09 })
hl("@module", { fg = c.base0A })
hl("@string", { fg = c.base0B })
hl("@string.escape", { fg = c.base0C })
hl("@string.special", { fg = c.base0C })
hl("@character", { fg = c.base0B })
hl("@number", { fg = c.base09 })
hl("@boolean", { fg = c.base09 })
hl("@function", { fg = c.base0D })
hl("@function.builtin", { fg = c.base0C })
hl("@function.call", { fg = c.base0D })
hl("@function.method", { fg = c.base0D })
hl("@constructor", { fg = c.base0C })
hl("@keyword", { fg = c.base0E })
hl("@keyword.function", { fg = c.base0E })
hl("@keyword.return", { fg = c.base0E })
hl("@keyword.import", { fg = c.base0D })
hl("@operator", { fg = c.base05 })
hl("@punctuation", { fg = c.base0F })
hl("@punctuation.bracket", { fg = c.base05 })
hl("@punctuation.delimiter", { fg = c.base05 })
hl("@type", { fg = c.base0A })
hl("@type.builtin", { fg = c.base0A })
hl("@attribute", { fg = c.base0C })
hl("@tag", { fg = c.base08 })
hl("@tag.attribute", { fg = c.base0A })
hl("@tag.delimiter", { fg = c.base0F })
hl("@comment", { fg = c.base03, italic=true })
hl("@markup.heading", { fg = c.base0D, bold=true })
hl("@markup.link", { fg = c.base0C, underline=true })
hl("@markup.raw", { fg = c.base0B })
hl("@markup.list", { fg = c.base08 })
hl("@markup.strong", { bold=true })
hl("@markup.italic", { italic=true })
hl("DiagnosticError", { fg = c.base08 })
hl("DiagnosticWarn", { fg = c.base0A })
hl("DiagnosticInfo", { fg = c.base0D })
hl("DiagnosticHint", { fg = c.base0C })
hl("DiagnosticOk", { fg = c.base0B })
hl("DiagnosticUnderlineError", { undercurl=true, sp=c.base08 })
hl("DiagnosticUnderlineWarn", { undercurl=true, sp=c.base0A })
hl("DiagnosticUnderlineInfo", { undercurl=true, sp=c.base0D })
hl("DiagnosticUnderlineHint", { undercurl=true, sp=c.base0C })
hl("LspReferenceText", { bg = c.base02 })
hl("LspReferenceRead", { bg = c.base02 })
hl("LspReferenceWrite", { bg = c.base02 })
hl("LspInlayHint", { fg = c.base03, bg = c.base01, italic=true })
hl("GitSignsAdd", { fg = c.base0B })
hl("GitSignsChange", { fg = c.base0A })
hl("GitSignsDelete", { fg = c.base08 })
hl("TelescopeBorder", { fg = c.base03, bg = c.base01 })
hl("TelescopeNormal", { fg = c.base05, bg = c.base01 })
hl("TelescopeSelection", { bg = c.base02 })
hl("TelescopeMatching", { fg = c.base0D, bold=true })
hl("NeoTreeNormal", { fg = c.base05, bg = c.base01 })
hl("NeoTreeNormalNC", { fg = c.base05, bg = c.base01 })
hl("NeoTreeDirectoryIcon", { fg = c.base0D })
hl("NeoTreeDirectoryName", { fg = c.base0D })
hl("NvimTreeNormal", { fg = c.base05, bg = c.base01 })
hl("NvimTreeFolderIcon", { fg = c.base0D })
hl("WhichKey", { fg = c.base0D })
hl("WhichKeyGroup", { fg = c.base0E })
hl("WhichKeyDesc", { fg = c.base05 })
hl("SnacksPickerMatch", { fg = c.base0D, bold=true })
hl("SnacksDashboardHeader", { fg = c.base0D })
hl("BlinkCmpMenu", { fg = c.base05, bg = c.base01 })
hl("BlinkCmpMenuSelection", { bg = c.base02 })
hl("BlinkCmpLabelMatch", { fg = c.base0D, bold=true })
hl("CmpItemAbbrMatch", { fg = c.base0D, bold=true })
hl("CmpItemKind", { fg = c.base0E })
hl("IblIndent", { fg = c.base02, nocombine=true })
hl("IblScope", { fg = c.base03, nocombine=true })
hl("MiniStatuslineModeNormal", { fg = c.base00, bg = c.base0D, bold=true })
hl("MiniStatuslineModeInsert", { fg = c.base00, bg = c.base0B, bold=true })
hl("MiniStatuslineModeVisual", { fg = c.base00, bg = c.base0E, bold=true })

vim.g.terminal_color_0 = "#2b2d31"
vim.g.terminal_color_1 = "#ef5d67"
vim.g.terminal_color_2 = "#8edb73"
vim.g.terminal_color_3 = "#f7c553"
vim.g.terminal_color_4 = "#7ca5ff"
vim.g.terminal_color_5 = "#e29ef3"
vim.g.terminal_color_6 = "#7dd8d3"
vim.g.terminal_color_7 = "#f8f8fa"
vim.g.terminal_color_8 = "#505258"
vim.g.terminal_color_9 = "#ff7680"
vim.g.terminal_color_10 = "#a2ee8b"
vim.g.terminal_color_11 = "#ffd86f"
vim.g.terminal_color_12 = "#97b6ff"
vim.g.terminal_color_13 = "#efb5f9"
vim.g.terminal_color_14 = "#94e8e3"
vim.g.terminal_color_15 = "#ffffff"
