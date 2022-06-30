
vRP.prepare("dk/get_registration","SELECT * FROM vrp_users WHERE (registration = @registration)")
vRP.prepare("dk/get_phone","SELECT * FROM vrp_users WHERE (phone = @phone)")

vRP.prepare("dk/update_registration","UPDATE vrp_users SET registration = @registration WHERE id = @id")
vRP.prepare("dk/update_phone","UPDATE vrp_users SET phone = @phone WHERE id = @id")
vRP.prepare("dk/rename_characters","UPDATE vrp_users SET name = @name, name2 = @name2 WHERE id = @id")

vRP.prepare("dk/get_perm","SELECT * FROM vrp_permissions WHERE user_id = @user_id")

vRP.prepare("dk/user_vehicles","SELECT * FROM vrp_vehicles WHERE user_id = @user_id")
vRP.prepare("dk/add_vehicle","INSERT IGNORE INTO vrp_vehicles(user_id,vehicle,plate,phone,work) VALUES(@user_id,@vehicle,@plate,@phone,@work)")
vRP.prepare("dk/rem_vehicle","DELETE FROM vrp_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")

vRP.prepare("dk/user_homes","SELECT * FROM propertys WHERE user_id = @user_id")
vRP.prepare("dk/rem_homes","DELETE FROM propertys WHERE name = @name")

vRP.prepare("dk/get_groups","SELECT * FROM vrp_permissions WHERE permiss = @permiss")

