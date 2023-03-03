MecanoF6Menu = false
MenuClothesMechanic = false
MenuActionsPrinciMechanic = false

vehicleADiagno = nil
vehiclePropsADiagno  = nil
coordVehADiagno = nil
local currentTask = {}
local oilLevel = nil
local temperature = nil
local pressionFrein = nil
local vieFrein = nil
local vieMoteur = nil
local vieReservoir = nil
local CurrentRPM = nil
local compressionSuspension = nil
local IsChecking = false
local isRecolting = false
local isCrafting = false
local RecolteMenuMechanic = false
local TransfoMenuMechanic = false
NPCOnJobMechanic = false




RMenu.Add("mecanoMenu", "mecanoMenu_main", RageUI.CreateMenu("Mécano", "Choisissez une action."))
RMenu:Get("mecanoMenu", "mecanoMenu_main"):SetStyleSize(0)
RMenu:Get("mecanoMenu", "mecanoMenu_main").Closed = function()
    MecanoF6Menu = false
    EndVehCam()
end

RMenu.Add('mecano_citizens', 'mecano_citizens_main', RageUI.CreateSubMenu(RMenu:Get('mecanoMenu', 'mecanoMenu_main'), "Intéractions citoyens", "Actions disponibles"))
RMenu:Get("mecano_citizens", "mecano_citizens_main"):SetStyleSize(0)
RMenu:Get('mecano_citizens', 'mecano_citizens_main').Closed = function()
end

RMenu.Add('mecano_veh', 'mecano_veh_main', RageUI.CreateSubMenu(RMenu:Get('mecanoMenu', 'mecanoMenu_main'), "Intéractions véhicules", "Actions disponibles"))
RMenu:Get("mecano_veh", "mecano_veh_main"):SetStyleSize(0)
RMenu:Get('mecano_veh', 'mecano_veh_main').Closed = function()
end


RMenu.Add('mecano_diagno', 'mecano_diagno_main', RageUI.CreateSubMenu(RMenu:Get('mecano_veh', 'mecano_veh_main'), "Diagnostic", "Diagnostic en cours.."))
RMenu:Get("mecano_diagno", "mecano_diagno_main"):SetStyleSize(0)
RMenu:Get('mecano_diagno', 'mecano_diagno_main').Closed = function()
    MecanoF6Menu = false
    EndVehCam()
end


RMenu.Add('mecano_announce', 'mecano_announce_main', RageUI.CreateSubMenu(RMenu:Get('mecanoMenu', 'mecanoMenu_main'), "Annonces", "Actions disponibles"))
RMenu:Get("mecano_announce", "mecano_announce_main"):SetStyleSize(0)
RMenu:Get('mecano_announce', 'mecano_announce_main').Closed = function()
end

local function Arrondis(num, dec)
    local aprdecimal = 10^(dec or 0)
    return math.floor(num * aprdecimal + 0.5) / aprdecimal
end

local function GetVehicleCaracteristique(vehiculePrisEnCharge)

    oilLevel = nil
    temperature = nil
    pressionFrein = nil
    vieFrein = nil
    vieMoteur = nil
    vieReservoir = nil
    CurrentRPM = nil
    compressionSuspension = nil

    Citizen.SetTimeout(2500, function()
        oilLevel = Arrondis(GetVehicleOilLevel(vehiculePrisEnCharge), 2)
    end)
    
    Citizen.SetTimeout(5000, function()
        temperature = Arrondis(GetVehicleEngineTemperature(vehiculePrisEnCharge), 2)
    end)
    
    Citizen.SetTimeout(7500, function()
        vieFrein = Arrondis(((GetVehicleWheelHealth(vehiculePrisEnCharge, 1))/10), 2)
    end)

    Citizen.SetTimeout(10000, function()
        vieMoteur = Arrondis(((GetVehicleEngineHealth(vehiculePrisEnCharge))/10), 2)
    end)

    Citizen.SetTimeout(12500, function()
        vieReservoir = Arrondis(((GetVehiclePetrolTankHealth(vehiculePrisEnCharge))/10), 2)
    end)

end

local function IsInDiagno()
    TaskStartScenarioInPlace(PlayerPedId(), 'PROP_HUMAN_BUM_BIN', 0, true)
    Citizen.CreateThread(function()
        Wait(12500)
        ClearPedTasksImmediately(PlayerPedId())
        ESX.ShowNotification('~g~Vérifications terminées')
        EndVehCam()
        IsChecking = false
    end)
end

function openMecanoMenuPrincipal()
    if not MecanoF6Menu then
        MecanoF6Menu = true
        RageUI.Visible(RMenu:Get('mecanoMenu', 'mecanoMenu_main'), true)
        local fps = ESX.PlayerData.job.grade_name
        Citizen.CreateThread(function()
            while MecanoF6Menu do
                RageUI.IsVisible(RMenu:Get("mecanoMenu",'mecanoMenu_main'),true,true,true,function()
                    RageUI.Separator("↓ ~b~Statut de service ~s~↓")
                    RageUI.Checkbox("Statut de service", nil, InServiceMecano, { Style = RageUI.CheckboxStyle.Tick }, function(Hovered, Selected, Active, Checked)
                        InServiceMecano = Checked;
                    end, function()
                        InServiceMecano = true
                    end, function()
                        InServiceMecano = false
                    end)

                    if InServiceMecano then
                        RageUI.Separator("↓ ~y~Interactions ~s~↓")

                        RageUI.ButtonWithStyle("Interaction véhicules", nil, { RightLabel = "→" }, true, function()
                        end, RMenu:Get('mecano_veh', 'mecano_veh_main'))
                        
                        
                    end
                end, function()    
                end, 1)

                

                RageUI.IsVisible(RMenu:Get("mecano_veh",'mecano_veh_main'),true,true,true,function()

                    -- Code divers et varié (privé)

                    RageUI.Separator("↓ ~o~Réparations ~s~↓")
                            
                    RageUI.ButtonWithStyle("Effectuer un diagnostic", nil, { RightLabel = nil }, true, function(_,_,s)
                        if s then
                            vehicleADiagno = ESX.Game.GetVehicleInDirection()
                            vehiclePropsADiagno  = ESX.Game.GetVehicleProperties(vehicleADiagno)
                            coordVehADiagno = GetEntityCoords(vehicleADiagno)

                            if vehicleADiagno ~= nil then
                                local engineToDiagno = GetEntityBoneIndexByName(vehicleADiagno, 'engine')
                                local coords = GetWorldPositionOfEntityBone(vehicleADiagno, engineToDiagno)
                                local capotOuvert = GetVehicleDoorAngleRatio(vehicleADiagno, 4) 

                                if capotOuvert ~= 0 then
                                    if #(GetEntityCoords(PlayerPedId()) - coords) <= 1.5 then
                                        if not IsChecking then
                                            GetVehicleCaracteristique(vehicleADiagno)
                                            CreateCamVeh(coordVehADiagno)
                                            IsChecking = true
                                            IsInDiagno()
                                            RageUI.Visible(RMenu:Get('mecano_diagno', 'mecano_diagno_main'), true)
                                        else
                                            ESX.ShowNotification('~r~Action déjà en cours.\n~o~Merci de patienter et réessayer.')
                                        end
                                    else
                                        ESX.ShowNotification('~r~Vous devez être face au moteur pour faire les vérifications')
                                    end
                                else
                                    ESX.ShowNotification('~r~Le capot doit être ouvert !')
                                end
                            else
                                ESX.ShowNotification('~r~Aucun véhicule détecté près de vous.\n~o~Veuillez réessayer.')
                            end
                        end
                    end)



                end, function()    
                end, 1)


                RageUI.IsVisible(RMenu:Get("mecano_diagno",'mecano_diagno_main'),true,true,true,function()

                    if oilLevel == nil then
                        RageUI.Separator('')
                        RageUI.Separator('~o~Vérification du niveau d\'huile')
                        RageUI.Separator('')
                    elseif oilLevel <= 2.1 then
                        RageUI.Separator('~r~Niveau d\'huile insuffisant : ~s~'..oilLevel..' ml')
                    else
                        RageUI.Separator('~g~Niveau d\'huile : ~s~'..oilLevel..' ml')
                    end
                        
                    if oilLevel ~= nil then
                        if temperature == nil then
                            RageUI.Separator('')
                            RageUI.Separator('~o~Vérification de la température du moteur')
                            RageUI.Separator('')
                        elseif temperature >= 90 then
                            RageUI.Separator('~r~Température trop élevée : ~s~'..temperature..' °C')
                        else
                            RageUI.Separator('~g~Température : ~s~'..temperature..' °C')
                        end
                    end

                    if temperature ~= nil then
                        if vieFrein == nil then
                            RageUI.Separator('')
                            RageUI.Separator('~o~Vérification de l\'état des freins')
                            RageUI.Separator('')
                        elseif vieFrein <= 30 then
                            RageUI.Separator('~r~Freins endommagés : ~s~'..vieFrein..' %')
                        else
                            RageUI.Separator('~g~Etat des freins : ~s~'..vieFrein..' %')
                        end
                    end
                    
                    if vieFrein ~= nil then
                        if vieMoteur == nil then
                            RageUI.Separator('')
                            RageUI.Separator('~o~Vérification de l\'état du moteur')
                            RageUI.Separator('')
                        elseif vieMoteur <= 30 then
                            RageUI.Separator('~r~Moteur endommagé : ~s~'..vieMoteur..' %')
                        else
                            RageUI.Separator('~g~Etat du moteur : ~s~'..vieMoteur..' %')
                        end
                    end

                    if vieMoteur ~= nil then
                        if vieReservoir == nil then
                            RageUI.Separator('')
                            RageUI.Separator('~o~Vérification de l\'état du réservoir')
                            RageUI.Separator('')
                        elseif vieReservoir <= 30 then
                            RageUI.Separator('~r~Réservoir endommagé : ~s~'..vieReservoir..' %')
                        else
                            RageUI.Separator('~g~Etat du réservoir : ~s~'..vieReservoir..' %')
                        end
                    end


                    if vieReservoir ~= nil then 
                        if vieReservoir <= 30 or vieMoteur <= 30 or vieFrein <= 30 or temperature >= 90 or oilLevel <= 3 then
                            if vieReservoir <= 30 and vieMoteur <= 30 and vieFrein <= 30 and temperature >= 90 and oilLevel <= 3 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~La voiture doit être réparée dans l\'immédiat.')
                                RageUI.Separator('~r~Énormément de soucis majeurs ont été identifiés.')
                            elseif vieReservoir <= 30 and vieMoteur <= 30 and vieFrein <= 30 and temperature >= 90 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~La voiture doit être réparée dans l\'immédiat.')
                                RageUI.Separator('~r~Énormément de soucis majeurs ont été identifiés.')
                            elseif vieReservoir <= 30 and vieMoteur <= 30 and vieFrein <= 30 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~La voiture doit être réparée dans l\'immédiat.')
                                RageUI.Separator('~r~Énormément de soucis majeurs ont été identifiés.')
                            elseif vieReservoir <= 30 and vieMoteur <= 30 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~La voiture doit être réparée dans l\'immédiat.')
                                RageUI.Separator('~r~Deux soucis majeurs ont été identifiés.')
                            elseif temperature >= 90 and vieMoteur <= 30 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~La voiture doit être réparée dans l\'immédiat.')
                                RageUI.Separator('~r~Deux soucis majeurs ont été identifiés.')
                            elseif vieReservoir <= 30 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~Le réservoir est endommagé.')
                                RageUI.Separator('~r~Il doit être changé.')
                            elseif vieMoteur <= 30 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~Le moteur de la voiture est endommagé.')
                                RageUI.Separator('~r~Il doit être changé.')
                            elseif vieFrein <= 30 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~Les freins de la voiture sont endommagés.')
                                RageUI.Separator('~r~Ils doivent être changés.')
                            elseif vieReservoir <= 30 or vieMoteur <= 30 or vieFrein <= 30 or temperature >= 90 or oilLevel <= 3 then
                                RageUI.Separator('')
                                RageUI.Separator('Bilan de votre diagnostic')
                                RageUI.Separator('~r~Le véhicule doit être réparé au plus vite.')
                                RageUI.Separator('~r~Problème(s) majeur(s) identifié(s)')
                            end
                        else
                            RageUI.Separator('')
                            RageUI.Separator('Bilan de votre diagnostic')
                            RageUI.Separator('~g~Aucun problème mécanique découvert.')
                            RageUI.Separator('~o~Essayez de regarder la carrosserie.')
                        end
                    end

                end, function()    
                end, 1)

                Wait(1)
            end

        Wait(0)
        MecanoF6Menu = false
        end)
    end
end


function CreateCamVeh(coords)
    Citizen.CreateThread(function()
        ClearFocus()

        local playerPed = PlayerPedId()

        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords.x, coords.y, coords.z + 7, 0, 0, 0, GetGameplayCamFov())
        SetCamRot(cam, 270.0, 0.0, 0)
        ShakeCam(cam, "DRUNK_SHAKE", 0.2)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 1500, true, false)
    end)
end 

function EndVehCam()
    Citizen.CreateThread(function()
        ClearFocus()
		SetTimecycleModifier('')
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end)
end

RegisterCommand('openMecanoMenuPrincipal', function()
	if ESX.IsPlayerLoaded() then
		if GetEntityHealth(PlayerPedId()) > 0 and ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
			openMecanoMenuPrincipal()
		end
	end
end, false)
  
RegisterKeyMapping('openMecanoMenuPrincipal', 'Menu Mécano', 'keyboard', 'F6')
