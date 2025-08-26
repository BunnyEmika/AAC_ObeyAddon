local api = require("api")

local M = {}

function M.CreateChildLabel(id, parent, text, alignment, font_size, r, g, b, a)
	local label = parent:CreateChildWidget("label", id, 0, true)
	label:SetText(text)
	label.style:SetAlign(alignment)
	label.style:SetFontSize(font_size)
	label.style:SetColor(r, g, b, a)
	return label
end

function M.CreateChildButton(id, parent, text, extent_w, extent_h, skin)
	local btn = parent:CreateChildWidget("button", id, 0, true)
	btn:SetExtent(extent_w, extent_h)
	btn:SetText(text)
	api.Interface:ApplyButtonSkin(btn, skin)
	return btn
end

function M.CreateMultiLineEdit(id, parent, text, extent_w, extent_h, max_text_len)
	local text_edit = W_CTRL.CreateMultiLineEdit(id, parent)
	text_edit:SetExtent(extent_w, extent_h)
	text_edit:SetMaxTextLength(max_text_len)
	text_edit:SetText(text)
	return text_edit
end

return M