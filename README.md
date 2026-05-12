# ESCAPE THE DUNGEON

#### Description: 
I made a small game in Lua with Löve2d as game engine. You're a little guy with a bow and a sword and you have to find a way out of the Dungeon while fighting against skeletons.

#### Explanation: 
You can only slash and shoot to the left or the right and aim by hovering your mouse to the respective side.  
move with "a" "s" "d" "w" or "left" "down" "right" "up"  
shoot with "rightclick"  
slash with "leftclick"  
close the game with "ESC"  

#### What I used: 
I got my sprites from [Itch](https://itch.io/)  
I used [Tiled](https://www.mapeditor.org/) to make my map  
Library to render the map from Tiled: [Simple-Tiled-Implementation](https://github.com/karai17/Simple-Tiled-Implementation)  
Library to add a camera following the player: [hump](https://github.com/vrld/hump)  
Library to add physics and collision: [windfield](https://github.com/a327ex/windfield)  
Library to make animations easier: [anim8](https://github.com/kikito/anim8)  

### Content and files:

#### sprites: 
This is the folder that contains the single sprites and spritesheets split in 3 categories for the "Player", "Enemy" and "Map".

#### libraries: 
This is the folder that contains the libraries I use in my program.

#### maps: 
This is the folder that cointains the map files and the tileset I use in Tiled.

#### conf.lua: 
Contains settings and information, the height, width of the window and the title of the window. (has to be named conf.lua so that it gets recognized, the same goes for main.lua)

## Code: 

### main.lua: 

This is the main program that gets executed when running the game, games in löve2d consist of mainly three functions: love.load() to do a one-time setup at the beginning, love.update(dt) manages the game between frames and love.draw() which is used to draw everything visual onto the screen.  

At the top I import all libraries and other files for this program and create 4 different tables, one for the player, the enemies, the map and the enemies that have to be spawned. I also create a physics world with zero gravity with "windfield", a camera with 2x the zoom with "hump" and read the gamemap with "sti" into a variable.  

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

Then in love.load() I use love.graphics.setDefaultFilter("nearest", "nearest") so I don't get blurry pixels. After that I load the map and player file into their variables and call the functions inside to create collision classes and colliders for each object in the map and the player. The player also loads the player animations.

	function love.load()
		love.graphics.setDefaultFilter("nearest", "nearest") -- when scale up graphics, no blurring, scales pixels up

		map = Map() map:Collisions() map:Build(spawn)
		player = Player(1200, 620) player:Hitbox() player:Load_Animations()
	end

Love.update() spawns each enemy on the map with a hitbox and loads the corresponding animations. After spawning the enemy, the function moves it to the enemy table and removes it from the spawn table. Following that, the number of enemies that have died or "despawned" gets counted. If the counted amount is equal to the maximum amount of enemies existing, the player gets a key, and the enemies table is set to nil. It also updates every animation for the player each frame and calls every other function for the map, enemies, and player if the right conditions are met. In the end, it makes the cam always look at the players' x and y positions and updates the physics, or "world" every frame.

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

Inside Love.draw() i call every draw() function for everything that has to be rendered on screen and attach the cam onto it. 

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

I additionally use two other functions to check if a certain key is pressed (in my case "ESC"), which will cause the game to quit. The other one checks if a mouse button is pressed ("MB2, MB1"), which results in either slashing with the sword or shooting with your bow.

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




## player.lua: 
#### Normalize(x, y) 
- stops diagonal movement from being faster than straight movement

#### Player(x, y) (_the function that gets returned_)

- sets x, y to be the players x and y coordinates,
- creates many variables like life, coins, keys,
- creates booleans needed for the program later,
- creates the Arrows table
	
#### Hitbox()
- creates the player collider with all its attributes

#### Load_Animation()
- loads all needed sprites and the spritesheet into variables,
- creates table for all animations,
- creates and loads all animations into variables

#### Update(dt)
- updates each animation every in game frame

#### Update_Movement()
- if a player presses one of the associated keys for moving
	- applies a linear impulse in that direction,
	- sets the appropriate animation,	
- normalizes the vector,
- moves the collider in the direction of the linear impulse,
- matches the player x,y with the collider x,y

#### Attack_prep / Bow_prep(x)
- lock from being called again while attacking,
- set Booleans to true that are needed for everything to work the right way,
- starts the needed animation from frame 1,
- sets the timer used in attack,
- sets Linearvelocity to 0 while attacking so you dont move while shooting,
- checks whether the attack should go to the right or left
	

#### Attack(dt)
- if everything is set up right
	- starts counting down every frame,
	- creates a collider matching the timing of the attack to either right or left,
	- gives the collider the right collisionclass so it can interact with the enemy collider,
	- if timer almost runs out, destroys the collider matching the timing of the attack,
	- if the timer runs out changes Booleans back and starts the next animation from frame 1 so everything else can continue working 
	
	
#### Bow(dt)
- creates a table for arrow,
	- if everything is set up right
		- start counting down every frame,
		- creates a collider matching the timing of the attack to either right or left,
		- sets the arrow direction depending on the player direction,
		- gives the collider the right collisionclass so it can interact with the enemy collider,
		- sets the arrow' linear velocity to right or left depending on its direction,
		- inserts the arrow into the arrows table,
	- if the timer runs out changes Booleans back and starts the next animation from frame 1 so everything else can continue working

#### Arrow_update()
- for each arrow in the arrows table,
	- checks if it exists and removes it if it doesn't,
	- destroys the collider and removes it if it collides with something it should interact with,
	- gets the position for each arrow so that it can be drawn later
	
#### Pickup()
- if player walks into health, coins or speed gets the matching effect

#### Death(dt)
- removes life if hit,
- if no life is left kills the player,
- if player is dead destroys the player collider,
- animates accordingly
	
#### Draw()
- Draws the player, player_life, player_coins, player_key, each arrow in Arrows and either the win or game over message


## skeleton1.lua:
#### Normalize(x, y) 
- stops diagonal movement from being faster than straight movement

#### Num_Pos(a)
- makes number positive

#### Skeleton(x, y) (_the function that gets returned_)
- sets x, y to be the enemies x and y coordinates,
- creates some variables like life, speed, keys, or distance_to_player
- creates Booleans needed for the program later
		
#### Hitbox()
- creates the enemy collider with all its attributes

#### Update(dt)
- updates each animation every in game frame

#### Load_Animations()
- loads all needed sprites and the spritesheet into variables,
- creates table for all animations,
- creates and loads all animations into variables

#### Update_Movement(Player x, Player y)
- creates 4 colliders on each side of the skeleton that are supposed to make the skeleton stop walking into a certain direction if the hitbox enters the wall, (_doesn't work well_)
- if the range of the enemy to the player is less than 400
	- creates a collider that goes from the skeletons position to the player position,
	- if that collider does not have a collider between it and the player
		- makes the enemy chase the player with distance_to_player_chase_far as range,
		- if range is smaller than 100
			- makes the enemy chase the player with distance_to_player_chase as range,
			- if range is smaller than 20			
				- makes the enemy chase the player with distance_to_player_chase_close as range,
- if player was seen once and range to player is smaller than 200 and it is not actively chasing
	- go to the last position where the player was seen,
- normalize vector,
- move the skeleton collider,
- sets skeleton x and y to collider position

#### Player_Detect(dt, player)
- if enemy is not dead
	- creates a circle collider around the skeleton,
	- if a player enters that circle collider
		- adjusts Booleans,
		- sets the timer,
		- starts the matching animation,
	- if enemy is not dead and player was inside circle collider
		- starts the timer,
		- after some time in the animation queries the area for the player,
	- if player is found
		- sets player.is_hit to true,
		- and applies a linear impulse to the player knocking him either to the right or left which depends on the direction the enemy is facing,
	- if timer runs out
		- adjusts Booleans
				
#### Death(dt, player)
- if enemy collider collides with an arrow collider or a player_attack collider
	- adjusts some Booleans,
	- sets timer,
	- removes 1 life,
	- start the matching animation,
	- applies a linear impulse to the skeleton depending on the direction the player attacked,
- if enemy took dmg
	- starts the timer,
	- when timer runs out sets the velocity of the enemy to 0,
- if skeleton has no life left but the dead Boolean is false
	- adjust some Booleans,
	- sets timer,
	- start the matching animation,
- if the dead Boolean is true
	- if the enemy didn't despawn yet
		- start the timer,
	- destroys the enemy collider,
	- if timer runs out
		- set despawn Boolean to true,
		- give player 10 coins

#### Draw()
- draws the Enemy
		

## map.lua: 
#### Destroy_on_impact(collision_class, tbl)  
- loops through the whole table and destroys the "Body" of object that got in contact with the player

#### Draw_Type(table, drawable)  
- loops through the whole table and draws the "drawable" at its position

#### Build_Type(gamemap_layer, tbl, collision_class, collider_type)
- fills the related table with all its content for each "gamemap_layer", checks how to create and creates the collider


#### Wrld() -- the function that gets returned
- tables for each map Object,
- loads all needed sprites into variables
	
#### Collisions()
- creates every collisionclass
	
#### Build(spawn)
- gets the data out of the gamemap files for each different gamemap layer,
- creates a collider for each object that should be spawned at the  beginning,
- inserts the data for each individual object into a local variable including the collider,
- inserts each object into the table it belongs to,
- loads each enemy that has to be spawned and created into "spawn"
		
#### Map_update()
- destroys coins, health, speed if they get in contact with player and remove them from the game,
- if a player collides with a ladder that is not the ladder to win the game
	- searches for another ladder in a different position with the same port and moves the players body next to the other ladder with the same port,
	- if a player collides with a locked ladder and has a key 
		- unlocks the ladder,
	- if a player collides with the unlocked ladder 
		- player wins the game,
	- if a player collides with a shop object and has enough coin to buy that item
		- gets the effect of the item,
	- if an arrow collides with the secret candles it gets lit
		- if both candles are lit spawns the related ladder with a collider and all its attributes and inserts it into the ladder table

#### Draw()
- draws every layer of the map,
- each object in each table,
- the price on the items of the shop,
- draws the candles as lit or unlit depending if they got hit,
- draws the ladder to win the game either unlocked or locked and if locked tells you that it's locked
		