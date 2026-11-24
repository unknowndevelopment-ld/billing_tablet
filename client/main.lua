local open = false

local function refresh()
    lib.callback('billing_tablet:getData', false, function(data)
        if open then SendNUIMessage({ action = 'data', data = data }) end
    end)
end

local function closeTablet()
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('billingtablet', function()
    if open then return closeTablet() end
    open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
    refresh()
end, false)
RegisterKeyMapping('billingtablet', 'Open billing tablet', 'keyboard', 'F7')

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    refresh()
    cb({ ok = true })
end)

RegisterNUICallback('create', function(data, cb)
    local target = tonumber(data.target)
    if not target or target == GetPlayerServerId(PlayerId()) then
        return cb({ ok = false, message = 'Enter a nearby player ID.' })
    end
    local player = GetPlayerFromServerId(target)
    if player == -1 or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(GetPlayerPed(player))) > Config.MaxDistance then
        return cb({ ok = false, message = 'That player is not nearby.' })
    end
    lib.callback('billing_tablet:create', false, function(result)
        cb(result)
        lib.notify({ title = 'Billing', description = result.message, type = result.ok and 'success' or 'error' })
        if result.ok then refresh() end
    end, data)
end)

RegisterNUICallback('pay', function(data, cb)
    lib.callback('billing_tablet:pay', false, function(result)
        cb(result)
        lib.notify({ title = 'Billing', description = result.message, type = result.ok and 'success' or 'error' })
        refresh()
    end, data.id)
end)

RegisterNetEvent('billing_tablet:refresh', function(message)
    if message then lib.notify({ title = 'Billing', description = message, type = 'inform' }) end
    if open then refresh() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
