local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")

checkPermission = function(user_id)
    return vRP.hasPermission(user_id,"Admin")
end

userSource = function(user_id) -- Função que pega a source do player.
    return vRP.getUserSource(user_id) or vRP.userSource(user_id)
end

checkExists = function(user_id) -- Função que checa se um player existe (precisa retornar o nome e sobrenome do mesmo)
    local identity = vRP.getUserIdentity(user_id) or vRP.userIdentity(user_id)
    if identity then
        local psource = userSource(user_id)
        local on = "#ce3737"
        if psource then
            on = "#4ba84b"
        end
        return {name = identity.name, name2 = identity.name2 or identity.firstname, online = on}
    else
        return "Usuário não encontrado"
    end
end

getInfos = function(name,user_id,group)
    local identity = vRP.getUserIdentity(user_id) or vRP.userIdentity(user_id)
    local psource = userSource(user_id)

    if identity then
        local infos = {
            ['infos'] = { -- Aqui você pode colocar os valores que quiser, no meu caso coloquei apenas esses
                ['Nome'] = identity.name.." "..(identity.name2 or identity.firstname),
                ['Registro'] = identity.registration or "",
                ['Telefone'] = identity.phone or "",
                ['Banco'] = "$"..(identity.bank or vRP.getBankMoney(user_id) or vRP.getBank(user_id) or "0"),
                ['Carteira'] = "$"..(vRP.getInventoryItemAmount(user_id,"dollars") or vRP.getMoney(user_id) or "0"),
            },
            ['perms'] = function()
                local tbl = {}
                local rows = vRP.query("dk/get_perm", {user_id = user_id})
                if rows[1] then
                    for k,v in pairs(rows) do
                        table.insert(tbl,{name = v.permiss})
                    end
                end
                return tbl
            end,
            ['vehs'] = function()
                local tbl = {}
                local rows = vRP.query("dk/user_vehicles", {user_id = user_id})
                if rows[1] then
                    for k,v in pairs(rows) do
                        if not v.work or v.work == "false" then
                            table.insert(tbl,{vehicle = v.vehicle,name = vRP.vehicleName(v.vehicle) or "Indefinido",fuel = v.fuel,engine = v.engine,body = v.body, image = ""})
                        end
                    end
                end
                return tbl
            end,
            ['homes'] = function()
                local tbl = {}
                local rows = vRP.query("dk/user_homes", {user_id = user_id})
                if rows[1] then
                    for k,v in pairs(rows) do
                        table.insert(tbl,{name = v.name})
                    end
                end
                return tbl
            end,
            ['inv'] = function()
                local tbl = {}
                if psource then
                    local data = vRP.getUserDataTable(user_id)
                    if data and data.inventorys then
                        for k,v in pairs(data.inventorys) do
                            if vRP.itemBodyList(v['item']) then
                                table.insert(tbl,{ index = v['item'], image = "http://190.102.42.230:3223/inventorys/"..v.item..".png", name = vRP.itemNameList(v['item']), amount = v.amount })
                            end
                        end
                    end
                else
                    local data = vRP.getUData(user_id,"Datatable")
                    data = json.decode(data) or {}
                    for k,v in pairs(data["inventorys"]) do
                        if vRP.itemBodyList(v['item']) then
                            table.insert(tbl,{ index = v['item'], image = "http://190.102.42.230:3223/inventorys/"..v.item..".png", name = vRP.itemNameList(v['item']), amount = v.amount })
                        end
                    end
                end 
                return tbl
            end,
            ['weapons'] = function()
                local tbl = {}
                if psource then
                    local weapons = vRPclient.getWeapons(psource)
                    if weapons then
                        for k,v in pairs(weapons) do
                            table.insert(tbl,{ index = k, image = "http://190.102.42.230:3223/inventorys/"..k..".png", name = vRP.itemNameList(k), ammo = v.ammo })
                        end
                    end
                else
                    local data = vRP.getUData(user_id,"Datatable")
                    data = json.decode(data) or {}
                    for k,v in pairs(data["weaps"]) do
                        table.insert(tbl,{ index = k, image = "http://190.102.42.230:3223/inventorys/"..k..".png", name = vRP.itemNameList(k), ammo = v.ammo })
                    end
                end 
                return tbl
            end,
            ['groups'] = function()
                local tbl = {}
                if group then
                    local rows = vRP.query("dk/get_groups", {permiss = group})
                    if rows[1] then
                        for k,v in pairs(rows) do
                            local nidentity = vRP.getUserIdentity(v.user_id) or vRP.userIdentity(v.user_id) or {name = " ", name2 = " "}
                            local on = "#ce3737"
                            local nsource = vRP.getUserSource(v.user_id) or vRP.userSource(v.user_id)
                            if nsource then
                                on = "#4ba84b"
                            end
                            table.insert(tbl,{name = nidentity.name.." "..(nidentity.name2 or nidentity.firstname), online = on, id = v.user_id,group = group})
                        end
                    end
                end 
                return tbl
            end,
        }

        if type(infos[name]) == "table" then
            return infos[name]
        elseif type(infos[name]) == "function" then
            return infos[name] ()
        end
    end
end

editInfos = function(data,user_id)
    local identity = vRP.getUserIdentity(user_id) or vRP.userIdentity(user_id)
    if identity then
        local infos = {
            ['Nome'] = function()
                vRP.execute("dk/rename_characters",{ id = user_id, name = data.text[1], name2 = data.text[2] })
                return true
            end,
            ['Registro'] = function()
                if string.len(data.text) ~= 8 then
                    return "O registro precisa conter 8 dígitos."
                end
                local rows = vRP.query("dk/get_registration", {registration = data.text})
                if rows[1] then
                    return "Registro em uso, escolha outro..."
                end
                vRP.execute("dk/update_registration",{ id = user_id, registration = data.text })
                return true
            end,
            ['Telefone'] = function()
                local phone = data.text:gsub( "[^%w-]", "" )
                if string.len(phone) ~= 7 then
                    return "O telefone precisa conter 6 dígitos, sendo: XXX-XXX."
                end
                local rows = vRP.query("dk/get_phone", {phone = phone})
                if rows[1] then
                    return "Telefone em uso, escolha outro..."
                end
                vRP.execute("dk/update_phone",{ id = user_id, phone = phone })
                return true
            end,
            ['Banco'] = function()
                local bankAmount = vRP.getBank(user_id) or vRP.getBankMoney(user_id) or 0
                vRP.setBank(user_id,bankAmount+parseInt(data.text))
                -- vRP.setBankMoney(user_id,bankAmount+parseInt(data.text))
                return true
            end,
            ['Carteira'] = function()
                local amount = parseInt(data.text)
                if amount < 0 then
                    if vRP.tryGetInventoryItem(user_id,"dollars",-(amount),true) then
                        return true
                    else
                        return "Dinheiro insuficiente na carteira"
                    end
                else
                    vRP.giveInventoryItem(user_id,"dollars",amount,true)
                    return true
                end
            end,
        }
        return infos[data.item] ()
    end
end

removeHome = function(home,user_id)
    vRP.execute("dk/rem_homes",{ name = home })
    return true
end
removeWeapon = function(item,amount,user_id)
    local psource = userSource(user_id)
    if psource then
        local weapons = vRPclient.getWeapons(psource)
        local new = {}
        for k,v in pairs(weapons) do
            if k ~= item then
                new[k] = {ammo = v.ammo}
            end
        end
        vRPclient.giveWeapons(psource,new,true)
    else
        local data = vRP.getUData(parseInt(user_id),"Datatable")
        data = json.decode(data) or {} 
        if data.weaps then
            for k,v in pairs(data.weaps) do 
                if k == item then
                    data.weaps[k] = nil
                end
            end
        end
        vRP.setUData(parseInt(user_id),"Datatable",json.encode(data))
    end
    return true
end
addWeapon = function(item,amount,user_id)
    amount = parseInt(amount)
    local psource = userSource(user_id)
    if psource then
        vRPclient.giveWeapons(psource,{[item] = {ammo = amount}})
    else
        local data = vRP.getUData(parseInt(user_id),"Datatable")
        data = json.decode(data) or {} 
        if data.weaps then
            for k,v in pairs(data.weaps) do 
                if k == item then
                    data.weaps[k] = {ammo = amount}
                end
            end
        end
        vRP.setUData(parseInt(user_id),"Datatable",json.encode(data))
    end
    return true
end
removeInv = function(item,amount,user_id)
    local psource = userSource(user_id)
    if psource then
        vRP.tryGetInventoryItem(user_id,item,parseInt(amount),true)
    else
        local data = vRP.getUData(parseInt(user_id),"Datatable")
        data = json.decode(data) or {}
        if data.inventorys then
            for k,v in pairs(data.inventorys) do 
                if v['item'] == item then
                    data.inventorys[k].amount =  data.inventorys[k].amount - parseInt(amount)
                    if  data.inventorys[k].amount < 1 then
                        data.inventorys[k] = nil
                    end
                end
            end
        end
        vRP.setUData(parseInt(user_id),"Datatable",json.encode(data))
    end
    return true
end
addInv = function(item,amount,user_id)
    amount = parseInt(amount)
    local psource = userSource(user_id)
    if psource then
        vRP.giveInventoryItem(user_id,item,parseInt(amount),true)
    else
        local data = vRP.getUData(parseInt(user_id),"Datatable")
        data = json.decode(data) or {}
        if data.inventorys then
            local initial = 0
            repeat
                initial = initial + 1
            until data.inventorys[tostring(initial)] == nil or (data.inventorys[tostring(initial)] and data.inventorys[tostring(initial)].item == item)
            initial = tostring(initial)

            if data.inventorys[initial] == nil then
                data.inventorys[initial] = { item = item, amount = amount }
            elseif data.inventorys[initial] and data.inventorys[initial].item == item then
                data.inventorys[initial].amount = parseInt(data.inventorys[initial].amount) + amount
            end
        end
        vRP.setUData(parseInt(user_id),"Datatable",json.encode(data))
    end
    return true
end

removeVehicle = function(vehicle,user_id)
    vRP.execute("dk/rem_vehicle",{ user_id = parseInt(user_id), vehicle = vehicle })
    return true
end
addVehicle = function(vehicle,user_id)
    vRP.execute("dk/add_vehicle",{ user_id = user_id, vehicle = vehicle, plate = vRP.generatePlateNumber(), phone = vRP.getPhone(user_id), work = tostring(false) })
    return true
end

removePermission = function(permission,user_id)
    local nplayer = userSource(user_id)
    if nplayer then
        vRP.removePermission(nplayer,tostring(permission))
    end
    vRP.execute("vRP/del_group",{ user_id = user_id, permiss = tostring(permission) })
    return true
end

addPermission = function(permission,user_id)
    if not vRP.hasPermission(user_id,tostring(permission)) then
        local nplayer = userSource(user_id)
        if nplayer then
            vRP.insertPermission(nplayer,tostring(permission))
        end
        vRP.execute("vRP/add_group",{ user_id = user_id, permiss = tostring(permission) })
    end
    return true
end

playerActions = function(action,user_id,staff)
    local actions = {
        ["kick"] = function()
            local reason = vRP.prompt(source,"Motivo?","")
			if reason == "" then
				return
			end
			vRP.kick(user_id,"Você foi expulso da cidade. Motivo: "..reason)
        end,
        ["ban"] = function()
			local pidentity = vRP.getUserIdentity(user_id)
            if pidentity then
                local reason = vRP.prompt(source,"Motivo?","")
                if reason == "" then
                    return
                end
                vRP.kick(user_id,"Você foi banido da Cidade. Motivo: "..reason)
                vRP.execute("vRP/set_banned",{ steam = tostring(pidentity.steam), banned = 1 })
            end
        end,
    }
    actions[action] ()
end

