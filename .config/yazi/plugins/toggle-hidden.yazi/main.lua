--- @since 26.5.6

local toggle = ya.sync(function()
	local pref = cx.active.pref
	pref.show_hidden = not pref.show_hidden
	ya.notify({
		title = "Yazi",
		content = pref.show_hidden and "Showing hidden files" or "Hiding hidden files",
		timeout = 2,
	})
end)

return {
	entry = function()
		toggle()
	end,
}
