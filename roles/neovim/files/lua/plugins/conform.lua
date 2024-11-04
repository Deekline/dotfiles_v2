local m = require("util").lazy_map
local c = require("util").create_cmd
local eslint_config_path = "/Users/myemets/.nvm/versions/node/v18.9.1/lib/node_modules/@core/vue-cli/.eslintrc.js"

local opts = {
	formatters_by_ft = {
		css = { "prettierd" },
		html = { "prettierd" },
		javascript = { "esling_d", "prettierd" },
		json = { "prettierd" },
		jsonc = { "prettierd" },
		lua = { "stylua" },
		scss = { "prettierd" },
		typescript = { "eslint_d", "prettierd" },
		vue = { "eslint_d" },
		sh = { "shfmt", "shellharden" },
		bash = { "shfmt", "shellharden" },
		markdown = { "cbfmt", "prettierd", "markdownlint" },
	},
	format_on_save = function(bufnr)
		---@diagnostic disable-next-line: undefined-field
		if vim.b[bufnr].disable_autoformat or vim.g.disable_autoformat then
			return
		end
		print(vim.fn.expand("%:p"))
		return { timeout_ms = 500, lsp_fallback = true }
	end,
	notify_on_error = false,
	formatters = {
		shfmt = {
			prepend_args = { "-i", "2" },
		},
		shellharden = {
			prepend_args = { "--transform" },
		},
		cbfmt = {
			prepend_args = { "--config", os.getenv("HOME") .. "/.config/cbfmt/cbfmt.toml" },
		},
		eslint_d = {
			cmd = "eslint_d",
			args = {
				"--stdin",
				"--fix-to-stdout",
				vim.fn.expand("%:p"), -- Full path of the current file
				"--config",
				eslint_config_path,
				"--fix", -- Add --fix option to automatically fix issues
			},
			stdin = true,
		},
	},
}

local function init()
	local function get_level(args)
		return args.bang and "g" or "b"
	end
	local function notify(args)
		local level = get_level(args)
		require("notify").notify(
			string.format(
				"Auto formatting %s %s",
				vim[level].disable_autoformat and "enabled" or "disabled",
				level == "b" and string.format("for buffer id: %s", vim.api.nvim_get_current_buf()) or "globally"
			),
			vim.log.levels.info,
			---@diagnostic disable-next-line: missing-fields
			{
				title = "conform.nvim formatting",
			}
		)
	end
	c("ConformFormatToggle", function(args)
		notify(args)
		local level = get_level(args)
		vim[level].disable_autoformat = not vim[level].disable_autoformat
	end, {
		bang = true,
	})
end

return {
	"stevearc/conform.nvim",
	lazy = false,
	event = { "BufWritePre" },
	opts = opts,
	cmd = { "ConformInfo" },
	keys = {
		m("<leader>ci", [[ConformInfo]]),
	},
	init = init,
}
