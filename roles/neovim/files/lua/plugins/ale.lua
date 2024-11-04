return {
	"dense-analysis/ale",
	lazy = false,
	config = function()
		-- Configuration goes here.
		local g = vim.g

		g.ale_ruby_rubocop_auto_correct_all = 1

		g.ale_linters = {
			lua = { "lua_language_server" },
			vue = { "volar", "eslint" },
		}

		g.ale_javascript_eslint_executable = "eslint_d" -- or 'eslint' if you prefer using ESLint directly
		g.ale_javascript_eslint_options =
			"--stdin --stdin-filename %s --format json --config /Users/myemets/.nvm/versions/node/v18.9.1/lib/node_modules/@core/vue-cli/.eslintrc.js"
		-- Automatically fix issues on save
		g.ale_fix_on_save = 1

		-- Define ALE linters by filetype
		vim.cmd([[
      autocmd BufEnter *.vue let b:ale_linters = ['eslint', 'volar']
    ]])

		-- Enable ALE globally
		vim.cmd("ALEEnable")
	end,
}
