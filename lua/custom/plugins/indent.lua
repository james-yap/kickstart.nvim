-- Personal indent-blankline tweak.
-- kickstart.plugins.indent_line installs + setups ibl; re-setup merges prefs
-- without editing the upstream example file.

require('ibl').setup {
  indent = {
    char = '▏',
  },
}
