-- name: Speedrun Mod
-- description: Reset saves, speedrun timer, works online. Its your all in one coop timer, im building this since beta 29 is taking WAY TOO LONG to come out, so BAM

gGlobalSyncTable.startTimer = 0
gGlobalSyncTable.speedrunTimer = 0
gGlobalSyncTable.beatedGame = false

local startTimer = 4 * 30
local speedrunTimer = 0

--- @param m MarioState
function mario_update(m)

    if m.playerIndex ~= 0 then return end

    if (m.controller.buttonPressed & X_BUTTON) ~= 0 and network_is_server() then
        
        m.numStars = 0
        m.numCoins = 0
        m.numLives = 3

        startTimer = 4 * 30
        gGlobalSyncTable.beatedGame = false

        warp_to_level(gLevelValues.entryLevel, 1, 0)
    end

    if gGlobalSyncTable.startTimer > 0 then
        m.freeze = true

        m.faceAngle.y = m.intendedYaw
        m.health = 0x880

        save_file_erase(get_current_save_file_num()-1)
        save_file_reload()
    end
end

function update()
    if network_is_server() then
        if startTimer > 0 then
            startTimer = startTimer - 1
            gGlobalSyncTable.startTimer = startTimer / 30
            gGlobalSyncTable.speedrunTimer = 0
            speedrunTimer = 0
        else
            if not gGlobalSyncTable.beatedGame then
                speedrunTimer = speedrunTimer + 1
                gGlobalSyncTable.speedrunTimer = speedrunTimer
            end
        end
    end
end

function hud_center_render()

    if gGlobalSyncTable.startTimer <= 0 then
        return
    end

    -- set text
    local text = tostring(math.floor(gGlobalSyncTable.startTimer))

    -- set scale
    local scale = 1

    -- get width of screen and text
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local width = djui_hud_measure_text(text) * scale
    local height = 32 * scale

    local x = (screenWidth - width) / 2.0
    local y = (screenHeight - height) / 2.0

    -- render
    djui_hud_set_color(0, 0, 0, 128);
    djui_hud_render_rect(x - 6 * scale, y, width + 12 * scale, height);

    djui_hud_set_color(255, 255, 255, 255);
    djui_hud_print_text(text, x, y, scale);
end

function hud_bottom_render()

    -- thanks mj for this code
    local minutes = 0
    local Seconds = 0
    local MilliSeconds = 0
    local Hours = 0
    if math.floor(gGlobalSyncTable.speedrunTimer/30/60) < 0 then
        Seconds = math.ceil(gGlobalSyncTable.speedrunTimer/30)
        MilliSeconds = (1000 - math.ceil(gGlobalSyncTable.speedrunTimer/30%1 * 1000)) % 1000
    else
        Hours = math.floor(gGlobalSyncTable.speedrunTimer/30/60/60)
        minutes = math.floor(gGlobalSyncTable.speedrunTimer/30/60%60)
        Seconds = math.floor(gGlobalSyncTable.speedrunTimer/30)%60
        MilliSeconds = math.floor(gGlobalSyncTable.speedrunTimer/30%1 * 1000)
    end

    -- set text
    local text = string.format("%s:%s:%s.%s", string.format("%d", Hours), string.format("%02d", minutes), string.format("%02d", Seconds), string.format("%03d", MilliSeconds))

    -- set scale
    local scale = 0.50

    -- get width of screen and text
    local screenWidth = djui_hud_get_screen_width()
    local screenHeight = djui_hud_get_screen_height()
    local width = djui_hud_measure_text(text) * scale

    local x = (screenWidth - width) / 2.0
    local y = screenHeight - 16

    -- render
    djui_hud_set_color(0, 0, 0, 128);
    djui_hud_render_rect(x - 6, y, width + 12, 16);

    djui_hud_set_color(255, 255, 255, 255);
    djui_hud_print_text(text, x, y, scale);
end

function on_render()
    djui_hud_set_font(FONT_NORMAL)
    djui_hud_set_resolution(RESOLUTION_N64)

    hud_center_render()
    hud_bottom_render()
end

function on_interact(m, o, intee, interacted)
    if get_id_from_behavior(o.behavior) == id_bhvGrandStar then
        gGlobalSyncTable.beatedGame = true
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_HUD_RENDER, on_render)
hook_event(HOOK_ON_INTERACT, on_interact)