-- Automatic plugin updates.
--
-- Once per INTERVAL, after the UI is up, a separate headless Nvim runs
-- vim.pack.update() with `force = true` (no confirmation buffer) and then the
-- build hooks. Doing it in another process keeps fetches and parser builds
-- from blocking the editor. When it finishes, the lockfile is compared to
-- report what changed and commit it. `:PackUpdate` runs the same job on
-- demand.
--
-- The child never triggers this itself: headless Nvim has no UIEnter.

local INTERVAL = 24 * 60 * 60 -- seconds

local stamp = vim.fn.stdpath("state") .. "/pack-update-stamp"
local lockfile = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"

local function read_revs()
	local f = io.open(lockfile, "r")
	if not f then return {} end
	local ok, data = pcall(vim.json.decode, f:read("*a"))
	f:close()
	local revs = {}
	for name, p in pairs(ok and data.plugins or {}) do
		revs[name] = p.rev
	end
	return revs
end

-- Commit only the lockfile, leaving anything else in the repo untouched.
local function commit(before, after, changed)
	local cwd = vim.fn.stdpath("config")
	if not vim.uv.fs_stat(cwd .. "/.git") then return end
	local lines = { "chore(pack): update plugins", "" }
	for _, name in ipairs(changed) do
		lines[#lines + 1] = ("- %s: %s -> %s"):format(
			name,
			(before[name] or "new"):sub(1, 8),
			after[name]:sub(1, 8)
		)
	end
	vim.system({
		"git",
		"commit",
		"--quiet",
		"-m",
		table.concat(lines, "\n"),
		"--",
		"nvim-pack-lock.json",
	}, { cwd = cwd, text = true }, function(res)
		if res.code ~= 0 then
			vim.schedule(
				function()
					vim.notify(
						"vim.pack: lockfile commit failed\n" .. res.stderr,
						vim.log.levels.WARN
					)
				end
			)
		end
	end)
end

local running = false

local function run()
	if running then return end
	running = true

	-- Write the stamp first so other Nvim instances don't start a second job.
	local f = io.open(stamp, "w")
	if f then
		f:write(tostring(os.time()))
		f:close()
	end

	local before = read_revs()
	vim.system({
		vim.v.progpath,
		"--headless",
		"-c",
		"lua vim.pack.update(nil, { force = true })",
		"-c",
		"lua require('config.pack').build_pending(true)",
		"-c",
		"qa!",
	}, { text = true }, function(res)
		vim.schedule(function()
			running = false
			if res.code ~= 0 then
				vim.notify(
					"vim.pack: update failed\n" .. (res.stderr or ""),
					vim.log.levels.WARN
				)
				return
			end
			local after, changed = read_revs(), {}
			for name, rev in pairs(after) do
				if before[name] ~= rev then changed[#changed + 1] = name end
			end
			if #changed > 0 then
				table.sort(changed)
				commit(before, after, changed)
				vim.notify(
					("vim.pack: updated %s\n:restart to load them, details in %s"):format(
						table.concat(changed, ", "),
						vim.fn.stdpath("log") .. "/nvim-pack.log"
					)
				)
			end
		end)
	end)
end

vim.api.nvim_create_user_command("PackUpdate", run, {
	desc = "Update plugins in the background",
})

vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		local f = io.open(stamp, "r")
		local last = f and tonumber(f:read("*a")) or 0
		if f then f:close() end
		if os.time() - last >= INTERVAL then vim.defer_fn(run, 3000) end
	end,
})
