local original_spawnmenu_AddContentType = spawnmenu.AddContentType
local icon_egs = 'icon16/egs.png'
local icon_prop_launcher = 'icon16/prop_launcher.png'

local egs_entity_type = {
	['entity'] = 0,
	['vehicle'] = 1,
	['npc'] = 2,
	['weapon'] = 3,
	['model'] = 4,
}

local lang = slib.language({
	['default'] = {
		['title'] = 'Spawn Group using EGS',
		['prop_launcher'] = 'Load into Prop Launcher',
	},
	['russian'] = {
		['title'] = 'Создать группу с помощью EGS',
		['prop_launcher'] = 'Снярядить в Prop Launcher',
	}
})

function spawnmenu.AddContentType(name, constructor)
	local debug_info = debug.getinfo(2, 'S')

	if debug_info and debug_info.short_src == 'lua/weapons/gmod_tool/stools/egs.lua' then
		return
	end

	return original_spawnmenu_AddContentType(name, constructor)
end

local function CheckInstalledPropLauncher()
	return slib.GetAddon('491910658')
		or file.Exists('addons/prop_launcher_(launch_any_prop)_491910658', 'GAME')
		or file.Exists('addons/ds_491910658.gma', 'GAME')
		or file.Exists('weapons/prop_launcher.lua', 'LUA')
end

hook.Add('slib.PostSpawnmenuAddContentType', 'EntityGroupSpawnerFixer',
function(name, icon, container, obj)
	if not slib.GetAddon('951638840') then return end

	local egs_ent_type = egs_entity_type[name]
	if not isnumber(egs_ent_type) then return end

	local BASE_OpenMenu = icon.OpenMenu
	local BASE_OpenMenuExtra = icon.OpenMenuExtra

	icon.OpenMenuExtra = function(self, menu)
		if isfunction(BASE_OpenMenuExtra) then
			BASE_OpenMenuExtra(self, menu)
		end

		menu:AddOption(lang['title'], function()
			RunConsoleCommand('gmod_tool', 'egs')
			RunConsoleCommand('egs_spawnmenu_incompatible', '0')
			RunConsoleCommand('egs_ent_type', egs_ent_type)

			if egs_ent_type == 0 or egs_ent_type == 1 or egs_ent_type == 3 then
				RunConsoleCommand('egs_ent_name',  obj.spawnname)
			elseif egs_ent_type == 2 then
				local weapons_list = obj.weapon or {}
				local weapon_class = table.Random(weapons_list) or ''

				local gmod_npcweapon = GetConVar('gmod_npcweapon'):GetString()
				if gmod_npcweapon ~= '' then
					weapon_class = gmod_npcweapon
				end

				RunConsoleCommand('egs_ent_name',  obj.spawnname)
				RunConsoleCommand('egs_ent_weapon', weapon_class)
			elseif egs_ent_type == 4 then
				RunConsoleCommand('egs_ent_name',  obj.model)
			end
		end):SetImage(icon_egs)

		if egs_ent_type == 4 and CheckInstalledPropLauncher() then
			menu:AddOption(lang['prop_launcher'], function()
				RunConsoleCommand('pl_model', obj.model)
				RunConsoleCommand('give', 'prop_launcher')
				RunConsoleCommand('use', 'prop_launcher')
			end):SetImage(icon_prop_launcher)
		end
	end

	if egs_ent_type == 4 then
		icon.OpenMenu = function(self)
			local hook_id = slib.UUID()
			hook.Add('slib.CreateDermaMenu', hook_id, function(menu)
				hook.Remove('slib.CreateDermaMenu', hook_id)
				if isfunction(self.OpenMenuExtra) then
					self:OpenMenuExtra(menu)
				end
			end)

			BASE_OpenMenu(self)
			hook.Remove('slib.CreateDermaMenu', hook_id)
		end
	end
end)