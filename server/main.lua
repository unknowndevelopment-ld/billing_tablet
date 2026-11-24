local ESX = exports['es_extended']:getSharedObject()

local function response(ok, message)
    return { ok = ok, message = message }
end

local function societyAccount(name)
    local account
    TriggerEvent('esx_addonaccount:getSharedAccount', name, function(found) account = found end)
    return account
end

local function onlinePlayer(identifier)
    for _, id in ipairs(GetPlayers()) do
        local player = ESX.GetPlayerFromId(tonumber(id))
        if player and player.identifier == identifier then return player end
    end
end

lib.callback.register('billing_tablet:getData', function(source)
    local player = ESX.GetPlayerFromId(source)
    if not player then return { invoices = {}, sent = {} } end
    local invoices = MySQL.query.await('SELECT id, issuer_name, job_label, reason, amount, status, created_at FROM billing_invoices WHERE recipient = ? ORDER BY id DESC LIMIT 100', { player.identifier })
    local sent = MySQL.query.await('SELECT id, recipient_name, reason, amount, status, created_at FROM billing_invoices WHERE issuer = ? ORDER BY id DESC LIMIT 100', { player.identifier })
    return { invoices = invoices or {}, sent = sent or {}, canBill = true, job = player.job and player.job.label or 'Personal', currency = Config.Currency, maxAmount = Config.MaxAmount, myId = source }
end)

lib.callback.register('billing_tablet:create', function(source, data)
    local issuer = ESX.GetPlayerFromId(source)
    local targetId = tonumber(data and data.target)
    local amount = tonumber(data and data.amount)
    local reason = data and type(data.reason) == 'string' and data.reason:match('^%s*(.-)%s*$')
    if not issuer then return response(false, 'Player is unavailable.') end
    if not targetId or targetId % 1 ~= 0 or targetId == source or not amount or amount % 1 ~= 0 or amount < 1 or amount > Config.MaxAmount or not reason or #reason < 3 or #reason > 120 then
        return response(false, 'Check the player ID, amount and reason.')
    end
    local target = ESX.GetPlayerFromId(targetId)
    if not target then return response(false, 'Player is offline.') end
    local a, b = GetPlayerPed(source), GetPlayerPed(targetId)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > Config.MaxDistance then
        return response(false, 'Player is not nearby.')
    end
    local job = issuer.job or { name = 'unemployed', label = 'Personal' }
    local society = 'society_' .. job.name
    local id = MySQL.insert.await('INSERT INTO billing_invoices (issuer, issuer_name, recipient, recipient_name, society, job_label, reason, amount) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        issuer.identifier, issuer.getName(), target.identifier, target.getName(), society, job.label, reason, amount
    })
    if not id then return response(false, 'Could not save the invoice.') end
    TriggerClientEvent('billing_tablet:refresh', targetId, 'New invoice: ' .. Config.Currency .. amount .. ' from ' .. job.label)
    return response(true, 'Invoice #' .. id .. ' sent.')
end)

lib.callback.register('billing_tablet:pay', function(source, rawId)
    local player = ESX.GetPlayerFromId(source)
    local id = tonumber(rawId)
    if not player or not id or id % 1 ~= 0 or id < 1 then return response(false, 'Invalid invoice.') end
    local changed = MySQL.update.await("UPDATE billing_invoices SET status = 'processing' WHERE id = ? AND recipient = ? AND status = 'unpaid'", { id, player.identifier })
    if changed ~= 1 then return response(false, 'Invoice is unavailable or already paid.') end

    local invoice = MySQL.single.await('SELECT amount, society, issuer FROM billing_invoices WHERE id = ? AND recipient = ?', { id, player.identifier })
    local account = invoice and societyAccount(invoice.society)
    local issuer = invoice and not account and onlinePlayer(invoice.issuer)
    local bank = player.getAccount('bank')
    if not invoice or not bank or bank.money < invoice.amount or (not account and not issuer) then
        MySQL.update.await("UPDATE billing_invoices SET status = 'unpaid' WHERE id = ? AND status = 'processing'", { id })
        local message = not invoice and 'Invoice unavailable.' or (not bank or bank.money < invoice.amount) and 'Not enough money in your bank account.' or 'The issuer must be online to receive this payment.'
        return response(false, message)
    end

    local ok = pcall(function()
        player.removeAccountMoney('bank', invoice.amount, 'Invoice #' .. id)
        if account then account.addMoney(invoice.amount) else issuer.addAccountMoney('bank', invoice.amount, 'Invoice #' .. id) end
    end)
    if not ok then
        print(('[billing_tablet] Payment #%d needs admin review: account transfer failed'):format(id))
        return response(false, 'Payment needs admin review. Contact staff.')
    end
    local saved = MySQL.update.await("UPDATE billing_invoices SET status = 'paid', paid_at = NOW() WHERE id = ? AND status = 'processing'", { id })
    if saved ~= 1 then
        print(('[billing_tablet] Payment #%d transferred but could not be marked paid'):format(id))
        return response(false, 'Payment needs admin review. Contact staff.')
    end
    TriggerClientEvent('billing_tablet:refresh', source)
    if issuer then TriggerClientEvent('billing_tablet:refresh', issuer.source, 'Invoice #' .. id .. ' was paid.') end
    return response(true, 'Invoice paid from your bank account.')
end)
