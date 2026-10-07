--!strict
-- Funciones para mostrar números bonitos, por ejemplo 12500 -> "$12,500".

local Format = {}

function Format.money(amount: number): string
	local digits = tostring(math.floor(amount))
	local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return "$" .. formatted
end

return Format
