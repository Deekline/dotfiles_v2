local km, l, api = vim.keymap.set, vim.lsp, vim.api

local config = function()
	local lspconfig = require("lspconfig")
	local vt = require("virtualtypes")

	--- Capabilities
	local capabilities = vim.tbl_deep_extend(
		"force",
		vim.lsp.protocol.make_client_capabilities(),
		require("cmp_nvim_lsp").default_capabilities()
	)
	-- ufo
	capabilities.textDocument.foldingRange = {
		dynamicRegistration = false,
		lineFoldingOnly = true,
	}
	---@diagnostic disable-next-line: inject-field
	capabilities.offsetEncoding = { "utf-16" }
	-- snippets
	local _snippet_capabilities = l.protocol.make_client_capabilities()
	---@diagnostic disable-next-line: inject-field
	_snippet_capabilities.textDocument.completion.completionItem.snippetSupport = true
	local snippet_capabilities = vim.tbl_extend("keep", capabilities, _snippet_capabilities)

	-- Diagnostic
	vim.diagnostic.config({
		virtual_text = true,
		virtual_lines = {
			only_current_line = true,
		},
		update_in_insert = false,
		underline = true,
		severity_sort = true,
		float = {
			focusable = true,
			border = "rounded",
			header = "",
			prefix = "",
		},
	})

	---@diagnostic disable-next-line: duplicate-set-field
	vim.lsp.handlers["textDocument/hover"] = function(_, result, ctx, config)
		if not (result and result.contents) then
			return
		end
		config = config or {}
		config.border = "rounded"
		l.handlers.hover(_, result, ctx, config)
	end
	l.handlers["textDocument/signatureHelp"] = l.with(l.handlers.signature_help, {
		border = "rounded",
	})
	---@diagnostic disable-next-line: duplicate-set-field
	l.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
		local ts_lsp = { "tsserver", "angularls", "volar" }
		local clients = l.get_clients({ id = ctx.client_id })
		if vim.tbl_contains(ts_lsp, clients[1].name) then
			local filtered_result = {
				diagnostics = vim.tbl_filter(function(d)
					return d.severity == 1
				end, result.diagnostics),
			}
			require("ts-error-translator").translate_diagnostics(err, filtered_result, ctx, config)
		end
		vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
	end

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("UserLspConfig", {}),
		callback = function(event)
			local bufopts = { noremap = true, silent = true, buffer = event.bufnr }
			km("n", "[g", function()
				vim.cmd("DiagnosticsErrorJumpPrev")
			end, bufopts)
			km("n", "]g", function()
				vim.cmd("DiagnosticsErrorJumpNext")
			end, bufopts)
			km("n", "[G", function()
				vim.cmd("DiagnosticsJumpPrev")
			end, bufopts)
			km("n", "]G", function()
				vim.cmd("DiagnosticsJumpNext")
			end, bufopts)
			km("n", "<leader>dd", vim.diagnostic.setqflist, bufopts)
			km("n", "gD", l.buf.declaration, bufopts)
			if not require("neoconf").get("lsp.keys.goto_definition.disable") then
				km("n", "gd", l.buf.definition, bufopts)
			end
			km("n", "gi", l.buf.implementation, bufopts)
			km("n", "<leader>D", l.buf.type_definition, bufopts)
			km("n", "gr", l.buf.references, bufopts)
			km({ "n", "v" }, "<leader>ca", l.buf.code_action, bufopts)
			km("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
			km("n", "L", vim.lsp.buf.hover, bufopts)
		end,
	})

	-- on_attach definitions
	local virtual_types_on_attach = function(client, bufnr)
		if client.server_capabilities.textDocument then
			if client.server_capabilities.textDocument.codeLens then
				vt.on_attach(client, bufnr)
			end
		end
	end
	local on_attach = function(client, bufnr)
		virtual_types_on_attach(client, bufnr)
	end

	-- LSP config

	local ts_ft = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }
	local util = require("lspconfig.util")
	local vue_ft = { unpack(ts_ft) }
	table.insert(vue_ft, "vue")
	local css_ft = { "css", "scss", "less", "sass", "vue" }
	local function tsdk(root_dir)
		local global_ts = "/Users/myemets/.nvm/versions/node/v18.9.1/lib/node_modules/typescript/lib"
		local found_ts = ""
		found_ts = util.path.join(root_dir, "node_modules", "typescript", "lib")
		if util.path.exists(found_ts) then
			return found_ts
		else
			return global_ts
		end
	end

	local server_enabled = function(server)
		return not require("neoconf").get("lsp.servers." .. server .. ".disable")
	end

	local lspconfig_setups = {
		language_servers = {
			"bashls",
			"docker_compose_language_service",
			"dockerls",
			"marksman",
			"sqlls",
			"yamlls",
			"volar",
			--"vuels",
		},
		tailwindcss = {
			root_dir = function(fname)
				local root_pattern = lspconfig.util.root_pattern("tailwind.config.js", "tailwind.config.ts")
				return root_pattern(fname)
			end,
		},
		cssls = {
			capabilities = snippet_capabilities,
			filetypes = css_ft,
			settings = {
				css = { validate = true, lint = {
					unknownAtRules = "ignore",
				} },
				scss = { validate = true, lint = {
					unknownAtRules = "ignore",
				} },
				less = { validate = true, lint = {
					unknownAtRules = "ignore",
				} },
			},
		},
		html = {
			capabilities = snippet_capabilities,
			filetypes = { "html", "vue" },
		},
		cssmodules_ls = {
			filetypes = vue_ft,
		},
		tsserver = {
			filetypes = ts_ft,
			root_dir = require("lspconfig/util").root_pattern(
				"/Users/myemets/dotfiles/.config/nvim/compiler/tsconfig.json",
				"jsconfig.json",
				"package.json",
				".git"
			),
			init_options = {
				tsconfigPath = "/Users/myemets/dotfiles/.config/nvim/compiler/tsconfig.json",
				plugins = {
					{
						name = "@vue/typescript-plugin",
						location = "/Users/myemets/.local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server/node_modules/@vue/typescript-plugin",
						languages = { "vue" },
					},
				},
				typescript = {
					tsdk = tsdk(),
				},
			},
			settings = {
				tsserver = {
					configFile = "/Users/myemets/dotfiles/.config/nvim/compiler/tsconfig.json",
				},
			},
		},
		volar = {
			cmd = { "vue-language-server", "--stdio" },
			filetypes = vue_ft,
			root_dir = util.root_pattern("package.json"),
			init_options = {
				vue = {
					hybridMode = true,
				},
				on_new_config = function(new_config, new_root_dir)
					if
						new_config.init_options
						and new_config.init_options.typescript
						and new_config.init_options.typescript.tsdk == ""
					then
						new_config.init_options.typescript.tsdk = tsdk(new_root_dir)
					end
				end,
			},
		},
		jsonls = {
			capabilities = snippet_capabilities,
			settings = {
				json = {
					schemas = require("schemastore").json.schemas({
						select = {
							"package.json",
							".eslintrc",
							"tsconfig.json",
						},
					}),
					validate = { enable = true },
				},
			},
		},
		vimls = {
			diagnostic = { enable = true },
			indexes = {
				count = 3,
				gap = 100,
				projectRootPatterns = { "runtime", "nvim", ".git", "autoload", "plugin" },
				runtimepath = true,
			},
			isNeovim = true,
			iskeyword = "@,48-57,_,192-255,-#",
			runtimepath = "",
			suggest = { fromRuntimepath = true, fromVimruntime = true },
			vimruntime = "",
		},
		lua_ls = {
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim", "require" },
					},
					workspace = {
						library = api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
					telemetry = { enable = false },
					hint = {
						enable = true,
					},
				},
			},
		},
		angularls = {
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)
				client.server_capabilities.renameProvider = false
			end,
		},
	}

	for srv, cfg in pairs(lspconfig_setups) do
		if srv == "language_servers" then
			for _, ls in ipairs(cfg) do
				lspconfig[ls].setup({
					capabilities = capabilities,
					on_attach = on_attach,
				})
			end
		elseif server_enabled(srv) then
			if not cfg.on_attach then
				cfg.on_attach = on_attach
			end
			if not cfg.capabilities then
				cfg.capabilities = capabilities
			end
			lspconfig[srv].setup(cfg)
		end
	end

	if server_enabled("diagnosticls") then
		lspconfig.diagnosticls.setup({
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				local stop_ft = {
					"dap-repl",
				}
				for _, ft in pairs(stop_ft) do
					if vim.bo.filetype == ft then
						if l.buf_is_attached(bufnr, client.id) then
							local notify = vim.notify
							---@diagnostic disable-next-line: duplicate-set-field
							vim.notify = function() end
							l.buf_detach_client(bufnr, client.id)
							vim.notify = notify
						end
					end
				end
				on_attach(client, bufnr)
			end,
		})
	end
end

return {
	"neovim/nvim-lspconfig",
	init = function()
		require("neoconf").setup({})
	end,
	config = config,
	dependencies = {
		"windwp/nvim-autopairs",
		{
			"williamboman/mason-lspconfig.nvim",
			dependencies = "williamboman/mason.nvim",
		},
		"b0o/schemastore.nvim",
		"kevinhwang91/nvim-ufo",
		"VidocqH/lsp-lens.nvim",
		"jubnzv/virtual-types.nvim",
		"folke/neoconf.nvim",
		{
			"dmmulroy/ts-error-translator.nvim",
			config = true,
			ft = { "typescript", "typescriptreact", "javascript", "javascriptreact", "vue" },
		},
	},
}
