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

function _init()

	//set variables
	player.x = 55
	player.y = 119
	
	reset_ball()
	
	//create bricks
	for y=12,28,4 do
		for x=8,120,8 do
			add_brick(x, y)
		end
	end
	
end

function _update60()

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

end

function _draw()
	cls()
	
	spr(player.sprite, player.x, player.y, 2, 1)
	spr(ball.sprite, ball.x, ball.y)
	
	for b in all(bricks) do
		spr(b.sprite, b.x, b.y)
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
			
		end
		
	end
	
	//check if it leaves the bottom of the screen
	if ball.y > 127 then
		reset_ball()
		sfx(2)
	end
	
end


//resets and launches ball
function reset_ball()
	
	ball.x = 59
	ball.y = 59
	ball.yspd = -1
	ball.xspd = -1 + rnd(2)
	
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
__sfx__
000100001f0501a050130500d0500905000000150000000011000000000f000000000d0000d0000b0000000009000000000000008000060000600000000060000600005000030000000000000000000000000000
00010000366302c6201a6200962001600016000760005600036000160001600016000160001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001815017150171501715017150151501615016150151501415014150141501415013150131501215011150101500f1500e1500c1500c1500b1500b1500a15008150081500715005150021500115001150
