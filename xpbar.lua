--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
*
* -------------------------------------------
* Images credited to windower addon barfiller
* -------------------------------------------
]]--

_addon.author   = 'spkywt';
_addon.name     = 'xpbar';
_addon.version  = '1.0.0';

-- Ashita Libs
require 'common'
require 'd3d8';

-- Addon Specific Files
require 'helpers'

----------------------------------------------------------------------------------------------------
-- Config - Editable, but may not look great.
----------------------------------------------------------------------------------------------------
barwidth						=	472;
barheight						=	5;

----------------------------------------------------------------------------------------------------
-- Local Variables -- Do not edit below this point.
----------------------------------------------------------------------------------------------------
local player					=	AshitaCore:GetDataManager():GetPlayer();
local JobMaskInverted			=	table_invert(JobMask);
local ExpCurrent				=	0;
local variables 				=
{
	['var_ShowXpBar']			=	{ nil, ImGuiVar_BOOLCPP, true }
};

----------------------------------------------------------------------------------------------------
-- Create Textures from Images
----------------------------------------------------------------------------------------------------
local hres, imgBarBg = ashita.d3dx.CreateTextureFromFileA(_addon.path .. '\\images\\bar_bg.png');
if (hres ~= 0) then echo('Error loading file.'); end
local hres, imgBarFg = ashita.d3dx.CreateTextureFromFileA(_addon.path .. '\\images\\bar_fg.png');
if (hres ~= 0) then echo('Error loading file.'); end

----------------------------------------------------------------------------------------------------
-- func: ShowBottomBar
-- desc: Shows storage summary window.
----------------------------------------------------------------------------------------------------
local function ShowXpBar()
	local Window_Flags	=	ImGuiWindowFlags_NoTitleBar + ImGuiWindowFlags_NoResize;
							
	imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 0);
	imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, 0, 0);
	imgui.PushStyleVar(ImGuiStyleVar_ChildWindowRounding, 0);
	imgui.PushStyleColor(ImGuiCol_WindowBg, 0, 0, 0, 0);
	imgui.SetNextWindowSize(barwidth, barheight + 20, ImGuiSetCond_Always);
	imgui.SetNextWindowPos((imgui.io.DisplaySize.x - barwidth) / 2, imgui.io.DisplaySize.y - 25, ImGuiSetCond_FirstUseEver);
	imgui.style.DisplayWindowPadding = ImVec2(barwidth + 16, barheight + 16);
	
	if (imgui.Begin('XpBar', variables['var_ShowXpBar'][1], Window_Flags)) then
		local ExpNeeded = player:GetExpNeeded();
		if (ExpCurrent ~= player:GetExpCurrent()) then
			if (ExpCurrent < player:GetExpCurrent()) then
				ExpCurrent = ExpCurrent + math.ceil((player:GetExpCurrent() - ExpCurrent) * 0.05)
			else
				ExpCurrent = 0;
			end
		end
		
		local MJ = JobMaskInverted[math.pow(2, player:GetMainJob())];
		local MJLv = player:GetMainJobLevel();
		local SJ = JobMaskInverted[math.pow(2, player:GetSubJob())];
		local SJLv = player:GetSubJobLevel();
		local fillwidth = ExpCurrent / ExpNeeded * (barwidth - 4);
		
		imgui.Image(imgBarBg:Get(), barwidth, barheight);
		imgui.SetCursorPos(2,0);
		imgui.Image(imgBarFg:Get(), fillwidth, barheight);
		imgui.SetCursorPos(barwidth / 100, barheight + 1);
		imgui.Text(('Lv.%s   %s/%s   EXP %s/%s'):format(MJLv, MJ, SJ, comma_value(ExpCurrent), comma_value(ExpNeeded)));
    end
	
	imgui.End();
	imgui.PopStyleColor(1);
	imgui.PopStyleVar();
	imgui.PopStyleVar();
	imgui.PopStyleVar();
end

----------------------------------------------------------------------------------------------------
-- func: load
-- desc: Event called when the addon is being loaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- Initialize the custom variables..
    for k, v in pairs(variables) do
        if (v[2] >= ImGuiVar_CDSTRING) then 
            variables[k][1] = imgui.CreateVar(variables[k][2], variables[k][3]);
        else
            variables[k][1] = imgui.CreateVar(variables[k][2]);
        end
        if (#v > 2 and v[2] < ImGuiVar_CDSTRING) then
            imgui.SetVarValue(variables[k][1], variables[k][3]);
        end        
    end
end);

----------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when the addon is unloaded.
----------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
    -- Cleanup the custom variables..
    for k, v in pairs(variables) do
        if (variables[k][1] ~= nil) then
            imgui.DeleteVar(variables[k][1]);
        end
        variables[k][1] = nil;
    end
	
	if (imgBarBg ~= nil ) then imgBarBg:Release(); end
	if (imgBarFg ~= nil ) then imgBarFg:Release(); end
end);

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();
	local echomsg;
	
	-- UI commands
	if (args[1] == '/xpbar') then
		if (args[2] == 'show') then imgui.SetVarValue(variables['var_ShowXpBar' ][1], true);
		elseif (args[2] == 'hide') then imgui.SetVarValue(variables['var_ShowXpBar' ][1], false);
		else echo('commands: show, hide');
		end
	end

    return false;
end);

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
	if (player:GetMainJobLevel() ~= 0) then
		if (imgui.GetVarValue(variables['var_ShowXpBar' ][1])) then ShowXpBar(); end
	end
end);
