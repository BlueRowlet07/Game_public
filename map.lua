local love = require "love"
local Enemies = require "skeleton1"

-- three functions so i don't have to copy paste the same function with different values
Destroy_on_impact = function(collision_class, tbl) -- loops through the whole table and destroys the "Body" of object that got in contact with the player
    for i, obj in pairs(tbl) do
        if obj then
            if obj:enter(collision_class) then
                obj:destroy()
                table.remove(tbl, i)
            end
        end
    end
end

Draw_Type = function (table, drawable) -- loops through the whole table and draws the "drawable" at its position
    for i, obj in pairs(table) do
        if obj then
            love.graphics.draw(drawable, obj.x, obj.y)
        end
    end
end

Build_Type = function(gamemap_layer, tbl, collision_class, collider_type) -- fills the related table with all its content for each "gamemap_layer", checks how to create and creates the collider
    if gameMap.layers[gamemap_layer] then
        for i, obj in pairs(gameMap.layers[gamemap_layer].objects) do
            if collider_type == "newRectangleCollider" then
                -- create body and set it to itself
                local name = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                name:setType('static')
                name:setObject(name)
                name:setCollisionClass(collision_class)
                -- all the content of obj
                name.x = obj.x
                name.y = obj.y
                if obj.properties["Port"] then
                    name.port = obj.properties["Port"]
                end
                if obj.properties["Price"] then
                    name.price = obj.properties["Price"]
                end
                if obj.properties["Item"] then
                    name.item = obj.properties["Item"]
                end
                if obj.properties["Hit"] ~= nil then
                    name.hit = obj.properties["Hit"]
                end
                -- insert all content into table
                table.insert(tbl, name)
            elseif collider_type == "newCircleCollider" then
                -- create body and set it to itself
                local name =  world:newCircleCollider(obj.x + 8, obj.y + 8, obj.width / 3.5) 
                name:setType('static')
                name:setObject(name)
                name:setCollisionClass(collision_class)
                -- all the content of obj
                name.x = obj.x
                name.y = obj.y
                if obj.properties["Port"] then
                    name.port = obj.properties["Port"]
                end
                if obj.properties["Price"] then
                    name.price = obj.properties["Price"]
                end
                if obj.properties["Item"] then
                    name.item = obj.properties["Item"]
                end
                if obj.properties["Hit"] then
                    name.hit = obj.properties["Hit"]
                end
                -- insert all content into table
                table.insert(tbl, name)
            end
        end
    end
end

function Wrld()
    return {
        -- all the tables needed
        walls = {},
        coins = {},
        health = {},
        speed = {},
        ladder = {},
        secret = {},
        shop = {},

        -- count to check for the secret
        count = 0,

        -- loads all sprites
        coin_pic = love.graphics.newImage("sprites/player/coin.png"),
        heal_potion_pic = love.graphics.newImage("sprites/map/heal_potion.png"),
        speed_potion_pic = love.graphics.newImage("sprites/map/speed_potion.png"),
        candle_on_pic = love.graphics.newImage("sprites/map/candle_on.png"),
        candle_off_pic = love.graphics.newImage("sprites/map/candle_off.png"),
        locked_ladder_pic = love.graphics.newImage("sprites/map/locked_ladder.png"),
        ladder_pic = love.graphics.newImage("sprites/map/ladder.png"),

        Collisions = function()
            -- adds all the collision classes needed
            world:addCollisionClass('Enemy')
            world:addCollisionClass('Player')
            world:addCollisionClass('Wall')
            world:addCollisionClass('Arrow', {ignores = {'All', except = {'Enemy', 'Wall'}}})
            world:addCollisionClass('Player_Attack', {ignores = {'All', except = {'Enemy'}}})
            world:addCollisionClass('Coins')
            world:addCollisionClass('Health')
            world:addCollisionClass('Speed')
            world:addCollisionClass('Ladder')
            world:addCollisionClass('Shop')
        end,

        Build = function(self, spawn)
            -- creates everything for each gamemap_layer
            Build_Type('Walls', self.walls, 'Wall', "newRectangleCollider")
            Build_Type('Health', self.health, 'Health', "newCircleCollider")
            Build_Type('Coins', self.coins, 'Coins', "newCircleCollider")
            Build_Type('Speed', self.speed, 'Speed', "newCircleCollider")
            Build_Type('Shop', self.shop, 'Shop', "newRectangleCollider")
            Build_Type('Candle_secret',self.secret, 'Wall', "newRectangleCollider")

            if gameMap.layers['Ladder'] then
                for i, obj in pairs(gameMap.layers['Ladder'].objects) do
                    if obj.properties["Exists"] ~= false then
                        local ladder = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                        ladder:setType('static')
                        ladder:setObject(ladder)
                        ladder.x = obj.x
                        ladder.y = obj.y
                        ladder.port = obj.properties["Port"]
                        ladder:setCollisionClass('Ladder')
                        table.insert(self.ladder, ladder)
                    end
                end
            end
            -- spawns an enemy for every object in the "Enemies" gamemap_layer at that position
            if gameMap.layers['Enemies'] then
                 for i, obj in pairs(gameMap.layers['Enemies'].objects) do
                    table.insert(spawn, Enemies(obj.x, obj.y))
                 end
            end
        end,

        Map_update = function (self)
            -- destroys body and removes it from table so it does not get drawn
            Destroy_on_impact('Player', self.coins)
            Destroy_on_impact('Player', self.health)
            Destroy_on_impact('Player', self.speed)

            for i, obj in pairs(self.ladder) do
                if obj then
                    if obj:enter('Player') then
                        local player = obj:getEnterCollisionData('Player')
                        player = player.collider:getObject()
                        for j, obj2 in pairs(self.ladder) do -- if player gets in contact with a ladder searches for another 
                        -- ladder in a different position with the same port and moves the players body next to the other ladder with the same port
                            if obj2 then
                                if obj2.x ~= obj.x or obj2.y ~= obj.y then
                                    if obj.port == obj2.port and obj2.port then
                                        player.collider:setPosition(obj2.x - 25, obj2.y + 5)
                                    end
                                end
                            end
                        end
                        if obj.locked then -- unlocks the locked ladder if player has a key
                            if obj:enter('Player') and obj.locked == true and player.keys ~= 0 then
                                player.keys = player.keys - 1
                                obj.locked = false
                            end
                        end
                        if obj:enter('Player') and obj.locked == false and obj.exists == true and obj.win == false then -- makes player win if in contact with unlocked ladder
                            player.won = true
                        end
                    end
                end
            end

             for i, obj in pairs(self.shop) do -- if player collides with hitbox and has enough money either gets a heal effect or a speed effect depending on obj.item
                if obj then
                    if obj:enter('Player') then
                        local player = obj:getEnterCollisionData('Player')
                        player = player.collider:getObject()
                        if obj.price < player.coins then
                            player.coins = player.coins - obj.price
                            if obj.item == "Heal" then
                                player.life = player.life + 1
                            end
                            if obj.item == "Speed" then
                                player.speed = player.speed + 10
                            end
                        end
                    end
                end
            end

            for i, obj in pairs(self.secret) do
                if obj then
                    if obj:enter('Arrow') then
                        if obj.hit == false then
                        self.count = self.count + 1
                        end
                        obj.hit = true
                    end
                    if self.count == #self.secret then
                        for j, obj2 in pairs(gameMap.layers['Ladder'].objects) do
                            if obj2 then
                                if obj.port == obj2.properties["Port"] and obj2.properties["Exists"] == false then -- checks to find the ladder that with a port and exists property in he gamemap_layer and creates it
                                    obj2.properties["Exists"] = true
                                    local laddus = world:newRectangleCollider(obj2.x, obj2.y, obj2.width, obj2.height)
                                    laddus:setType('static')
                                    laddus:setObject(laddus)
                                    laddus.x = obj2.x
                                    laddus.y = obj2.y
                                    laddus.port = obj2.properties["Port"]
                                    laddus.win = obj2.properties["Win"]
                                    laddus.exists = obj2.properties["Exists"]
                                    laddus.locked = obj2.properties["Locked"]
                                    laddus:setCollisionClass('Ladder')
                                    table.insert(self.ladder, laddus)
                                end
                            end
                        end
                    end
                end
            end
        end,

        Draw = function (self) -- draws everything at its position
            gameMap:drawLayer(gameMap.layers["Ground"]) -- draws the whole gamemap_layer out of testmap.lua
            gameMap:drawLayer(gameMap.layers["Objects"])

            Draw_Type(self.coins, self.coin_pic)
            Draw_Type(self.health, self.heal_potion_pic)
            Draw_Type(self.speed, self.speed_potion_pic)

            for i, obj in pairs(self.shop) do
                if obj then
                    love.graphics.print(obj.price, obj.x + 6, obj.y + 10, nil, 0.75, 0.75)
                end
            end

            for i, obj in pairs(self.secret) do
                if obj then
                    if obj.hit == true then
                        love.graphics.draw(self.candle_on_pic, obj.x, obj.y)
                    else
                        love.graphics.draw(self.candle_off_pic, obj.x, obj.y)
                    end
                end
            end

            for i,obj in pairs(self.ladder) do --draws locked_ladder_pic if locked and ladder_pic if not locked
                if obj then
                    if obj.locked == true then
                        love.graphics.draw(self.locked_ladder_pic, obj.x, obj.y)
                        love.graphics.print("it's locked", obj.x -15, obj.y - 15)
                    elseif obj.locked == false then
                        love.graphics.draw(self.ladder_pic, obj.x, obj.y)
                    end
                end
            end
        end
    }
end

return Wrld