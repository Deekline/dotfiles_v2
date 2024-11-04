local opts = {
	ensure_installed = {
		"angularls",
		"bashls",
		"clangd",
		"cssls",
		"cssmodules_ls",
		"diagnosticls",
		"docker_compose_language_service",
		"dockerls",
		"emmet_ls",
		"eslint",
		"html",
		"jsonls",
		"lua_ls",
		"marksman",
		"powershell_es",
		"sqlls",
		"tailwindcss",
		"tsserver",
		"volar",
		"vuels",
		"yamlls",
	},
	automatic_installation = true,
}

return {
	"williamboman/mason-lspconfig.nvim",
	opts = opts,
	event = "BufReadPre",
	dependencies = "williamboman/mason.nvim",
}
