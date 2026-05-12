local love = require "love"
local anim8 = require "libraries/anim8"

Normalize = function(x, y) -- idea from copilot, if player walks vertical and horizontal at the same time he will be about 1.4 times faster because of *MATH* normalzing the Vector fixes that
    local length = math.sqrt(x * x + y * y)
    if length == 0 then
        return 0, 0
    end
    return x / length, y / length
end

Num_Pos = function(a) -- makes number positive
    local num = a
    num = ((num^2)^0.5)
    return num
end

function Skeleton1(x, y)
    return {
        took_dmg = false,
        life = 3,
        timer = 0,
        player_detected = false,
        is_attacking = false,
        dead = false,
        detected = false,
        despawn = false,
        is_right = true,
        speed = 40,
        LOS = false,
        x = x,
        y = y,
        coord_check = false,
        player_seen = false,
        player_last_seen_x = 0,
        player_last_seen_y = 0,
        distance_to_player_chase_far = 10,
        distance_to_player_chase = 8,
        distance_to_player_chase_close = 1,

        Hitbox = function(self)  -- creates self collider with all attributes
            self.collider = world:newBSGRectangleCollider(self.x, self.y, 12, 15, 8)
            self.collider:setFixedRotation(true)
            self.collider:setCollisionClass('Enemy')
            self.collider:setObject(self)
        end,

        Update = function(self, dt) -- important for the anim8 library so that the animations get updated each frame
            self.animations.attack:update(dt)
            self.animations.death:update(dt)
            self.animations.idle:update(dt)
            self.animations.movement:update(dt)
            self.animations.take_damage:update(dt)
        end,

        Load_Animations = function(self) -- loads all self animations
            self.spriteSheet = love.graphics.newImage("sprites/enemy/enemies-skeleton1.png")
            self.grid = anim8.newGrid(32, 32, self.spriteSheet:getWidth(), self.spriteSheet:getHeight())

            self.animations = {}

            self.animations.attack = anim8.newAnimation(self.grid("1-9", 5), 0.15)
            self.animations.death = anim8.newAnimation(self.grid("1-17", 1), 0.15)
            self.animations.idle = anim8.newAnimation(self.grid("1-6", 2), 0.2)
            self.animations.movement = anim8.newAnimation(self.grid("1-10", 3), 0.2)
            self.animations.take_damage = anim8.newAnimation(self.grid("1-5", 4), 0.15)
        end,

        Update_Movement = function(self, player_x, player_y)
            self.vx, self.vy = 0, 0
            self.move = self.animations.idle -- self.move is what gets animated in the end so because Update_Movement gets updated each frame if the player does not move self.move will go back to idle

            -- colliders on each side to make the skelly not walk into walls later (doesn't really work well)
            self.collider_top = world:queryLine(self.x, self.y, self.x, self.y - 10, {'Wall', 'Player', 'Enemy'})
            self.collider_bottom = world:queryLine(self.x, self.y, self.x, self.y + 10, {'Wall', 'Player', 'Enemy'})
            self.collider_left = world:queryLine(self.x, self.y, self.x - 10, self.y, {'Wall', 'Player', 'Enemy'})
            self.collider_right = world:queryLine(self.x, self.y, self.x + 10, self.y, {'Wall', 'Player', 'Enemy'})

            if Num_Pos(player_y - self.y) + Num_Pos(player_x - self.x) < 400 then -- if player is seen and range is smaller than 400 
                self.collider_LOS = world:queryLine(self.x, self.y, player_x, player_y, {'Wall'}) -- if collider_LOS connecting with the player without anything being in its way LOS = true

                if next(self.collider_LOS) == nil then
                    self.coord_check = false
                    self.LOS = true
                    self.player_seen = true
                else
                    if self.coord_check == false then
                        self.player_last_seen_x = player_x
                        self.player_last_seen_y = player_y
                        self.coord_check = true
                    end
                    self.LOS = false
                end
            end
            if self.LOS == true then
                if player_x - self.x > self.distance_to_player_chase_far then
                    if next(self.collider_right) == nil then
                        self.vx = self.speed
                        self.move = self.animations.movement
                        self.is_right = true
                    end
                end

                if self.x - player_x > self.distance_to_player_chase_far then
                    if next(self.collider_left) == nil then
                        self.vx = self.speed * -1
                        self.move = self.animations.movement
                        self.is_right = false
                    end
                end

                if player_y - self.y > self.distance_to_player_chase_far then
                    if next(self.collider_bottom) == nil then
                        self.vy = self.speed
                        self.move = self.animations.movement
                    end
                end

                if self.y - player_y > self.distance_to_player_chase_far then
                    if next(self.collider_top) == nil then
                        self.vy = self.speed * -1
                        self.move = self.animations.movement
                    end
                end

                if Num_Pos(player_y - self.y) + Num_Pos(player_x - self.x) < 100 then -- if player range is smaller than 100 and player is seen overwrite top vx,vy
                    if player_x - self.x > self.distance_to_player_chase then
                        if next(self.collider_right) == nil then
                            self.vx = self.speed
                            self.move = self.animations.movement
                            self.is_right = true
                        end
                    end

                    if self.x - player_x > self.distance_to_player_chase then
                        if next(self.collider_left) == nil then
                            self.vx = self.speed * -1
                            self.move = self.animations.movement
                            self.is_right = false
                        end
                    end

                    if player_y - self.y > self.distance_to_player_chase then
                        if next(self.collider_bottom) == nil then
                            self.vy = self.speed
                            self.move = self.animations.movement
                        end
                    end

                    if self.y - player_y > self.distance_to_player_chase then
                        if next(self.collider_top) == nil then
                            self.vy = self.speed * -1
                            self.move = self.animations.movement
                        end
                    end
                end

                if Num_Pos(player_y - self.y) + Num_Pos(player_x - self.x) < 20 then -- if player range is smaller than 20 and player is seen overwrite top vx,vy
                    if player_x - self.x > self.distance_to_player_chase_close then
                        if next(self.collider_right) == nil then
                            self.vx = self.speed
                            self.move = self.animations.movement
                            self.is_right = true
                        end
                    end

                    if self.x - player_x > self.distance_to_player_chase_close then
                        if next(self.collider_left) == nil then
                            self.vx = self.speed * -1
                            self.move = self.animations.movement
                            self.is_right = false
                        end
                    end

                    if player_y - self.y > self.distance_to_player_chase_close then
                        if next(self.collider_bottom) == nil then
                            self.vy = self.speed
                            self.move = self.animations.movement
                        end
                    end

                    if self.y - player_y > self.distance_to_player_chase_close then
                        if next(self.collider_top) == nil then
                            self.vy = self.speed * -1
                            self.move = self.animations.movement
                        end
                    end
                end
            end

            if Num_Pos(player_y - self.y) + Num_Pos(player_x - self.x) > 200 and self.coord_check == false and self.player_seen == true then -- if player was seen once and range to player is smaller than 200 and is not actively chasing 
                self.player_last_seen_x = player_x
                self.player_last_seen_y = player_y
                self.coord_check = true
                self.LOS = false
            end

            if self.LOS == false and self.player_seen == true then
                if self.player_last_seen_x - self.x > self.distance_to_player_chase_close then
                    if next(self.collider_right) == nil then
                        self.vx = self.speed
                        self.move = self.animations.movement
                        self.is_right = true
                    end
                end

                if self.x - self.player_last_seen_x > self.distance_to_player_chase_close then
                    if next(self.collider_left) == nil then
                        self.vx = self.speed * -1
                        self.move = self.animations.movement
                        self.is_right = false
                    end
                end
                if self.player_last_seen_y - self.y > self.distance_to_player_chase_close then
                    if next(self.collider_bottom) == nil then
                        self.vy = self.speed
                        self.move = self.animations.movement
                    end
                end

                if self.y - self.player_last_seen_y > self.distance_to_player_chase_close then
                    if next(self.collider_top) == nil then
                        self.vy = self.speed * -1
                        self.move = self.animations.movement
                    end
                end
            end

            self.vy, self.vx = Normalize(self.vy, self.vx) -- fixing diagonal movement from being about 1.4 times faster (normalization of Vector)
            self.vy, self.vx = self.vy * self.speed, self.vx * self.speed

            self.collider:setLinearVelocity(self.vx, self.vy) -- moving the Body
            self.x = self.collider:getX()
            self.y = self.collider:getY()
        end,

        Player_Detect = function(self, dt, player)
            if self.dead == false then
                self.detect_player = world:queryCircleArea(self.x,  self.y, 10, {'Player'})
            end
            if next(self.detect_player) ~= nil and self.detected == false and self.dead == false then
                self.detected = true
                self.is_attacking = true
                self.timer = 0.15 * 9
                self.move =  self.animations.attack
                self.move:gotoFrame(1)
                self.move:resume()
            end

            if self.is_attacking == true and self.dead == false then
                self.timer = self.timer - dt
                self.collider:setLinearVelocity(0, 0)
                if self.timer >= 0.2 and self.timer <= 0.4 then
                    if self.is_right == true then
                        for _, collider in ipairs(world:queryCircleArea(self.x + 12, self.y, 15, {'Player'})) do
                            player.is_hit = true
                            collider:setLinearVelocity(0,0)
                            collider:applyLinearImpulse(15, 0)
                        end
                    else
                        for _, collider in ipairs(world:queryCircleArea(self.x - 12, self.y, 15, {'Player'})) do
                            player.is_hit = true
                            collider:setLinearVelocity(0,0)
                            collider:applyLinearImpulse(-15, 0)
                        end
                    end
                end
                if self.timer <= 0 then
                    self.detected = false
                    self.is_attacking = false
                end
            end
        end,

        Death = function(self, dt, player)
            if self.collider:enter('Arrow') then
                self.took_dmg = true
                self.move =  self.animations.take_damage
                self.move:gotoFrame(1)
                self.move:resume()
                self.life = self.life - 1
                self.detected = false
                self.is_attacking = false
                if player.right_hit == true then
                    self.collider:applyLinearImpulse(5,0)
                else
                    self.collider:applyLinearImpulse(-5,0)
                end
                self.timer = 0.15 * 4
            elseif self.collider:enter('Player_Attack') then
                self.took_dmg = true
                self.is_attacking = false
                self.move =  self.animations.take_damage
                self.move:gotoFrame(1)
                self.move:resume()
                self.life = self.life - 1
                self.detected = false
                self.is_attacking = false
                if player.right_hit == true then
                    self.collider:applyLinearImpulse(5,0)
                else
                    self.collider:applyLinearImpulse(-5,0)
                end
                self.timer = 0.15 * 4
            end
            if self.took_dmg == true then
                self.timer = self.timer - dt
                if self.timer <= 0 then
                    self.took_dmg = false
                    self.vx, self.vy = 0,0
                end
            end

            if self.life == 0 and self.dead == false then
                self.dead = true
                self.took_dmg = false
                self.timer = 0.15 * 17
                self.move = self.animations.death
                self.move:gotoFrame(1)
                self.move:resume()
            end

            if self.dead == true then
                if self.despawn == false then
                    self.timer = self.timer - dt
                end
                self.collider:destroy()
                if self.timer <= 0 then
                    self.despawn = true
                    player.coins = player.coins + 10
                    self.timer = 1
                end
            end

            if self.dead == false then
                self.x = self.collider:getX()
                self.y = self.collider:getY()
            end
        end,

        Draw = function(self)
            if self.despawn == false then
                if self.is_right == true then
                    self.move:draw(self.spriteSheet, self.x + 3, self.y - 5, nil, nil, nil, 16, 16) --adjustments on x and y because drawing skeleton1 is kinda wonky... idk why? (maybe because i made the spritesheet in Paint and im too lazy to fix it) disclaimer: i didn't draw it i just put the frames together in one png
                elseif self.is_right == false then
                    self.move:draw(self.spriteSheet, self.x - 3, self.y - 5, nil, -1, 1, 16, 16)
                end
            end
        end,
    }
end

return Skeleton1