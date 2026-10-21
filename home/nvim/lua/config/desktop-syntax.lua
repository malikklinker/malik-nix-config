-- One semantic vocabulary for legacy syntax, Tree-sitter, and LSP tokens.
local M = {}

function M.highlights(theme)
	local p, c = theme.palette, theme.colors
	local colors = {
		text = c.text,
		punctuation = c.subtext,
		comment = c.muted,
		keyword = p.base0E,
		func = p.base0D,
		type = p.base0A,
		constant = p.base09,
		string = p.base0B,
		special = p.base0C,
	}
	if theme.slug == "midnight-blue" then
		colors.keyword = c.accent
		colors.func = c.accent
		colors.type = c.secondary
		colors.constant = c.secondary
		colors.string = c.cyan
		colors.special = c.secondary
	end

	local groups = {
		text = {
			"Identifier",
			"Ignore",
			"@variable",
			"@variable.parameter",
			"@variable.member",
			"@property",
			"@module",
			"@lsp.type.variable",
			"@lsp.type.parameter",
			"@lsp.type.property",
			"@lsp.type.namespace",
			"@lsp.type.event",
			"@markup",
			"@markup.list",
			"@markup.list.unchecked",
		},
		punctuation = {
			"Delimiter",
			"Operator",
			"@operator",
			"@punctuation",
			"@punctuation.delimiter",
			"@punctuation.bracket",
			"@tag.delimiter",
			"@lsp.type.operator",
		},
		comment = {
			"Comment",
			"SpecialComment",
			"@comment",
			"@comment.documentation",
			"@lsp.type.comment",
			"@markup.quote",
		},
		keyword = {
			"Statement",
			"Conditional",
			"Repeat",
			"Label",
			"Keyword",
			"Exception",
			"Debug",
			"PreCondit",
			"@keyword",
			"@keyword.coroutine",
			"@keyword.function",
			"@keyword.operator",
			"@keyword.import",
			"@keyword.type",
			"@keyword.modifier",
			"@keyword.repeat",
			"@keyword.return",
			"@keyword.debug",
			"@keyword.exception",
			"@keyword.conditional",
			"@keyword.conditional.ternary",
			"@label",
			"@lsp.type.keyword",
			"@lsp.type.modifier",
		},
		func = {
			"Function",
			"Include",
			"@function",
			"@function.builtin",
			"@function.call",
			"@function.method",
			"@function.method.call",
			"@constructor",
			"@lsp.type.function",
			"@lsp.type.method",
			"@markup.heading",
		},
		type = {
			"Type",
			"StorageClass",
			"Structure",
			"Typedef",
			"@type",
			"@type.builtin",
			"@type.definition",
			"@attribute",
			"@attribute.builtin",
			"@tag",
			"@tag.builtin",
			"@lsp.type.type",
			"@lsp.type.typeParameter",
			"@lsp.type.class",
			"@lsp.type.enum",
			"@lsp.type.interface",
			"@lsp.type.struct",
			"@lsp.type.decorator",
		},
		constant = {
			"Constant",
			"Number",
			"Integer",
			"Float",
			"Boolean",
			"Define",
			"Macro",
			"PreProc",
			"Tag",
			"@constant",
			"@constant.builtin",
			"@constant.macro",
			"@boolean",
			"@number",
			"@number.float",
			"@variable.builtin",
			"@variable.parameter.builtin",
			"@module.builtin",
			"@symbol",
			"@tag.attribute",
			"@function.macro",
			"@keyword.directive",
			"@keyword.directive.define",
			"@lsp.type.enumMember",
			"@lsp.type.macro",
			"@lsp.type.number",
			"@lsp.type.boolean",
			"@lsp.mod.readonly",
		},
		string = {
			"String",
			"Character",
			"@string",
			"@string.documentation",
			"@string.regexp",
			"@string.special",
			"@string.special.path",
			"@string.special.url",
			"@character",
			"@lsp.type.string",
			"@lsp.type.regexp",
			"@markup.raw",
			"@markup.raw.block",
			"@markup.math",
		},
		special = {
			"Special",
			"SpecialChar",
			"@string.escape",
			"@string.special.symbol",
			"@character.special",
			"@punctuation.special",
			"@markup.link",
			"@markup.link.label",
		},
	}
	local highlights = {}
	for role, names in pairs(groups) do
		for _, name in ipairs(names) do
			highlights[name] = { fg = colors[role] }
		end
	end
	for level = 1, 6 do
		highlights["markdownH" .. level] = { fg = colors.func, bold = true }
		highlights["@markup.heading." .. level] = { link = "markdownH" .. level }
	end
	highlights["@markup.link.url"] = { fg = colors.string, underline = true }
	highlights["@markup.strong"] = { bold = true }
	highlights["@markup.italic"] = { italic = true }
	highlights["@markup.strikethrough"] = { strikethrough = true }
	highlights["@markup.underline"] = { underline = true }
	-- Semantic modifiers add emphasis without repainting the token's syntax role.
	highlights["@lsp.mod.deprecated"] = { strikethrough = true }
	highlights["@lsp.mod.documentation"] = { italic = true }
	for group, target in pairs({
		["@comment.error"] = "DiagnosticError",
		["@comment.warning"] = "DiagnosticWarn",
		["@comment.todo"] = "Todo",
		["@comment.note"] = "DiagnosticInfo",
		["@diff.plus"] = "Added",
		["@diff.minus"] = "Removed",
		["@diff.delta"] = "Changed",
		["@markup.list.checked"] = "DiagnosticOk",
	}) do
		highlights[group] = { link = target }
	end
	highlights.Todo = { fg = c.accent, bg = c.surface, bold = true }
	return highlights
end

return M
