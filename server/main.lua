local Core, Framework = nil, nil
local Prefix = Config.EventPrefix or 'rs-bossmenu'

local function debugPrint(...)
    if Config.Debug then
        print(('^5[%s]^7'):format(Prefix), ...)
    end
end

local function locale(key, ...)
    local tbl = Locales[Config.Locale] or Locales['en'] or {}
    local value = tbl[key] or key
    if select('#', ...) > 0 then
        return value:format(...)
    end
    return value
end

local function moneyFormat(amount)
    local formatted = tostring(math.floor(tonumber(amount) or 0))
    while true do
        local k = formatted:gsub('^(%-?%d+)(%d%d%d)', '%1,%2')
        if k == formatted then break end
        formatted = k
    end
    return formatted
end

local function bootFramework()
    while not Framework do
        if Config.Framework == 'qbcore' or Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
            Core = exports['qb-core']:GetCoreObject()
            Framework = 'qb'
        elseif Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
            Core = exports['es_extended']:getSharedObject()
            Framework = 'esx'
        end
        if not Framework then Wait(500) end
    end
    debugPrint('Framework initialized as', Framework)
end

CreateThread(bootFramework)

local function getPlayer(src)
    if Framework == 'qb' then
        return Core.Functions.GetPlayer(src)
    elseif Framework == 'esx' then
        return Core.GetPlayerFromId(src)
    end
end

local function getAllPlayers()
    local list = {}
    for _, id in ipairs(GetPlayers()) do
        list[#list+1] = tonumber(id)
    end
    return list
end

local function getPlayerNameFull(src)
    local player = getPlayer(src)
    if not player then return GetPlayerName(src) or 'Unknown' end
    if Framework == 'qb' then
        local c = player.PlayerData.charinfo or {}
        local name = ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
        return name ~= '' and name or GetPlayerName(src) or 'Unknown'
    end
    return player.getName and player.getName() or GetPlayerName(src) or 'Unknown'
end

local function getIdentifier(src)
    local player = getPlayer(src)
    if not player then return nil end
    if Framework == 'qb' then
        return player.PlayerData.citizenid
    end
    return player.identifier
end

local function getJobData(src)
    local player = getPlayer(src)
    if not player then return nil end
    if Framework == 'qb' then
        return player.PlayerData.job
    end
    return player.job
end

local function getJobName(src)
    local job = getJobData(src)
    return job and job.name or nil
end

local function getJobGrade(src)
    local job = getJobData(src)
    if not job then return 0 end
    if Framework == 'qb' then
        return tonumber(job.grade and (job.grade.level or job.grade) or 0) or 0
    end
    return tonumber(job.grade or 0) or 0
end

local function getJobGradeName(src)
    local job = getJobData(src)
    if not job then return '' end
    if Framework == 'qb' then
        return job.grade and (job.grade.name or '') or ''
    end
    return job.grade_name or job.grade_label or ''
end

local function getJobLabel(jobName)
    if Framework == 'qb' then
        return Core.Shared and Core.Shared.Jobs and Core.Shared.Jobs[jobName] and Core.Shared.Jobs[jobName].label or jobName
    end
    if Core and Core.Jobs and Core.Jobs[jobName] then
        return Core.Jobs[jobName].label or jobName
    end
    return (Config.JobLocations[jobName] and Config.JobLocations[jobName].label) or jobName
end

local function getGrades(jobName)
    local items = {}
    if Framework == 'qb' then
        local job = Core.Shared and Core.Shared.Jobs and Core.Shared.Jobs[jobName]
        if job and job.grades then
            for k, v in pairs(job.grades) do
                items[#items+1] = {
                    grade = tonumber(k) or 0,
                    label = v.name or tostring(k),
                    isboss = v.isboss or false,
                    bankAuth = v.bankAuth or false,
                    payment = tonumber(v.payment or 0) or 0
                }
            end
        end
    else
        local job = Core and Core.Jobs and Core.Jobs[jobName]
        if job and job.grades then
            for k, v in pairs(job.grades) do
                items[#items+1] = {
                    grade = tonumber(k) or 0,
                    label = v.label or v.name or tostring(k),
                    isboss = v.isboss or false,
                    bankAuth = v.bankAuth or false,
                    payment = tonumber(v.payment or 0) or 0
                }
            end
        else
            local rows = MySQL.query.await('SELECT grade, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { jobName }) or {}
            for i = 1, #rows do
                items[#items+1] = {
                    grade = tonumber(rows[i].grade or 0) or 0,
                    label = rows[i].label or tostring(rows[i].grade or 0),
                    isboss = false,
                    bankAuth = false,
                    payment = 0
                }
            end
        end
    end
    table.sort(items, function(a, b) return a.grade < b.grade end)
    return items
end

local function getGradeLabel(jobName, grade)
    local grades = getGrades(jobName)
    for i = 1, #grades do
        if grades[i].grade == tonumber(grade) then
            return grades[i].label
        end
    end
    return tostring(grade)
end

local function getMaxGrade(jobName)
    local grades = getGrades(jobName)
    local max = 0
    for i = 1, #grades do
        if grades[i].grade > max then
            max = grades[i].grade
        end
    end
    return max
end

local function hasBossAccess(src, expectedJob)
    local job = getJobData(src)
    if not job or job.name ~= expectedJob then
        return false
    end

    if Config.UseFrameworkBoss then
        if Framework == 'qb' then
            if type(job.grade) == 'table' and (job.grade.isboss or job.grade.bankAuth) then
                return true
            end
            local shared = Core.Shared and Core.Shared.Jobs and Core.Shared.Jobs[expectedJob]
            local gradeIndex = tonumber(job.grade and (job.grade.level or job.grade) or 0) or 0
            local gradeData = shared and shared.grades and (shared.grades[tostring(gradeIndex)] or shared.grades[gradeIndex])
            if gradeData and (gradeData.isboss or gradeData.bankAuth) then
                return true
            end
        else
            if job.grade_name == 'boss' then
                return true
            end
        end
    end

    local gradeName = string.lower(getJobGradeName(src) or '')
    for i = 1, #(Config.BossGradeNames or {}) do
        if gradeName == string.lower(Config.BossGradeNames[i]) then
            return true
        end
    end

    local grade = getJobGrade(src)
    for i = 1, #(Config.BossGradeLevels or {}) do
        if grade == tonumber(Config.BossGradeLevels[i]) then
            return true
        end
    end

    return false
end

local function getAccountCandidates(jobName, provider)
    local candidates = {}
    local function add(name)
        if name and name ~= '' then
            for i = 1, #candidates do
                if candidates[i] == name then
                    return
                end
            end
            candidates[#candidates + 1] = name
        end
    end

    if provider == 'renewed-banking' then
        add(jobName)
        add(('society_%s'):format(jobName))
        add(('business:%s'):format(jobName))
        add(('business_%s'):format(jobName))
    elseif provider == 'qb-banking' then
        add(jobName)
        add(('society_%s'):format(jobName))
    else
        add(jobName)
    end

    return candidates
end

local function detectSocietyProvider()
    local preferred = string.lower(Config.SocietySystem or 'auto')
    if preferred ~= 'auto' then
        return preferred
    end
    if GetResourceState('Renewed-Banking') == 'started' then return 'renewed-banking' end
    if Framework == 'qb' and GetResourceState('qb-management') == 'started' then return 'qb-management' end
    if Framework == 'qb' and GetResourceState('qb-banking') == 'started' then return 'qb-banking' end
    if Framework == 'esx' and GetResourceState('esx_addonaccount') == 'started' then return 'esx_addonaccount' end
    return 'fallback'
end

local function ensureTables()
    if not Config.AutoAddDatabaseTables then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rs_bossmenu_societies` (
            `job_name` varchar(64) NOT NULL,
            `money` bigint NOT NULL DEFAULT 0,
            PRIMARY KEY (`job_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rs_bossmenu_logs` (
            `id` int NOT NULL AUTO_INCREMENT,
            `job_name` varchar(64) NOT NULL,
            `action` varchar(64) NOT NULL,
            `actor_name` varchar(128) DEFAULT NULL,
            `target_name` varchar(128) DEFAULT NULL,
            `amount` bigint NOT NULL DEFAULT 0,
            `extra` longtext DEFAULT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_job_created` (`job_name`,`created_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rs_bossmenu_duty_sessions` (
            `id` int NOT NULL AUTO_INCREMENT,
            `job_name` varchar(64) NOT NULL,
            `identifier` varchar(96) NOT NULL,
            `player_name` varchar(128) DEFAULT NULL,
            `started_at` int NOT NULL,
            `ended_at` int DEFAULT NULL,
            `duration` int NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            KEY `idx_job_identifier` (`job_name`,`identifier`),
            KEY `idx_started_at` (`started_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `rs_bossmenu_active_duty` (
            `identifier` varchar(96) NOT NULL,
            `job_name` varchar(64) NOT NULL,
            `player_name` varchar(128) DEFAULT NULL,
            `started_at` int NOT NULL,
            PRIMARY KEY (`identifier`,`job_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function getStashId(jobName)
    local prefix = (Config.Inventory and Config.Inventory.stashes and Config.Inventory.stashes.prefix) or 'bossstash_'
    return ('%s%s'):format(prefix, jobName)
end

local function registerOxStashes()
    if not Config.Inventory or not Config.Inventory.stashes or not Config.Inventory.stashes.enabled then return end
    local oxName = Config.Inventory.stashes.ox or 'ox_inventory'
    if GetResourceState(oxName) ~= 'started' then return end
    for jobName, data in pairs(Config.JobLocations or {}) do
        local stashConfig = data.stash or {}
        pcall(function()
            exports[oxName]:RegisterStash(
                getStashId(jobName),
                stashConfig.label or Config.Inventory.stashes.defaultLabel or 'Society Stash',
                stashConfig.slots or Config.Inventory.stashes.defaultSlots or 100,
                stashConfig.maxWeight or Config.Inventory.stashes.defaultMaxWeight or 400000,
                false,
                { [jobName] = 0 }
            )
        end)
    end
end

CreateThread(function()
    while not Framework do Wait(250) end
    ensureTables()
    registerOxStashes()
end)

local function ensureSociety(jobName)
    if not Config.AutoCreateSociety then return end
    local row = MySQL.single.await('SELECT job_name FROM rs_bossmenu_societies WHERE job_name = ?', { jobName })
    if not row then
        MySQL.insert.await('INSERT INTO rs_bossmenu_societies (job_name, money) VALUES (?, ?)', { jobName, 0 })
    end
end

local function getFallbackBalance(jobName)
    ensureSociety(jobName)
    local row = MySQL.single.await('SELECT money FROM rs_bossmenu_societies WHERE job_name = ?', { jobName })
    return tonumber(row and row.money or 0) or 0
end

local function setFallbackBalance(jobName, amount)
    ensureSociety(jobName)
    MySQL.update.await('UPDATE rs_bossmenu_societies SET money = ? WHERE job_name = ?', { amount, jobName })
    return true
end

local function getRenewedBalance(jobName)
    for _, accountName in ipairs(getAccountCandidates(jobName, 'renewed-banking')) do
        local ok, value = pcall(function()
            return exports['Renewed-Banking']:getAccountMoney(accountName)
        end)
        if ok and value ~= nil and value ~= false then
            return tonumber(value) or 0
        end
    end
    return nil
end

local function addRenewedBalance(jobName, amount)
    for _, accountName in ipairs(getAccountCandidates(jobName, 'renewed-banking')) do
        local ok, value = pcall(function()
            return exports['Renewed-Banking']:addAccountMoney(accountName, amount)
        end)
        if ok then
            return value ~= false
        end
    end
    return nil
end

local function removeRenewedBalance(jobName, amount)
    for _, accountName in ipairs(getAccountCandidates(jobName, 'renewed-banking')) do
        local ok, value = pcall(function()
            return exports['Renewed-Banking']:removeAccountMoney(accountName, amount)
        end)
        if ok then
            return value ~= false
        end
    end
    return nil
end

local function getSocietyMoney(jobName)
    local provider = detectSocietyProvider()
    if provider == 'renewed-banking' and GetResourceState('Renewed-Banking') == 'started' then
        local amount = getRenewedBalance(jobName)
        if amount ~= nil then return amount, provider end
    elseif provider == 'qb-management' and GetResourceState('qb-management') == 'started' then
        local ok, value = pcall(function() return exports['qb-management']:GetAccount(jobName) end)
        if ok then
            if type(value) == 'table' then return tonumber(value.balance or value.money or 0) or 0, provider end
            return tonumber(value or 0) or 0, provider
        end
    elseif provider == 'qb-banking' and GetResourceState('qb-banking') == 'started' then
        local ok, value
        for _, accountName in ipairs(getAccountCandidates(jobName, 'qb-banking')) do
            ok, value = pcall(function() return exports['qb-banking']:GetAccountBalance(accountName) end)
            if ok then break end
        end
        if ok then return tonumber(value or 0) or 0, provider end
    elseif provider == 'esx_addonaccount' and GetResourceState('esx_addonaccount') == 'started' then
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', ('society_%s'):format(jobName), function(account)
            p:resolve(account and account.money or 0)
        end)
        return tonumber(Citizen.Await(p) or 0) or 0, provider
    end
    return getFallbackBalance(jobName), 'fallback'
end

local function addSocietyMoney(jobName, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local provider = detectSocietyProvider()
    if provider == 'renewed-banking' and GetResourceState('Renewed-Banking') == 'started' then
        local ok = addRenewedBalance(jobName, amount)
        if ok ~= nil then return ok end
    elseif provider == 'qb-management' and GetResourceState('qb-management') == 'started' then
        local ok = pcall(function() exports['qb-management']:AddMoney(jobName, amount) end)
        if ok then return true end
    elseif provider == 'qb-banking' and GetResourceState('qb-banking') == 'started' then
        local ok = false
        for _, accountName in ipairs(getAccountCandidates(jobName, 'qb-banking')) do
            ok = pcall(function() exports['qb-banking']:AddMoney(accountName, amount) end)
            if ok then break end
        end
        if ok then return true end
    elseif provider == 'esx_addonaccount' and GetResourceState('esx_addonaccount') == 'started' then
        TriggerEvent('esx_addonaccount:getSharedAccount', ('society_%s'):format(jobName), function(account)
            if account then account.addMoney(amount) end
        end)
        return true
    end
    local current = getFallbackBalance(jobName)
    return setFallbackBalance(jobName, current + amount)
end

local function removeSocietyMoney(jobName, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local balance = select(1, getSocietyMoney(jobName))
    if balance < amount then return false end
    local provider = detectSocietyProvider()
    if provider == 'renewed-banking' and GetResourceState('Renewed-Banking') == 'started' then
        local ok = removeRenewedBalance(jobName, amount)
        if ok ~= nil then return ok end
    elseif provider == 'qb-management' and GetResourceState('qb-management') == 'started' then
        local ok = pcall(function() exports['qb-management']:RemoveMoney(jobName, amount) end)
        if ok then return true end
    elseif provider == 'qb-banking' and GetResourceState('qb-banking') == 'started' then
        local ok = false
        for _, accountName in ipairs(getAccountCandidates(jobName, 'qb-banking')) do
            ok = pcall(function() exports['qb-banking']:RemoveMoney(accountName, amount) end)
            if ok then break end
        end
        if ok then return true end
    elseif provider == 'esx_addonaccount' and GetResourceState('esx_addonaccount') == 'started' then
        TriggerEvent('esx_addonaccount:getSharedAccount', ('society_%s'):format(jobName), function(account)
            if account then account.removeMoney(amount) end
        end)
        return true
    end
    local current = getFallbackBalance(jobName)
    return setFallbackBalance(jobName, current - amount)
end

local function getCash(src)
    local player = getPlayer(src)
    if not player then return 0 end
    if Framework == 'qb' then
        return player.Functions.GetMoney('cash') or 0
    end
    return player.getMoney() or 0
end

local function removeCash(src, amount)
    local player = getPlayer(src)
    if not player then return false end
    if Framework == 'qb' then
        return player.Functions.RemoveMoney('cash', amount, 'rs-bossmenu-deposit')
    end
    player.removeMoney(amount)
    return true
end

local function addCash(src, amount)
    local player = getPlayer(src)
    if not player then return false end
    if Framework == 'qb' then
        player.Functions.AddMoney('cash', amount, 'rs-bossmenu-withdraw')
        return true
    end
    player.addMoney(amount)
    return true
end

local function setJob(src, jobName, grade)
    local player = getPlayer(src)
    if not player then return false end
    if Framework == 'qb' then
        player.Functions.SetJob(jobName, grade)
    else
        player.setJob(jobName, grade)
    end
    return true
end

local function setOfflineJob(identifier, jobName, grade)
    if Framework == 'qb' then
        local row = MySQL.single.await('SELECT job FROM players WHERE citizenid = ?', { identifier })
        if not row then return false end
        local jobData = type(row.job) == 'string' and json.decode(row.job) or row.job
        local shared = Core.Shared and Core.Shared.Jobs and Core.Shared.Jobs[jobName]
        local gradeData = shared and shared.grades and (shared.grades[tostring(grade)] or shared.grades[grade]) or {}
        jobData = jobData or {}
        jobData.name = jobName
        jobData.label = shared and shared.label or jobName
        jobData.onduty = false
        jobData.payment = tonumber(gradeData.payment or 0) or 0
        jobData.grade = {
            name = gradeData.name or tostring(grade),
            level = tonumber(grade) or 0,
            payment = tonumber(gradeData.payment or 0) or 0,
            isboss = gradeData.isboss or false
        }
        MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(jobData), identifier })
        return true
    end
    MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { jobName, grade, identifier })
    return true
end

local function logAction(jobName, action, actorName, targetName, amount, extra)
    MySQL.insert.await('INSERT INTO rs_bossmenu_logs (job_name, action, actor_name, target_name, amount, extra) VALUES (?, ?, ?, ?, ?, ?)', {
        jobName,
        action,
        actorName,
        targetName,
        tonumber(amount or 0) or 0,
        extra and json.encode(extra) or nil
    })
end

local function getRecentLogs(jobName)
    local rows = MySQL.query.await('SELECT action, actor_name, target_name, amount, created_at FROM rs_bossmenu_logs WHERE job_name = ? ORDER BY id DESC LIMIT 20', { jobName }) or {}
    local list = {}
    for i = 1, #rows do
        local row = rows[i]
        local suffix = ''
        if tonumber(row.amount or 0) > 0 then
            suffix = (' • %s%s'):format(Config.Currency, moneyFormat(row.amount))
        end
        local target = row.target_name and row.target_name ~= '' and (' • ' .. row.target_name) or ''
        list[#list+1] = {
            title = row.actor_name or 'System',
            description = string.upper(row.action:gsub('_', ' ')) .. suffix .. target,
            timestamp = tostring(row.created_at or '')
        }
    end
    return list
end

local function getFinanceHistory(jobName, currentBalance)
    local rows = MySQL.query.await('SELECT action, amount, created_at FROM rs_bossmenu_logs WHERE job_name = ? AND action IN (?, ?) ORDER BY id DESC LIMIT 12', {
        jobName,
        'deposit',
        'withdraw'
    }) or {}

    local entries = {}
    for i = #rows, 1, -1 do
        local row = rows[i]
        local amount = tonumber(row.amount or 0) or 0
        local signed = row.action == 'withdraw' and -amount or amount
        entries[#entries + 1] = {
            label = tostring(row.created_at or ''):sub(12, 16),
            amount = signed
        }
    end

    if #entries == 0 then
        entries[1] = { label = 'Now', amount = 0 }
    end

    return entries
end

local function getNearbyPlayers(src)
    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)
    local list = {}
    for _, id in ipairs(getAllPlayers()) do
        if id ~= src then
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)
            local dist = #(srcCoords - coords)
            if dist <= (Config.HireDistance or 3.0) then
                list[#list+1] = {
                    source = id,
                    name = getPlayerNameFull(id),
                    distance = math.floor(dist * 10) / 10
                }
            end
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

local function getEmployees(jobName)
    local employees = {}
    local onlineMap = {}
    for _, id in ipairs(getAllPlayers()) do
        local job = getJobData(id)
        if job and job.name == jobName then
            local identifier = getIdentifier(id)
            onlineMap[identifier] = {
                identifier = identifier,
                source = id,
                online = true,
                name = getPlayerNameFull(id),
                grade = getJobGrade(id),
                gradeLabel = getGradeLabel(jobName, getJobGrade(id))
            }
        end
    end

    if Framework == 'qb' then
        local rows = MySQL.query.await('SELECT citizenid, charinfo, job FROM players') or {}
        for i = 1, #rows do
            local row = rows[i]
            local jobData = type(row.job) == 'string' and json.decode(row.job) or row.job
            if jobData and jobData.name == jobName then
                local online = onlineMap[row.citizenid]
                local charinfo = type(row.charinfo) == 'string' and json.decode(row.charinfo) or row.charinfo
                employees[#employees+1] = {
                    identifier = row.citizenid,
                    source = online and online.source or nil,
                    online = online ~= nil,
                    name = online and online.name or ((((charinfo and charinfo.firstname) or 'Unknown') .. ' ' .. ((charinfo and charinfo.lastname) or '')):gsub('%s+$', '')),
                    grade = online and online.grade or tonumber(jobData.grade and (jobData.grade.level or 0) or 0) or 0,
                    gradeLabel = online and online.gradeLabel or (jobData.grade and jobData.grade.name or getGradeLabel(jobName, tonumber(jobData.grade and (jobData.grade.level or 0) or 0) or 0))
                }
            end
        end
    else
        local rows = MySQL.query.await('SELECT identifier, firstname, lastname, job, job_grade FROM users WHERE job = ?', { jobName }) or {}
        for i = 1, #rows do
            local row = rows[i]
            local online = onlineMap[row.identifier]
            employees[#employees+1] = {
                identifier = row.identifier,
                source = online and online.source or nil,
                online = online ~= nil,
                name = online and online.name or (((row.firstname or 'Unknown') .. ' ' .. (row.lastname or '')):gsub('%s+$', '')),
                grade = online and online.grade or tonumber(row.job_grade or 0) or 0,
                gradeLabel = online and online.gradeLabel or getGradeLabel(jobName, row.job_grade)
            }
        end
    end

    table.sort(employees, function(a, b)
        if a.online ~= b.online then return a.online and not b.online end
        if a.grade ~= b.grade then return a.grade > b.grade end
        return a.name < b.name
    end)

    return employees
end


local function getUnix()
    return os.time()
end

local function beginDutySession(src, jobName)
    local identifier = getIdentifier(src)
    if not identifier or not jobName then return end
    MySQL.query.await('DELETE FROM rs_bossmenu_active_duty WHERE identifier = ? AND job_name = ?', { identifier, jobName })
    MySQL.insert.await('INSERT INTO rs_bossmenu_active_duty (identifier, job_name, player_name, started_at) VALUES (?, ?, ?, ?)', {
        identifier,
        jobName,
        getPlayerNameFull(src),
        getUnix()
    })
end

local function closeDutySessionByIdentifier(identifier, playerName)
    if not identifier then return end
    local active = MySQL.query.await('SELECT * FROM rs_bossmenu_active_duty WHERE identifier = ?', { identifier }) or {}
    local now = getUnix()
    for i = 1, #active do
        local row = active[i]
        local startedAt = tonumber(row.started_at or now) or now
        local duration = math.max(0, now - startedAt)
        if duration > 0 then
            MySQL.insert.await('INSERT INTO rs_bossmenu_duty_sessions (job_name, identifier, player_name, started_at, ended_at, duration) VALUES (?, ?, ?, ?, ?, ?)', {
                row.job_name,
                identifier,
                playerName or row.player_name,
                startedAt,
                now,
                duration
            })
        end
        MySQL.query.await('DELETE FROM rs_bossmenu_active_duty WHERE identifier = ? AND job_name = ?', { identifier, row.job_name })
    end
    local jobs = {}
    for i = 1, #active do jobs[#jobs+1] = active[i].job_name end
    return jobs
end

local function formatDuration(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours > 0 then
        return ('%sh %sm'):format(hours, minutes)
    end
    return ('%sm'):format(minutes)
end

local function getDutySummary(identifier, jobName)
    if not identifier or not jobName then
        return { totalSeconds = 0, totalFormatted = formatDuration(0), currentShiftSeconds = 0, currentShiftFormatted = formatDuration(0), todayName = 'Monday', days = {} }
    end

    local totalRow = MySQL.single.await('SELECT COALESCE(SUM(duration), 0) AS total FROM rs_bossmenu_duty_sessions WHERE identifier = ? AND job_name = ?', { identifier, jobName }) or {}
    local active = MySQL.single.await('SELECT started_at FROM rs_bossmenu_active_duty WHERE identifier = ? AND job_name = ?', { identifier, jobName })
    local activeSeconds = 0
    if active and active.started_at then
        activeSeconds = math.max(0, getUnix() - (tonumber(active.started_at) or getUnix()))
    end

    local weekRows = MySQL.query.await([[SELECT DAYOFWEEK(FROM_UNIXTIME(started_at)) AS weekday_index, COALESCE(SUM(duration),0) AS total
        FROM rs_bossmenu_duty_sessions
        WHERE identifier = ? AND job_name = ? AND YEARWEEK(FROM_UNIXTIME(started_at), 1) = YEARWEEK(CURDATE(), 1)
        GROUP BY weekday_index]], { identifier, jobName }) or {}

    local totalsByDay = {}
    for i = 1, #weekRows do
        local row = weekRows[i]
        local weekdayIndex = tonumber(row.weekday_index or 0) or 0
        if weekdayIndex == 1 then weekdayIndex = 7 else weekdayIndex = weekdayIndex - 1 end
        totalsByDay[weekdayIndex] = tonumber(row.total or 0) or 0
    end

    local weekdayNames = { 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' }
    local todayTable = os.date('*t')
    local todayIndex = tonumber(todayTable and todayTable.wday or 2) or 2
    if todayIndex == 1 then
        todayIndex = 7
    else
        todayIndex = todayIndex - 1
    end
    if activeSeconds > 0 then
        totalsByDay[todayIndex] = (totalsByDay[todayIndex] or 0) + activeSeconds
    end

    local days = {}
    for i = 1, 7 do
        local seconds = totalsByDay[i] or 0
        days[#days+1] = {
            day = weekdayNames[i],
            short = weekdayNames[i]:sub(1, 3),
            seconds = seconds,
            formatted = formatDuration(seconds),
            today = i == todayIndex
        }
    end

    local total = (tonumber(totalRow.total or 0) or 0) + activeSeconds
    return {
        totalSeconds = total,
        totalFormatted = formatDuration(total),
        currentShiftSeconds = activeSeconds,
        currentShiftFormatted = formatDuration(activeSeconds),
        todayName = weekdayNames[todayIndex],
        days = days
    }
end

local function getDutyOverview(jobName)
    local employees = getEmployees(jobName)
    local items = {}
    for i = 1, #employees do
        local emp = employees[i]
        local summary = getDutySummary(emp.identifier, jobName)
        items[#items+1] = {
            identifier = emp.identifier,
            name = emp.name,
            grade = emp.grade,
            gradeLabel = emp.gradeLabel,
            online = emp.online,
            totalSeconds = summary.totalSeconds,
            totalFormatted = summary.totalFormatted,
            currentShiftFormatted = summary.currentShiftFormatted,
            days = summary.days
        }
    end
    table.sort(items, function(a, b) return (a.totalSeconds or 0) > (b.totalSeconds or 0) end)
    return items
end

local function getOverview(src, jobName)
    local employees = getEmployees(jobName)
    local balance, provider = getSocietyMoney(jobName)
    local onlineCount = 0
    for i = 1, #employees do
        if employees[i].online then onlineCount = onlineCount + 1 end
    end
    local grades = getGrades(jobName)
    local stashConfig = (Config.JobLocations[jobName] and Config.JobLocations[jobName].stash) or {}
    local job = getJobData(src)
    local onDuty = false
    if Framework == 'qb' and job then
        onDuty = job.onduty == true
    end
    return {
        job = jobName,
        jobLabel = getJobLabel(jobName),
        subtitle = locale('menu_subtitle'),
        balance = tonumber(balance or 0) or 0,
        balanceFormatted = ('%s%s'):format(Config.Currency, moneyFormat(balance or 0)),
        balanceProvider = provider,
        accountLabel = 'Society Treasury',
        employeeCount = #employees,
        onlineCount = onlineCount,
        employees = employees,
        nearby = getNearbyPlayers(src),
        activity = getRecentLogs(jobName),
        financeHistory = getFinanceHistory(jobName, balance),
        grades = grades,
        quickAmounts = Config.QuickAmounts or { 500, 1000, 2500, 5000 },
        selfGrade = getJobGrade(src),
        selfGradeLabel = getGradeLabel(jobName, getJobGrade(src)),
        operations = {
            stash = Config.Inventory and Config.Inventory.stashes and Config.Inventory.stashes.enabled,
            wardrobe = Config.Wardrobe and Config.Wardrobe.enabled,
            duty = Framework == 'qb',
            onDuty = onDuty
        },
        dutyOverview = getDutyOverview(jobName),
        settings = {
            finances = true,
            employees = true,
            hiring = true,
            activity = true,
            operations = true
        }
    }
end

local function refreshForJob(jobName)
    for _, id in ipairs(getAllPlayers()) do
        if getJobName(id) == jobName then
            TriggerClientEvent(Prefix .. ':client:refresh', id, jobName)
        end
    end
end

lib.callback.register(Prefix .. ':server:openMenu', function(src, jobName)
    while not Framework do Wait(100) end
    jobName = jobName or getJobName(src)
    if not jobName then
        return { message = locale('invalid_job'), type = 'error' }
    end
    if not hasBossAccess(src, jobName) then
        return { message = locale('no_access'), type = 'error' }
    end
    return getOverview(src, jobName)
end)

lib.callback.register(Prefix .. ':server:nuiAction', function(src, payload)
    while not Framework do Wait(100) end
    local action = payload.action
    local jobName = payload.job or getJobName(src)
    if not jobName or not hasBossAccess(src, jobName) then
        return { ok = false, message = locale('no_access'), type = 'error' }
    end

    local actorName = getPlayerNameFull(src)

    if action == 'deposit' then
        local amount = math.floor(tonumber(payload.amount) or 0)
        if amount <= 0 then return { ok = false, message = locale('invalid_amount'), type = 'error' } end
        if getCash(src) < amount then return { ok = false, message = locale('not_enough_cash'), type = 'error' } end
        if not removeCash(src, amount) then return { ok = false, message = locale('not_enough_cash'), type = 'error' } end
        addSocietyMoney(jobName, amount)
        logAction(jobName, 'deposit', actorName, '', amount, nil)
        refreshForJob(jobName)
        return { ok = true, message = locale('deposit_success', Config.Currency, moneyFormat(amount)), type = 'success' }
    elseif action == 'withdraw' then
        local amount = math.floor(tonumber(payload.amount) or 0)
        if amount <= 0 then return { ok = false, message = locale('invalid_amount'), type = 'error' } end
        local balance = select(1, getSocietyMoney(jobName))
        if balance < amount then return { ok = false, message = locale('not_enough_funds'), type = 'error' } end
        if not removeSocietyMoney(jobName, amount) then return { ok = false, message = locale('not_enough_funds'), type = 'error' } end
        addCash(src, amount)
        logAction(jobName, 'withdraw', actorName, '', amount, nil)
        refreshForJob(jobName)
        return { ok = true, message = locale('withdraw_success', Config.Currency, moneyFormat(amount)), type = 'success' }
    elseif action == 'hire' then
        local target = tonumber(payload.target)
        if not target or target == src then return { ok = false, message = locale('player_not_found'), type = 'error' } end
        local srcPed, targetPed = GetPlayerPed(src), GetPlayerPed(target)
        if #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed)) > (Config.HireDistance or 3.0) then
            return { ok = false, message = locale('no_nearby'), type = 'error' }
        end
        local targetJob = getJobName(target)
        setJob(target, jobName, 0)
        logAction(jobName, 'hire', actorName, getPlayerNameFull(target), 0, { previousJob = targetJob })
        refreshForJob(jobName)
        return { ok = true, message = locale('hire_success'), type = 'success' }
    elseif action == 'promote' or action == 'demote' then
        local identifier = payload.identifier
        local employee = nil
        for _, data in ipairs(getEmployees(jobName)) do
            if data.identifier == identifier then employee = data break end
        end
        if not employee then return { ok = false, message = locale('player_not_found'), type = 'error' } end
        if identifier == getIdentifier(src) then return { ok = false, message = locale('self_action'), type = 'error' } end
        local maxGrade = getMaxGrade(jobName)
        local requestedGrade = tonumber(payload.grade)
        local newGrade = requestedGrade or (employee.grade + (action == 'promote' and 1 or -1))
        if newGrade < 0 or newGrade > maxGrade or newGrade == employee.grade then return { ok = false, message = locale('grade_limit'), type = 'error' } end
        if action == 'promote' and newGrade < employee.grade then return { ok = false, message = locale('grade_limit'), type = 'error' } end
        if action == 'demote' and newGrade > employee.grade then return { ok = false, message = locale('grade_limit'), type = 'error' } end
        if employee.source then setJob(employee.source, jobName, newGrade) else setOfflineJob(identifier, jobName, newGrade) end
        logAction(jobName, action, actorName, employee.name, 0, { from = employee.grade, to = newGrade })
        refreshForJob(jobName)
        return { ok = true, message = locale(action == 'promote' and 'promote_success' or 'demote_success'), type = 'success' }
    elseif action == 'fire' then
        local identifier = payload.identifier
        local employee = nil
        for _, data in ipairs(getEmployees(jobName)) do
            if data.identifier == identifier then employee = data break end
        end
        if not employee then return { ok = false, message = locale('player_not_found'), type = 'error' } end
        if identifier == getIdentifier(src) then return { ok = false, message = locale('self_action'), type = 'error' } end
        if employee.source then
            setJob(employee.source, 'unemployed', 0)
        else
            setOfflineJob(identifier, 'unemployed', 0)
        end
        closeDutySessionByIdentifier(identifier, employee.name)
        if Config.DefaultPaymentAfterFire and Config.DefaultPaymentAfterFire > 0 and employee.source then
            addCash(employee.source, Config.DefaultPaymentAfterFire)
        end
        logAction(jobName, 'fire', actorName, employee.name, Config.DefaultPaymentAfterFire or 0, nil)
        refreshForJob(jobName)
        return { ok = true, message = locale('fire_success'), type = 'success' }
    elseif action == 'refresh' then
        return { ok = true, message = 'Refreshed.', type = 'success' }
    elseif action == 'bonus' then
        local identifier = payload.identifier
        local amount = math.floor(tonumber(payload.amount) or 0)
        if amount <= 0 then return { ok = false, message = locale('invalid_amount'), type = 'error' } end
        local employee = nil
        for _, data in ipairs(getEmployees(jobName)) do
            if data.identifier == identifier then employee = data break end
        end
        if not employee then return { ok = false, message = locale('player_not_found'), type = 'error' } end
        local balance = select(1, getSocietyMoney(jobName))
        if balance < amount then return { ok = false, message = locale('not_enough_funds'), type = 'error' } end
        if not removeSocietyMoney(jobName, amount) then return { ok = false, message = locale('not_enough_funds'), type = 'error' } end
        if employee.source then
            addCash(employee.source, amount)
        else
            local extra = { bonus = true, identifier = identifier }
            logAction(jobName, 'bonus_offline', actorName, employee.name, amount, extra)
            refreshForJob(jobName)
            return { ok = true, message = ('Bonus recorded for %s (%s%s). Player must be online to receive it instantly.'):format(employee.name, Config.Currency, moneyFormat(amount)), type = 'success' }
        end
        logAction(jobName, 'bonus', actorName, employee.name, amount, nil)
        refreshForJob(jobName)
        return { ok = true, message = ('Bonus paid to %s for %s%s.'):format(employee.name, Config.Currency, moneyFormat(amount)), type = 'success' }
    end

    return { ok = false, message = 'Unknown action.', type = 'error' }
end)

RegisterNetEvent(Prefix .. ':server:toggleDuty', function(jobName)
    local src = source
    local playerJob = getJobName(src)
    local targetJob = jobName or playerJob
    if not targetJob or playerJob ~= targetJob then return end
    local player = getPlayer(src)
    if not player then return end
    if Framework == 'qb' then
        local wasOnDuty = player.PlayerData.job.onduty == true
        local newState = not wasOnDuty
        player.Functions.SetJobDuty(newState)
        if newState then
            beginDutySession(src, targetJob)
        else
            closeDutySessionByIdentifier(getIdentifier(src), getPlayerNameFull(src))
        end
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = newState and locale('duty_on') or locale('duty_off'), position = 'top' })
        refreshForJob(targetJob)
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = locale('duty_unavailable'), position = 'top' })
    end
end)

lib.callback.register(Prefix .. ':server:getDutyPointData', function(src, jobName)
    while not Framework do Wait(100) end
    local currentJob = getJobName(src)
    jobName = jobName or currentJob
    if not jobName or currentJob ~= jobName then
        return { ok = false, message = locale('invalid_job') }
    end
    return {
        ok = true,
        job = jobName,
        label = getJobLabel(jobName),
        summary = getDutySummary(getIdentifier(src), jobName),
        onDuty = Framework == 'qb' and (getJobData(src) and getJobData(src).onduty == true) or false
    }
end)

AddEventHandler('playerDropped', function()
    local src = source
    local identifier = getIdentifier(src)
    if identifier then
        local jobs = closeDutySessionByIdentifier(identifier, GetPlayerName(src) or 'Unknown') or {}
        for i = 1, #jobs do
            refreshForJob(jobs[i])
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local rows = MySQL.query.await('SELECT * FROM rs_bossmenu_active_duty') or {}
    local now = getUnix()
    for i = 1, #rows do
        local row = rows[i]
        local duration = math.max(0, now - (tonumber(row.started_at) or now))
        if duration > 0 then
            MySQL.insert.await('INSERT INTO rs_bossmenu_duty_sessions (job_name, identifier, player_name, started_at, ended_at, duration) VALUES (?, ?, ?, ?, ?, ?)', {
                row.job_name, row.identifier, row.player_name, row.started_at, now, duration
            })
        end
    end
    MySQL.query.await('DELETE FROM rs_bossmenu_active_duty')
end)
