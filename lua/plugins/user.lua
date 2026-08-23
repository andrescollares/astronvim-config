-- You can also add or configure plugins by creating files in this `plugins/` folder
-- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
-- Here are some examples:

-- Keep terminal output history in the buffer so it can be scrolled/searched
-- after the command finishes. 'scrollback' is an undocumented buffer-local
-- option for terminal buffers (default 0 = discard); see neovim PR #6142.
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(a)
    vim.api.nvim_set_option_value("scrollback", 10000, { buf = a.buf })
  end,
})

---@type LazySpec
return {
  -- {
  --   "zbirenbaum/copilot.lua",
  --   cmd = "Copilot",
  --   build = ":Copilot auth",
  --   event = "BufReadPost",
  --   opts = {
  --     suggestion = {
  --       keymap = {
  --         accept = false, -- handled by completion engine
  --       },
  --     },
  --     filetypes = {
  --       yaml = true,
  --       markdown = true,
  --     },
  --   },
  --   specs = {
  --     {
  --       "AstroNvim/astrocore",
  --       opts = {
  --         options = {
  --           g = {
  --             -- set the ai_accept function
  --             ai_accept = function()
  --               if require("copilot.suggestion").is_visible() then
  --                 require("copilot.suggestion").accept()
  --                 return true
  --               end
  --             end,
  --           },
  --         },
  --       },
  --     },
  --   },
  -- },
  -- {
  --   "olimorris/codecompanion.nvim",
  --   config = function()
  --     require("codecompanion").setup {
  --       -- Lazy.nvim will merge this with any existing defaults (from AstroNvim/Community)
  --       adapters = {
  --         http = {
  --           ["qwen_local"] = function()
  --             return require("codecompanion.adapters").extend("openai_compatible", {
  --               env = {
  --                 url = "http://localhost:8020",
  --                 chat_url = "/v1/chat/completions",
  --                 api_key = "TERM", -- Leave empty for local
  --               },
  --               schema = {
  --                 model = {
  --                   default = "qwen3.6-27b-autoround",
  --                 },
  --               },
  --             })
  --           end,
  --         },
  --       },
  --       interactions = {
  --         -- Apply the local adapter to all agent types
  --         chat = { adapter = "qwen_local" },
  --         review = { adapter = "qwen_local" },
  --         quick_fix = { adapter = "qwen_local" },
  --         inline = { adapter = "qwen_local" },
  --       },
  --       -- -- Optional: Adjust timeouts for slower local models
  --       -- display = {
  --       --   preview = {
  --       --     timeout = 10000, -- 10 seconds
  --       --   },
  --       -- },
  --     }
  --   end,
  -- },
  {
    -- Override AstroNvim's bundled toggleterm: auto_scroll (default true) runs
    -- `normal! G` on every terminal output event while in normal mode, which
    -- yanks the cursor to the bottom and prevents scrolling live output.
    "akinsho/toggleterm.nvim",
    opts = {
      auto_scroll = false,
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        sign = false,
        -- border = true,
        width = { "full", "full", "block", "block" },
        min_width = 30,
        left_pad = 1,
        icons = { "󰬺  ", "󰬻  ", "󰬼  ", "󰬽  ", "󰬾  ", "󰬿  " },
      },
      code = {
        sign = false,
        width = "block",
        min_width = 60,
        left_pad = 2,
        right_pad = 2,
        border = "thick",
        language_name = false,
        position = "right",
      },
    },
  },
}
