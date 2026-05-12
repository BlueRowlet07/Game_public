local love = require "love"
local anim8 = require "libraries/anim8"

Normalize = function(x, y) -- idea from copilot, if player walks vertical and horizontal at the same time he will be about 1.4 times faster because of *MATH* normalzing the Vector fixes that
    local length = math.sqrt(x * x + y * y)
    if length == 0 then
        return 0, 0
    end
    return x / length, y / length
end

function Player(x, y) -- the function that gets returned
    return {
        x = x,
        y = y,
        speed = 100,
        timer = 0,
        keys = 0,
        coins = 0,
        life = 3,
        arrow_speed = 250,
        arrows = {},
        took_dmg = false,
        is_hit = false,
        won = false,
        dead = false,
        horizontal_movement_R = false,
        horizontal_movement_L = false,
        vertical_movement_B = false,
        vertical_movement_T = false,
        is_attacking = false,
        sword_attack = false,
        bow_attack = false,
        right_hit = true,
        is_shot = false,
        is_right = true,

        Hitbox = function(self)  -- creates self collider with all attributes
            self.collider = world:newBSGRectangleCollider(self.x, self.y, 10, 15, 4)
            self.collider:setFixedRotation(true)
            self.collider:setCollisionClass('Player')
            self.collider:setObject(self)
        end,

        Load_Animations = function(self)  --loads all self animations
            self.spriteSheet = love.graphics.newImage("sprites/player/soldier.png")
            self.grid = anim8.newGrid(100, 100, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())

            self.animations = {}

            self.animations.idle = anim8.newAnimation(self.grid("1-6", 1), 0.2)
            self.animations.move = anim8.newAnimation(self.grid("1-8", 2), 0.2)
            self.animations.attack = anim8.newAnimation(self.grid("1-6", 3), 0.1)
            self.animations.bow = anim8.newAnimation(self.grid("1-9", 5), 0.1)
            self.animations.take_damage = anim8.newAnimation(self.grid("1-4", 6), 0.05)
            self.animations.death = anim8.newAnimation(self.grid("1-4", 7), 0.1)

            self.coin_pic = love.graphics.newImage("sprites/player/coin.png")
            self.arrow_pic = love.graphics.newImage("sprites/player/arrow.png")
            self.heart_pic = love.graphics.newImage("sprites/player/heart.png")
            self.key_pic = love.graphics.newImage("sprites/map/gold_key.png")
        end,

         Update = function(self, dt) -- important for the anim8 library so that the animations get updated each frame
            self.animations.attack:update(dt)
            self.animations.death:update(dt)
            self.animations.idle:update(dt)
            self.animations.take_damage:update(dt)
            self.animations.move:update(dt)
            self.animations.bow:update(dt)
        end,

        Update_Movement = function(self)  -- updates self movement and animation based on key input
            self.vx, self.vy = 0, 0

            self.move = self.animations.idle

            if love.keyboard.isDown({ "right", "d" }) == true and self.horizontal_movement_L == false then
                self.vx = self.speed
                self.move = self.animations.move
                self.is_right = true
                self.horizontal_movement_R = true
                if love.keyboard.isDown({ "left", "a" }) == true then
                    self.vx = self.speed * -1
                    self.move = self.animations.move
                    self.is_right = false
                end
            else
                self.horizontal_movement_R = false
            end

            if love.keyboard.isDown({ "left", "a" }) == true and self.horizontal_movement_R == false then
                self.vx = self.speed * -1
                self.move = self.animations.move
                self.is_right = false
                self.horizontal_movement_L = true
                if love.keyboard.isDown({ "right", "d" }) == true then
                    self.vx = self.speed
                    self.move = self.animations.move
                    self.is_right = true
                end
            else
                self.horizontal_movement_L = false
            end

            if love.keyboard.isDown({ "down", "s" }) == true and self.vertical_movement_T == false then
                self.vy = self.speed
                self.move = self.animations.move
                self.vertical_movement_B = true
                if love.keyboard.isDown({ "up", "w" }) == true then
                    self.vy = self.speed * -1
                    self.move = self.animations.move
                    self.vertical_movement_T = true
                end
            else
                self.vertical_movement_B = false
            end

            if love.keyboard.isDown({ "up", "w" }) == true and self.vertical_movement_B == false then
                self.vy = self.speed * -1
                self.move = self.animations.move
                self.vertical_movement_T = true
                if love.keyboard.isDown({ "down", "s" }) == true then
                    self.vy = self.speed
                    self.move = self.animations.move
                    self.vertical_movement_B = true
                end
            else
                self.vertical_movement_T = false
            end

            self.vy, self.vx = Normalize(self.vy, self.vx) -- fixing diagonal movement from being about 1.4 times faster (normalization of Vector)
            self.vy, self.vx = self.vy * self.speed, self.vx * self.speed

            self.collider:setLinearVelocity(self.vx, self.vy)
            self.x = self.collider:getX()
            self.y = self.collider:getY()
        end,

        Attack_prep = function(self, x)
            if self.is_attacking then return end

            self.camx, self.camy = cam:cameraCoords(self.x, self.y)
            self.is_attacking = true
            self.sword_attack = true
            self.move = self.animations.attack
            self.move:gotoFrame(1)
            self.collider:setLinearVelocity(0, 0)
            self.timer = 6 * 0.1

            if x > self.camx then
                self.is_right = true
                self.right_hit = true
            else
                self.is_right = false
                self.right_hit = false
            end
        end,

        Bow_prep = function(self, x)
            if self.is_attacking then return end

            self.camx, self.camy = cam:cameraCoords(self.x, self.y)
            self.is_attacking = true
            self.bow_attack = true
            self.move = self.animations.bow
            self.move:gotoFrame(1)
            self.collider:setLinearVelocity(0, 0)
            self.timer = 9 * 0.1
            if x > self.camx then
                self.is_right = true
                self.right_hit = true
            else
                self.is_right = false
                self.right_hit = false
            end
        end,

        Attack = function(self, dt) --timer idea from Copilot
            if self.is_attacking and self.timer and self.sword_attack == true then
                self.timer = self.timer - dt
                if self.timer <= 0.3 and self.timer >= 0 and not self.swipe_box then
                    if self.is_right == true then
                        self.swipe_box = world:newPolygonCollider({self.x + 23, self.y - 3, self.x + 23, self.y + 5, self.x + 12, self.y - 15, self.x + 5, self.y - 15, self.x - 5, self.y + 10, self.x + 12, self.y + 15 })
                    else
                        self.swipe_box = world:newPolygonCollider({self.x - 23, self.y - 5, self.x - 23, self.y + 5, self.x - 12, self.y - 15, self.x - 5, self.y - 15, self.x + 5, self.y + 10, self.x - 12, self.y + 15 })
                    end
                    self.swipe_box:setCollisionClass('Player_Attack')
                end
                if self.timer <= 0.1 and self.timer >= 0 then
                    if self.swipe_box then
                        self.swipe_box:destroy()
                        self.swipe_box = nil
                    end
                end
                if self.timer <= 0 then
                    self.is_attacking = false
                    self.timer = 0
                    self.move:gotoFrame(1)
                    self.move:resume()
                    self.sword_attack = false
                end
            end
        end,

        Bow = function(self, dt)
            local arrow = {}
            if self.is_attacking and self.timer and self.bow_attack == true then
                self.timer = self.timer - dt
                if self.timer <= 0.2 and self.timer >= 0 and self.is_shot == false then
                    if self.is_right == true then
                        arrow = world:newRectangleCollider(self.x + 10, self.y, 9, 2) --local variable idea from Copilot (it didnt work before with self.(...))
                    elseif self.is_right == false then
                        arrow = world:newRectangleCollider(self.x - 10, self.y, 9, 2) --local variable idea from Copilot (it didnt work before with self.(...)) 
                    end
                    arrow.direction_right = (self.is_right == true)
                    arrow:setCollisionClass('Arrow')
                    arrow:setFixedRotation(true)
                    if arrow.direction_right == true then
                        arrow:setLinearVelocity(self.arrow_speed, 0)
                    else
                        arrow:setLinearVelocity(self.arrow_speed * -1, 0)
                    end
                    table.insert(self.arrows, arrow)
                    self.is_shot = true
                end
                if self.timer <= 0 then
                    self.is_attacking = false
                    self.move:gotoFrame(1)
                    self.move:resume()
                    self.bow_attack = false
                    self.is_shot = false
                end
            end
        end,

        Arrow_update = function (self)
            for i = #self.arrows, 1, -1 do
                local obj = self.arrows[i]
                if not obj then
                    table.remove(self.arrows, i)
                elseif obj:enter('Wall') or obj:enter('Enemy') then
                    obj:destroy()
                    table.remove(self.arrows, i)  --copilot help (i used table.remove wrong and didnt understand why)
                else
                    obj.arrowx, obj.arrowy = obj:getX(), obj:getY()
                end
            end
        end,

        Pickup = function (self)
            if self.collider:enter('Health') then
                self.life = self.life + 1
            end

            if self.collider:enter('Coins') then
                self.coins = self.coins + 1
            end

            if self.collider:enter('Speed') then
                self.speed = self.speed + 20
            end
        end,

        Death = function (self, dt)
            if self.is_hit == true and self.life > 1 then
                self.is_hit = false
                self.took_dmg  = true
                self.timer = 0.05 * 4
                self.move = self.animations.take_damage
                self.move:gotoFrame(1)
                self.move:resume()
            end
            if self.life == 1 and self.is_hit == true then
                self.is_hit = false
                self.took_dmg  = true
                self.dead = true
                self.timer = 0.1 * 4
                self.move = self.animations.death
                self.move:gotoFrame(1)
                self.move:resume()
            end
            if self.took_dmg == true and self.timer and self.dead == false then
                self.x = self.collider:getX() --
                self.y = self.collider:getY() -- needed because skeleton applies linear impulse to the player on hit, so to update the drawing we need to set the x,y of the player to the collider position while death() is doing its thing
                self.timer = self.timer - dt
                if self.timer <= 0 then
                    self.took_dmg = false
                    self.life = self.life - 1
                    self.collider:setLinearVelocity(0,0)
                end
            end
            if self.took_dmg == true and self.timer and self.dead == true then
                self.timer = self.timer - dt
                self.collider:setLinearVelocity(0,0)
                if self.timer <= 0 then
                    self.took_dmg = false
                    self.life = self.life - 1
                    self.collider:destroy()
                    self.move:pauseAtEnd()
                end
            end
        end,

        Draw = function(self)
            if self.is_right == true then
                self.move:draw(self.spriteSheet, self.x, self.y, nil, nil, nil, 50, 50)
            elseif self.is_right == false then
                self.move:draw(self.spriteSheet, self.x, self.y, nil, -1, 1, 50, 50)
            end
            if self.arrows then
                for i, obj in pairs(self.arrows) do
                    if obj then
                        if obj.direction_right == true then
                            love.graphics.draw(self.arrow_pic, obj.arrowx, obj.arrowy, nil, nil, nil, 50, 50)
                        elseif obj.direction_right == false then
                            love.graphics.draw(self.arrow_pic, obj.arrowx, obj.arrowy, nil, -1, 1, 50, 50)
                        end
                    end
                end
            end
            if self.coins == 0 then
                love.graphics.print(self.coins, self.x + 410, self.y - 245, nil, 1.5, 1.5)
            else
                love.graphics.print(self.coins, self.x + 410 - 11 * ((math.log(self.coins, 10))), self.y - 245, nil, 1.5, 1.5)
            end
            love.graphics.draw(self.coin_pic, self.x + 420, self.y - 251, nil, 2, 2)
            for i = self.life, 1, -1 do
                love.graphics.draw(self.heart_pic, self.x -450 + 18 * i, self.y - 240)
            end
            if self.keys ~= 0 then
                love.graphics.draw(self.key_pic, self.x + 410, self.y - 225, nil, 1.5, 1.5)
            end
            if self.won == true then
                love.graphics.print("You Won!!!", self.x - 200, self.y - 200, nil, 5, 5)
                love.graphics.print("Press Esc to quit", self.x - 150, self.y, nil, 2, 2)
            end
            if self.dead == true then
                love.graphics.print("Game Over...", self.x - 200, self.y - 200, nil, 5, 5)
                love.graphics.print("Press Esc to quit", self.x - 150, self.y, nil, 2, 2)
            end
        end
    }
end

return Player