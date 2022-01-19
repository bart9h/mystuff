vim.cmd [[packadd packer.nvim]]
return require('packer').startup(function()
	use 'elihunter173/dirbuf.nvim'
	use 'tpope/vim-fugitive'
	use {
		'lewis6991/gitsigns.nvim',
		requires = {
			'nvim-lua/plenary.nvim'
		},
		config = function()
			require('gitsigns').setup()
		end
	}
	use 'morhetz/gruvbox'
	use 'wbthomason/packer.nvim'
end)
