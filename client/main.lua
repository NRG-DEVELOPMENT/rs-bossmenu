local Core, Framework = nil, nil
local Prefix = Config.EventPrefix or 'rs-bossmenu'
local PlayerData = {}
local IsOpen = false
local CurrentJob = nil
local DutyUiOpen = false

local function setFramework()
    if Config.Framework == 'qbcore' or Config.Framework == 'qb' or (Config.Framework == 'auto' and GetResourceState('qb-core') == 'started') then
        Core = exports['qb-core']:GetCoreObject()
        Framework = 'qb'
    elseif Config.Framework == 'esx' or (Config.Framework == 'auto' and GetResourceState('es_extended') == 'started') then
        Core = exports['es_extended']:getSharedObject()
        Framework = 'esx'
    end
end

local function syncPlayerData()
    if Framework == 'qb' then
        PlayerData = Core.Functions.GetPlayerData() or {}
    elseif Framework == 'esx' then
        PlayerData = Core.GetPlayerData() or {}
    end
end

local function notify(description, type)
    lib.notify({ description = description, type = type or 'inform', position = 'top' })
end

local function getJobName()
    return PlayerData.job and PlayerData.job.name or nil
end

local function detectInventory()
    local preferred = string.lower(Config.InventorySystem or 'auto')
    if preferred ~= 'auto' then
        return preferred
    end
    if GetResourceState(Config.Inventory.stashes.ox or 'ox_inventory') == 'started' then
        return 'ox_inventory'
    end
    if GetResourceState(Config.Inventory.stashes.qb or 'qb-inventory') == 'started' then
        return 'qb-inventory'
    end
    return 'none'
end

local function detectClothing()
    local preferred = string.lower(Config.ClothingSystem or 'auto')
    if preferred ~= 'auto' then
        return preferred
    end
    if GetResourceState('illenium-appearance') == 'started' then
        return 'illenium-appearance'
    end
    if GetResourceState('qb-clothing') == 'started' then
        return 'qb-clothing'
    end
    return 'none'
end

local function openMenu(jobName)
    local response = lib.callback.await(Prefix .. ':server:openMenu', false, jobName or getJobName())
    if not response then return end
    if response.message then
        return notify(response.message, response.type)
    end
    CurrentJob = response.job
    DutyUiOpen = false
    IsOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'open', data = response })
end

local function closeMenu(push)
    IsOpen = false
    DutyUiOpen = false
    SetNuiFocus(false, false)
    if push then SendNUIMessage({ action = 'close' }) end
end

local function getStashId(jobName)
    local prefix = (Config.Inventory and Config.Inventory.stashes and Config.Inventory.stashes.prefix) or 'bossstash_'
    return ('%s%s'):format(prefix, jobName)
end

local function openSocietyStash(jobName)
    local inventory = detectInventory()
    if inventory == 'ox_inventory' and GetResourceState(Config.Inventory.stashes.ox or 'ox_inventory') == 'started' then
        exports[Config.Inventory.stashes.ox or 'ox_inventory']:openInventory('stash', getStashId(jobName))
        return true
    end
    if inventory == 'qb-inventory' and GetResourceState(Config.Inventory.stashes.qb or 'qb-inventory') == 'started' then
        local stashConfig = (Config.JobLocations[jobName] and Config.JobLocations[jobName].stash) or {}
        local stashId = getStashId(jobName)
        TriggerEvent('inventory:client:SetCurrentStash', stashId)
        TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId, {
            maxweight = stashConfig.maxWeight or Config.Inventory.stashes.defaultMaxWeight or 400000,
            slots = stashConfig.slots or Config.Inventory.stashes.defaultSlots or 100,
            label = stashConfig.label or Config.Inventory.stashes.defaultLabel or 'Society Stash'
        })
        return true
    end
    return false
end

local function openWardrobe()
    local clothing = detectClothing()
    if clothing == 'illenium-appearance' and GetResourceState('illenium-appearance') == 'started' then
        TriggerEvent((Config.Wardrobe and Config.Wardrobe.illeniumEvent) or 'illenium-appearance:client:openOutfitMenu')
        return true
    end
    if clothing == 'qb-clothing' and GetResourceState('qb-clothing') == 'started' then
        TriggerEvent((Config.Wardrobe and Config.Wardrobe.qbClothingEvent) or 'qb-clothing:client:openOutfitMenu')
        return true
    end
    return false
end


local function openDutyPointMenu(jobName)
    local response = lib.callback.await(Prefix .. ':server:getDutyPointData', false, jobName or getJobName())
    if not response or not response.ok then
        return notify((response and response.message) or 'Unable to load duty data.', 'error')
    end
    CurrentJob = response.job
    IsOpen = false
    DutyUiOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'openDuty', data = response })
end

CreateThread(function()
    setFramework()
    while not Framework do
        Wait(500)
        setFramework()
    end
    syncPlayerData()

    if Config.UseTarget then
        if Config.TargetSystem == 'ox-target' and GetResourceState('ox_target') == 'started' then
            for job, data in pairs(Config.JobLocations or {}) do
                for i = 1, #(data.bossCoords or {}) do
                    exports.ox_target:addSphereZone({
                        coords = data.bossCoords[i],
                        radius = 1.15,
                        options = {
                            {
                                name = ('rs_bossmenu_%s_%s'):format(job, i),
                                icon = 'fa-solid fa-briefcase',
                                label = 'Open Boss Menu',
                                onSelect = function()
                                    openMenu(job)
                                end
                            }
                        }
                    })
                end
                for i = 1, #(data.dutyCoords or {}) do
                    exports.ox_target:addSphereZone({
                        coords = data.dutyCoords[i],
                        radius = 1.15,
                        options = {
                            {
                                name = ('rs_dutymenu_%s_%s'):format(job, i),
                                icon = 'fa-solid fa-user-clock',
                                label = 'Open Duty Menu',
                                onSelect = function()
                                    openDutyPointMenu(job)
                                end
                            }
                        }
                    })
                end
            end
        elseif Config.TargetSystem == 'qb-target' and GetResourceState('qb-target') == 'started' then
            for job, data in pairs(Config.JobLocations or {}) do
                for i = 1, #(data.bossCoords or {}) do
                    exports['qb-target']:AddCircleZone(('rs_bossmenu_%s_%s'):format(job, i), data.bossCoords[i], 1.15, {
                        useZ = true,
                        name = ('rs_bossmenu_%s_%s'):format(job, i)
                    }, {
                        options = {
                            {
                                icon = 'fa-solid fa-briefcase',
                                label = 'Open Boss Menu',
                                action = function()
                                    openMenu(job)
                                end
                            }
                        },
                        distance = 1.5
                    })
                end
                for i = 1, #(data.dutyCoords or {}) do
                    exports['qb-target']:AddCircleZone(('rs_dutymenu_%s_%s'):format(job, i), data.dutyCoords[i], 1.15, {
                        useZ = true,
                        name = ('rs_dutymenu_%s_%s'):format(job, i)
                    }, {
                        options = {
                            {
                                icon = 'fa-solid fa-user-clock',
                                label = 'Open Duty Menu',
                                action = function()
                                    openDutyPointMenu(job)
                                end
                            }
                        },
                        distance = 1.5
                    })
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        if Config.UseMarkers then
            local sleep = 1000
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local currentJob = getJobName()
            if currentJob and Config.JobLocations[currentJob] then
                for _, point in ipairs(Config.JobLocations[currentJob].bossCoords or {}) do
                    local dist = #(coords - point)
                    if dist <= (Config.MarkerDistance or 10.0) then
                        sleep = 0
                        DrawMarker(Config.MarkerId or 21, point.x, point.y, point.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerScale.x, Config.MarkerScale.y, Config.MarkerScale.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, Config.MarkerColor.a, false, false, 2, false, nil, nil, false)
                        if dist <= 1.5 then
                            lib.showTextUI('[E] Open Boss Menu')
                            if IsControlJustReleased(0, 38) then
                                openMenu(currentJob)
                            end
                        else
                            lib.hideTextUI()
                        end
                    end
                end
            else
                lib.hideTextUI()
            end
            Wait(sleep)
        else
            Wait(1500)
        end
    end
end)

if Config.UseCommand then
    RegisterCommand(Config.OpenBossMenuCommand, function()
        openMenu()
    end, false)
    RegisterKeyMapping(Config.OpenBossMenuCommand, 'Open Boss Menu', 'keyboard', Config.OpenBossMenuKey or 'F6')
end

if Config.UseTimeSheetCommand then
    RegisterCommand(Config.TimeSheetCommand or 'timesheet', function()
        local jobName = getJobName()
        if not jobName then return end
        local dutyData = lib.callback.await(Prefix .. ':server:getDutyPointData', false, jobName)
        if dutyData and dutyData.ok then
            CurrentJob = dutyData.job
            IsOpen = false
            DutyUiOpen = true
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(false)
            SendNUIMessage({ action = 'openDuty', data = dutyData })
            return
        end
        notify((dutyData and dutyData.message) or 'Unable to load duty data.', 'error')
    end, false)
end

exports('OpenBossMenu', function(jobName)
    openMenu(jobName)
    return true
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', syncPlayerData)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer or {}
end)
RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
end)
RegisterNetEvent(Prefix .. ':client:refresh', function(jobName)
    if (not IsOpen and not DutyUiOpen) or CurrentJob ~= jobName then return end
    local response = lib.callback.await(Prefix .. ':server:openMenu', false, jobName)
    if response and not response.message then
        if IsOpen then
            SendNUIMessage({ action = 'refresh', data = response })
        end
    end
    if DutyUiOpen then
        local dutyData = lib.callback.await(Prefix .. ':server:getDutyPointData', false, jobName)
        if dutyData and dutyData.ok then
            SendNUIMessage({ action = 'openDuty', data = dutyData })
        end
    end
end)

RegisterNUICallback('close', function(_, cb)
    closeMenu(true)
    cb(1)
end)

RegisterNUICallback('action', function(data, cb)
    local action = data.action
    if action == 'stash' then
        closeMenu(true)
        Wait(150)
        local ok = openSocietyStash(CurrentJob or data.job)
        if not ok then
            notify(Locales[Config.Locale].stash_unavailable or 'Stash integration is unavailable.', 'error')
        end
        cb({ ok = ok })
        return
    elseif action == 'wardrobe' then
        closeMenu(true)
        Wait(150)
        local ok = openWardrobe()
        if not ok then
            notify(Locales[Config.Locale].wardrobe_unavailable or 'Wardrobe integration is unavailable.', 'error')
        end
        cb({ ok = ok })
        return
    elseif action == 'duty' then
        TriggerServerEvent(Prefix .. ':server:toggleDuty', CurrentJob or data.job)
        if DutyUiOpen then
            Wait(150)
            local dutyData = lib.callback.await(Prefix .. ':server:getDutyPointData', false, CurrentJob or data.job)
            if dutyData and dutyData.ok then
                SendNUIMessage({ action = 'openDuty', data = dutyData })
            end
        end
        cb({ ok = true })
        return
    elseif action == 'viewDuty' then
        local dutyData = lib.callback.await(Prefix .. ':server:getDutyPointData', false, CurrentJob or data.job)
        if dutyData and dutyData.ok then
            CurrentJob = dutyData.job
            IsOpen = false
            DutyUiOpen = true
            SendNUIMessage({ action = 'openDuty', data = dutyData })
            cb({ ok = true })
            return
        end
        notify((dutyData and dutyData.message) or 'Unable to load duty data.', 'error')
        cb({ ok = false })
        return
    end

    local response = lib.callback.await(Prefix .. ':server:nuiAction', false, data)
    if response and response.message then
        notify(response.message, response.type)
    end
    if response and response.ok and CurrentJob then
        local refresh = lib.callback.await(Prefix .. ':server:openMenu', false, CurrentJob)
        if refresh and not refresh.message then
            SendNUIMessage({ action = 'refresh', data = refresh })
        end
    end
    cb(response or { ok = false })
end)
