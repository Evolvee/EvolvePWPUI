local version = 2
if humfras_tools and humfras_tools.version >= version then return end

local type = type;
local error = error;
local geterrorhandler = geterrorhandler;
local issecure = issecure;
local forceinsecure = forceinsecure;
local securecall = securecall;
local setmetatable = setmetatable;
local getmetatable = getmetatable;
local tostring = tostring;
local rawget = rawget;
local next = next;
local unpack = unpack;
local pairs = pairs;
local ipairs = ipairs;
local newproxy = newproxy;
local select = select;
local wipe = wipe;
local tonumber = tonumber;
local pcall = pcall;
 
local t_insert = table.insert;
local t_maxn = table.maxn;
local t_concat = table.concat;
local t_sort = table.sort;
local t_remove = table.remove;
 
local s_gsub = string.gsub;
 
local InCombatLockdown = InCombatLockdown;
 
---------------------------------------------------------------------------
-- PRINT
-- Taken from WoW 4.3 - RestrictedInfrastrucure.lua (Part of the Secure Handlers implementation)
-- Written by:
--  Daniel Stephens (iriel@vigilance-committee.org)
--  Nevin Flanagan (alestane@comcast.net)
--
--
-- Somewhat extensible print infrastructure for debugging, modelled around
-- error handler code.
--
-- setprinthandler(func) -- Sets the active print handler
-- func = getprinthandler() -- Gets the current print handler
-- print(...) -- Passes its arguments to the current print handler
--
-- The default print handler simply strjoin's its arguments with a " "
-- delimiter and adds it to DEFAULT_CHAT_FRAME
 
local LOCAL_ToStringAllTemp = {};
function tostringall(...)
    local n = select('#', ...);
    -- Simple versions for common argument counts
    if (n == 1) then
        return tostring(...);
    elseif (n == 2) then
        local a, b = ...;
        return tostring(a), tostring(b);
    elseif (n == 3) then
        local a, b, c = ...;
        return tostring(a), tostring(b), tostring(c);
    elseif (n == 0) then
        return;
    end
 
    local needfix;
    for i = 1, n do
        local v = select(i, ...);
        if (type(v) ~= "string") then
            needfix = i;
            break;
        end
    end
    if (not needfix) then return ...; end
 
    LOCAL_ToStringAllTemp = {}	--wipe(LOCAL_ToStringAllTemp);
    for i = 1, needfix - 1 do
        LOCAL_ToStringAllTemp[i] = select(i, ...);
    end
    for i = needfix, n do
        LOCAL_ToStringAllTemp[i] = tostring(select(i, ...));
    end
    return unpack(LOCAL_ToStringAllTemp);
end
 
local LOCAL_PrintHandler =
    function(...)
        DEFAULT_CHAT_FRAME:AddMessage(strjoin(" ", tostringall(...)));
    end
 
function setprinthandler(func)
    if (type(func) ~= "function") then
        error("Invalid print handler");
    else
        LOCAL_PrintHandler = func;
    end
end
 
function getprinthandler() return LOCAL_PrintHandler; end
 
local function print_inner(...)
    --forceinsecure();
    local ok, err = pcall(LOCAL_PrintHandler, ...);
    if (not ok) then
        local func = geterrorhandler();
        func(err);
    end
end
 
function print(...)
    securecall(print_inner, ...);
end


---------------------------------------------------------------------------
-- pairsByKeys
-- sorts and returns table values alphabetically

function pairsByKeys(t, f)
	local a = {}
		for n in pairs(t) do table.insert(a, n) end
		table.sort(a, f)
		local i = 0      -- iterator variable
		local iter = function ()   -- iterator function
			i = i + 1
			if a[i] == nil then return nil
			else return a[i], t[a[i]]
			end
		end
	return iter
end



-- END
humfras_tools = {
	version = version
}