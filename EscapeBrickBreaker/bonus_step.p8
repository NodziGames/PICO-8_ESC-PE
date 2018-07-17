pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- esc@pe 2018 --
-- brick breaker clone --

//declare objects

player = {
	x = 0,
	y = 0,
	sprite = 5,
	
	bbox = {
		x1 = 0,
		x2 = 15,
		y1 = 5,
		y2 = 7
	}
}

ball = {
	xspd = 0,
	yspd = 0,
	sprite = 4,
	
	bbox = {
		x1 = 2,
		x2 = 5,
		y1 = 2,
		y2 = 5
	}
}

bricks = {}
particles = {}
highscores = {}

function _init()

	state = "menu"
	selection = 1
	music(0)
	
end

function init_game()
	music(5)
	state = "game"
	camera_x = 0
	camera_y = 0

	//set variables
	player.x = 55
	player.y = 119
	score = 0
	lives = 3
	
	reset_ball()

	bricks = {}
	
	//create bricks
	for y=12,28,4 do
		for x=8,120,8 do
			add_brick(x, y)
		end
	end
end

function _update60()

	//game state

	if (state == "game") then
		//player controls
		if btn(0) then
			player.x -= 2
		elseif btn(1) then
			player.x += 2
		end
		
		//clamp player x and y
		player.x = max(0, player.x)
		player.x = min(111, player.x)
		
		//call ball behaviour
		ball_behaviour()
		brick_behaviour()
		handle_camera()
		handle_particles()
	end

	//menu state

	if (state == "menu") then
		if btnp(2) or btnp(3) then
			sfx(3)
			if selection == 1 then
				selection = 2
			else
				selection = 1
			end
		end
		if btnp(4) then
			sfx(4)
			if selection == 1 then init_game() end
			if selection == 2 then goto_gameover() end
		end
	end

	if (state == "gameover") then
		if btnp(5) then
			sfx(4)
			state = "menu"
		end
	end
end

function _draw()
	cls()
	
	if (state == "game") then
		print("score: " .. score, 85 - camera_x, 4 - camera_y, 13)
		for i=0,lives,1 do
			print("●", 12 + (i * 8) - camera_x, 4 - camera_y, 13)
		end
		
		spr(player.sprite, player.x - camera_x, player.y - camera_y, 2, 1)
		spr(ball.sprite, ball.x - camera_x, ball.y - camera_y)
		
		for b in all(bricks) do
			spr(b.sprite, b.x - camera_x, b.y - camera_y)
		end

		for p in all(particles) do
			spr(p.sprite, p.x - camera_x, p.y - camera_y)
		end
	end

	if (state == "menu") then
		//draw title
		iteration = 0
		for i=32,42,2 do
			spr(i, 8 + (20 * iteration), 8, 2, 2)
			iteration += 1
		end
		//draw start game
		if selection == 1 then
			print("🐱 start game 🐱", 32, 90, 7)
		else
			print("   start game   ", 32, 90, 5)
		end
		
		//draw highscores button or whatever
		if selection == 2 then
			print("🐱 highscores 🐱", 32, 102, 7)
		else
			print("   highscores   ", 32, 102, 5)
		end
		print("(z) to select", 37, 118, 1)
	end

	if (state == "gameover") then
		print("★highscores★", 40, 12, 10)
		print("--------------", 40, 24, 7)
		iteration = 0
		for h in all(highscores) do
			if iteration < 7 then
				print((iteration + 1) .. ": " .. h, 50, 34 + (iteration * 10), 7)
				iteration += 1
			end
		end
		print(" ❎ to return", 40, 114, 1)
	end
end


//other functions

function add_brick(x, y)
	brick = {}
	
	brick.x = x
	brick.y = y
	brick.sprite = rnd(4)
	
	brick.bbox = {
		x1 = 0,
		x2 = 7,
		y1 = 0,
		y2 = 3
	}
	
	add(bricks, brick)
end

function add_particle(x, y)
	particle = {}

	particle.x = x
	particle.y = y
	particle.sprite = 16 + rnd(6)

	particle.xspd = -2 + rnd(4)
	particle.yspd = -2 + rnd(4)

	particle.lifetime = 30 + rnd(30)

	add(particles, particle)
end


//compares bounding boxes
function colliding(a, b)
	if (a.x + a.bbox.x1 > b.x + b.bbox.x2) or
		(a.x + a.bbox.x2 < b.x + b.bbox.x1) or
		(a.y + a.bbox.y1 > b.y + b.bbox.y2) or
		(a.y + a.bbox.y2 < b.y + b.bbox.y1) then
		return false
	else
		return true
	end
end

//ball behaviour
function ball_behaviour()

	//move the ball
	ball.x += ball.xspd
	ball.y += ball.yspd
	
	//prevent it from leaving the field
	if (ball.y <= 0) then
		ball.yspd *= -1
	end
	
	if (ball.x <= 0 or ball.x >= 122) then
		ball.xspd *= -1
	end
	
	//collide with player bat
	if colliding(ball, player) then
	
		//check if it hasn't bounced yet, then bounce
		if ball.yspd > 0 then
		
			ball.yspd *= -1
			
			//change xdir based on the angle
			ball.xspd = ((player.x + 7) - ball.x) / -10
		
			sfx(0)

			camera_y -= 2
			
		end
		
	end
	
	//check if it leaves the bottom of the screen
	if ball.y > 127 then
		reset_ball()
		sfx(2)
		if lives > 0 then
			lives -= 1
		else
			add(highscores, score)
			sfx(5)
			goto_gameover()
		end
	end
	
end


//resets and launches ball
function reset_ball()
	
	ball.x = 59
	ball.y = 59
	ball.yspd = -1
	ball.xspd = -1 + rnd(2)
	
end


//brick behaviour

function brick_behaviour()

	for b in all(bricks) do
	
		//predict if ball will collide in the next update
		//otherwise the ball will already be in the brick so we won't know which side it collided from
		ball_predict = {
			x = ball.x + ball.xspd,
			y = ball.y + ball.yspd,
			bbox = ball.bbox
		}
		
		if colliding(b, ball_predict) then
		
			//if side collision
			if (ball.x + ball.bbox.x2 <= b.x) or (ball.x + ball.bbox.x1 >= b.x + b.bbox.x2) then
				ball.xspd *= -1
			else
				ball.yspd *= -1
			end
			
			sfx(1)

			for i=0,6,1 do
				add_particle(b.x, b.y)
			end

			del(bricks, b)
			score += 1
			camera_y += 2
			
		end
	end

end



//camera stuff
function handle_camera()
	if camera_x > 0 then
		camera_x -= 0.25
	elseif camera_x < 0 then
		camera_x += 0.25
	end

	if camera_y > 0 then
		camera_y -= 0.25
	elseif camera_y < 0 then
		camera_y += 0.25
	end
end


function handle_particles()

	for p in all(particles) do
		p.x += p.xspd
		p.y += p.yspd
		if p.lifetime > 0 then
			p.lifetime -= 1
		else
			del(particles, p)
		end
	end

end

function goto_gameover()
	sort(highscores)
	state = "gameover"
end

function sort(a)
    for i=1,#a do
        local j = i
        while j > 1 and a[j-1] < a[j] do
            a[j],a[j-1] = a[j-1],a[j]
            j = j - 1
        end
    end
end
__gfx__
77777777777777777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccbbbbbbbbaaaaaaaa88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccbbbbbbbbaaaaaaaa88888888000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111333333339999999922222222007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000066000dddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000dddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001111111111111111000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000f000000f0000000ff000000f00000000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000f00000000f00000000000000f00000000f000000ff00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888800000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888800000000000000000000000000000000
88822222222222228882222222222222888222222222222288822222222222888882222222222888888222222222222200000000000000000000000000000000
88800000000000008880000000000000888000000000000088800000000000888880000000000888888000000000000000000000000000000000000000000000
88800000000000008880000000000000888000000000000088800000000000888880000000000888888000000000000000000000000000000000000000000000
88800000000000008880000000000000888000000000000088800088888888828880000000000888888000000000000000000000000000000000000000000000
88800000000000008880000000000000888000000000000088800880088222208880000000000888888000000000000000000000000000000000000000000000
88888888888888888888888888888888888000000000000088800880088000008880000000000888888888888888888800000000000000000000000000000000
88888888888888888888888888888888888000000000000088800880088000008888888888888888888888888888888800000000000000000000000000000000
88822222222222222222222222222888888000000000000088800880088000008888888888888888888222222222222200000000000000000000000000000000
88800000000000000000000000000888888000000000000088800888888000008882222222222222888000000000000000000000000000000000000000000000
88800000000000000000000000000888888000000000000088800000022000008880000000000000888000000000000000000000000000000000000000000000
88800000000000000000000000000888888000000000000088800000000000008880000000000000888000000000000000000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888880000000000000888888888888888800000000000000000000000000000000
88888888888888888888888888888888888888888888888888888888888888888880000000000000888888888888888800000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222222220000000000000222222222222222200000000000000000000000000000000
__sfx__
0001000013050100500d0500b05008050040500105001050133001330013300133001330013300133001330013300133001330008000060000600000000060000600005000030000000000000000000000000000
00010000366302c6201a6200962001600016000760005600036000160001600016000160001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001815017150171501715017150151501615016150151501415014150141501415013150131501215011150101500f1500e1500c1500c1500b1500b1500a15008150081500715005150021500115001150
000200000a1500b1500e15011150161501f150231501b100211002910000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000b3500f3500f3500d35009350093500b3500d3500d3500c3500f35012350143501335018350183501f350203502035026350283502b35000000000000000000000000000000000000000000000000000
001600002a350233501d350173500e35008350013502330021300203001e3001d3001b3001830015300123000f3000d3000000000000000000000000000000000000000000000000000000000000000000000000
00100000180501f0001a0501f0001c0501f0001f0501f000210501f000230501f000240501d0001f0501c0001d050180001c0501a0501c0501f00018050000001a050000001f0500000018050000001a05000000
011000000c050211001300000000130500000000000000000c050000000000000000130500000000000000000c050000000000000000130500000000000000000c05000000000000000013050000000000000000
0010000010675226001f6001660034633086000160000000106750000000000000003463300000000000000010675000000000000000346330000000000000001067500000000000000034633106753463300000
000300003f6203b600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000018050000001a050000001c050000001f050000002405000000210500000023050000001f0500000021050000001d050000001f050000001c050000001d050000001c050000001a050000001805000000
001000001105000000000001700018050000000000000000110500000000000000001805000000000000000011050000000000000000180500000000000000001105000000000000000018050000000000000000
00100000150500000000000000001005000000000000000015050000000000000000100500000000000000001305000000000000000010050000000000000000130500000000000000001c050000000000000000
001000001105000000000000000015050000000000000000110500000000000000001505000000000000000011050000000000000000150500000000000000001105000000000000000013050000000000000000
00100000307303073130731307313073130731307313073130731307313073130731307313073130731307312f7312f7312f7312f7312f7312f7312f7312f7313273132731327313273132731327313273132731
00100000307303073130731307313073130731307313073130731307313073130731307313073130731307312f7312f7312f7312f7312f7312f7312f7312f7312b7312b7312b7312b7312b7312b7312b7312b731
001000002d7302d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312d7312f7312f7312f7312f7312f7312f7312f7312f731
__music__
01 0607080e
01 0a0b080e
01 060c080f
04 0a0d0810
