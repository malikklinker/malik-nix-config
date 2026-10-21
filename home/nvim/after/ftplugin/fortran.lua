-- The Fortran Tree-sitter parser can split identifiers into keyword fragments
-- while recovering from incomplete statements. Use word-based syntax colors
-- while retaining the parser for structural features and fortls for the LSP.
pcall(vim.treesitter.stop, 0)
vim.bo.syntax = "fortran"
