-- Personal config entrypoint (loaded from init.lua SECTION 10).
-- Keep machine-varying and preference overrides here so init.lua stays close
-- to upstream kickstart and merges cleanly.
--
-- Load order matters:
--   1. enabled kickstart optional plugins
--   2. custom.plugins (format.lua merge, ibl tweak, personal plugins)
--   3. options / UI overrides
--   4. telescope overrides (after SECTION 5 setup)
--   5. personal keymaps

-- Optional kickstart examples (kept commented in upstream init.lua SECTION 10).
require 'kickstart.plugins.indent_line'
require 'kickstart.plugins.autopairs'
require 'kickstart.plugins.gitsigns' -- adds gitsigns recommended keymaps

require 'custom.plugins'
require 'custom.options'
require 'custom.telescope'
require 'custom.keymaps'
