-- The Fortran Tree-sitter parser can split identifiers into keyword fragments
-- while recovering from incomplete statements. Use word-based syntax colors
-- while retaining the parser for structural features and fortls for the LSP.
pcall(vim.treesitter.stop, 0)
vim.bo.syntax = "fortran"

-- The built-in indenter handles program units while they are being typed.
-- Enable reindent triggers for their opening/closing keywords, and indent
-- modern DO/END DO loops in free-form source without changing fixed-form code.
vim.b.fortran_indent_more = 1
if vim.b.fortran_fixed_source == 0 then
  vim.b.fortran_do_enddo = 1
end
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "")
  .. " | unlet! b:fortran_indent_more b:fortran_do_enddo"
