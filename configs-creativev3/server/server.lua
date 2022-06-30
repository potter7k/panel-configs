RegisterCommand("adminp",function(source,args)
    local user_id = vRP.getUserId(source)
	if vRP.hasPermission(user_id,"Admin") or vRP.hasPermission(user_id,"admin.permissao") then
        TriggerClientEvent("dk_panel/toggleMenu",source)
    end
end)