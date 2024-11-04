local m = require("util").lazy_map

return {
	{
		"dstein64/vim-startuptime",
		lazy = false,
	},
	{
		"lambdalisue/suda.vim",
		event = "BufReadPre",
	},
	{
		"romainl/vim-cool",
		event = "BufReadPre",
	},
	{
		"famiu/bufdelete.nvim",
		dependencies = "schickling/vim-bufonly",
		cmd = { "BufOnly", "Bdelete" },
	},
	{
		"folke/neoconf.nvim",
		lazy = true,
	},
}
