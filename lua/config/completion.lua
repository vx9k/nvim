-- Built-in completion, replacing blink.cmp.
--
-- Insert mode: 'autocomplete' opens the menu as you type, pulling from the
-- LSP omnifunc first ("o") and then buffer words. Accepting with <C-y> (or
-- <Tab>, below) applies LSP side effects: snippets via |vim.snippet|,
-- additional text edits, commands. See |ins-autocompletion|, |lsp-completion|.
--
-- Command line: menu as you type via wildtrigger(). See
-- |cmdline-autocompletion|.

vim.o.autocomplete = true
vim.o.complete = "o,.^10,w^5,b^5,u^5"
-- No "fuzzy": it re-ranks LSP results case-insensitively, so "pri" in C
-- offers PRId8 before printf.
vim.o.completeopt = "menuone,noselect,popup"
vim.o.pumheight = 12

-- super-tab: <Tab> accepts (the first item if none is selected), then jumps
-- through snippet placeholders, then falls back to a literal tab.
vim.keymap.set("i", "<Tab>", function()
	if vim.fn.pumvisible() == 1 then
		return vim.fn.complete_info({ "selected" }).selected == -1 and "<C-n><C-y>"
			or "<C-y>"
	elseif vim.snippet.active({ direction = 1 }) then
		return "<Cmd>lua vim.snippet.jump(1)<CR>"
	end
	return "<Tab>"
end, { expr = true, desc = "Accept completion / next snippet field" })

vim.keymap.set("i", "<S-Tab>", function()
	if vim.fn.pumvisible() == 1 then return "<C-p>" end
	if vim.snippet.active({ direction = -1 }) then
		return "<Cmd>lua vim.snippet.jump(-1)<CR>"
	end
	return "<S-Tab>"
end, { expr = true, desc = "Previous item / previous snippet field" })

vim.keymap.set(
	"i",
	"<C-Space>",
	function() vim.lsp.completion.get() end,
	{ desc = "Trigger LSP completion" }
)

local group = vim.api.nvim_create_augroup("config.completion", {})

vim.api.nvim_create_autocmd("LspAttach", {
	group = group,
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client then return end

		if client:supports_method("textDocument/completion") then
			-- autotrigger covers trigger characters such as "." and "->",
			-- which 'autocomplete' does not open the menu for.
			vim.lsp.completion.enable(true, client.id, ev.buf, {
				autotrigger = true,
			})
		end

		-- Show signature help automatically on the server's trigger
		-- characters, usually "(" and ",".
		local sig = client.server_capabilities.signatureHelpProvider
		local triggers = sig and sig.triggerCharacters
		if triggers and #triggers > 0 then
			vim.api.nvim_create_autocmd("InsertCharPre", {
				group = group,
				buffer = ev.buf,
				callback = function()
					if vim.list_contains(triggers, vim.v.char) then
						vim.schedule(
							function()
								vim.lsp.buf.signature_help({
									focusable = false,
									silent = true,
								})
							end
						)
					end
				end,
			})
		end
	end,
})

vim.o.wildmode = "noselect:lastused,full"
vim.api.nvim_create_autocmd("CmdlineChanged", {
	group = group,
	pattern = { ":", "/", "?" },
	callback = function() vim.fn.wildtrigger() end,
})
vim.keymap.set(
	"c",
	"<Up>",
	function() return vim.fn.wildmenumode() == 1 and "<C-e><Up>" or "<Up>" end,
	{ expr = true }
)
vim.keymap.set(
	"c",
	"<Down>",
	function() return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>" end,
	{ expr = true }
)
