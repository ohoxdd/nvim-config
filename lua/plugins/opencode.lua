-- lua/plugins/opencode.lua
--
-- OpenCode integration — opens the `opencode` CLI in a floating terminal.
-- Machine-agnostic: gracefully skips if `opencode` is not on PATH.
-- Toggle with <leader>oc  (or whatever you remap OPENCODE_KEY to below).

local OPENCODE_KEY  = "<leader>oc"
local OPENCODE_CMD  = "opencode"          -- name/path of the binary
local FLOAT_WIDTH   = 0.85               -- fraction of editor width
local FLOAT_HEIGHT  = 0.85               -- fraction of editor height

-- We don't depend on any third-party plugin; this uses only nvim built-ins.
return {
    -- A minimal "plugin" entry so lazy.nvim tracks it cleanly.
    -- dir = "." tells lazy this is a local (no-download) spec.
    dir  = vim.fn.stdpath("config"),
    name = "opencode-integration",
    lazy = false,
    config = function()
        -- ── Availability check ────────────────────────────────────────────────
        if vim.fn.executable(OPENCODE_CMD) == 0 then
            vim.notify(
                ("opencode: '%s' not found on PATH — integration disabled.\n"
                 .. "Install from https://opencode.ai then restart nvim."):format(OPENCODE_CMD),
                vim.log.levels.WARN,
                { title = "OpenCode" }
            )
            return
        end

        -- ── Floating terminal helpers ─────────────────────────────────────────
        local state = { buf = nil, win = nil }

        local function float_dimensions()
            local lines = vim.o.lines
            local cols  = vim.o.columns
            local h = math.floor(lines  * FLOAT_HEIGHT)
            local w = math.floor(cols   * FLOAT_WIDTH)
            local r = math.floor((lines - h) / 2)
            local c = math.floor((cols  - w) / 2)
            return { height = h, width = w, row = r, col = c }
        end

        local function open_float()
            local d = float_dimensions()

            -- Reuse buffer if it still exists
            if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
                state.win = vim.api.nvim_open_win(state.buf, true, {
                    relative = "editor",
                    style    = "minimal",
                    border   = "rounded",
                    width    = d.width,
                    height   = d.height,
                    row      = d.row,
                    col      = d.col,
                    title    = " OpenCode ",
                    title_pos = "center",
                })
                -- Resume terminal mode
                vim.cmd("startinsert")
                return
            end

            -- Create fresh buffer + terminal
            state.buf = vim.api.nvim_create_buf(false, true)
            state.win = vim.api.nvim_open_win(state.buf, true, {
                relative  = "editor",
                style     = "minimal",
                border    = "rounded",
                width     = d.width,
                height    = d.height,
                row       = d.row,
                col       = d.col,
                title     = " OpenCode ",
                title_pos = "center",
            })

            vim.fn.termopen(OPENCODE_CMD, {
                on_exit = function()
                    -- Clean up so next open starts fresh
                    if state.win and vim.api.nvim_win_is_valid(state.win) then
                        vim.api.nvim_win_close(state.win, true)
                    end
                    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
                        vim.api.nvim_buf_delete(state.buf, { force = true })
                    end
                    state.buf = nil
                    state.win = nil
                end,
            })
            vim.cmd("startinsert")
        end

        local function close_float()
            if state.win and vim.api.nvim_win_is_valid(state.win) then
                vim.api.nvim_win_close(state.win, false)
                state.win = nil
            end
        end

        local function toggle()
            if state.win and vim.api.nvim_win_is_valid(state.win) then
                close_float()
            else
                open_float()
            end
        end

        -- ── Keymaps ───────────────────────────────────────────────────────────
        vim.keymap.set("n", OPENCODE_KEY, toggle,
            { noremap = true, silent = true, desc = "Toggle OpenCode" })

        -- <Esc><Esc> inside the float closes it without killing the session
        vim.keymap.set("t", "<Esc><Esc>", function()
            if state.win and vim.api.nvim_win_is_valid(state.win) then
                close_float()
            else
                -- Normal escape passthrough in other terminals
                vim.api.nvim_feedkeys(
                    vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
                    "n", false
                )
            end
        end, { noremap = true, silent = true, desc = "Close OpenCode float" })

        -- ── Auto-resize on VimResized ─────────────────────────────────────────
        vim.api.nvim_create_autocmd("VimResized", {
            callback = function()
                if state.win and vim.api.nvim_win_is_valid(state.win) then
                    local d = float_dimensions()
                    vim.api.nvim_win_set_config(state.win, {
                        relative = "editor",
                        width    = d.width,
                        height   = d.height,
                        row      = d.row,
                        col      = d.col,
                    })
                end
            end,
        })
    end,
}
