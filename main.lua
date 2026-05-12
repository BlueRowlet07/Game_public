local love = require "love"
local camera = require "libraries/camera"
local wf = require "libraries/windfield"
local anim8 = require "libraries/anim8"
local sti = require "libraries/sti"
local Player = require "player"
local Map = require "map"
local Skeleton1 = require "skeleton1"

local player = {}
local enemies = {}
local spawn = {}
local map = {}

world = wf.newWorld(0, 0) -- creates a new windfield world with no gravity
cam = camera(nil, nil, 2) -- creates a new camera with 2x zoom
gameMap = sti("maps/testmap.lua")


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest") -- when scale up graphics, no blurring, scales pixels up

    map = Map() map:Collisions() map:Build(spawn)
    player = Player(1200, 620) player:Hitbox() player:Load_Animations()
end


function love.update(dt)
    for i, obj in pairs(spawn) do
        if obj then
            obj:Hitbox()
            obj:Load_Animations()
            table.insert(enemies, obj)
            table.remove(spawn, i)
        end
    end

    if enemies then
        local count = 0
        for i, obj in pairs(enemies) do
            if obj.despawn == true then
                count = count + 1
            end
        end
        if count == #enemies then
            player.keys = player.keys + 1
            enemies = nil
        end
    end

    if enemies then
        for i, obj in pairs(enemies) do
            if obj then
                obj:Update(dt)

                if obj.took_dmg == false and obj.is_attacking == false and obj.life ~= 0 and obj.dead == false then
                    if obj.player_detected == false then
                        obj:Update_Movement(player.x, player.y)
                    end
                end
                if obj.took_dmg == false then
                    obj:Player_Detect(dt, player)
                end

                obj:Death(dt, player)
            end
        end
    end

    if player.is_attacking == false and player.took_dmg == false and player.dead == false then
        player:Update_Movement(player)
    end

    if player.dead == false then
        player:Attack(dt)
        player:Bow(dt)
        player:Arrow_update()
        player:Pickup()
    end
    player:Death(dt)
    player:Update(dt)

    map:Map_update()

    cam:lookAt(player.x, player.y)

    world:update(dt)
    --world:setQueryDebugDrawing(true) -- debug
end


function love.draw()
    cam:attach()
        map:Draw()
        player:Draw()
        --world:draw() -- debug
        if enemies then
            for i, obj in pairs(enemies) do
                if obj then
                    obj:Draw()
                end
            end
        end
    cam:detach()
end


function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and not player.is_attacking then
        player:Attack_prep(x)
    end
    if button == 2 and not player.is_attacking then
        player:Bow_prep(x)
    end
end