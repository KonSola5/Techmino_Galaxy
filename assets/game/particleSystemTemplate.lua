--- @class Techmino.particleSystems
--- @field rectShade love.ParticleSystem
--- @field spinArrow table
--- @field star love.ParticleSystem
--- @field line love.ParticleSystem
--- @field hitSparkle love.ParticleSystem
--- @field cornerCheck love.ParticleSystem
--- @field tiltRect love.ParticleSystem
--- @field trail love.ParticleSystem
--- @field minoMapBack love.ParticleSystem
local ps={}

do-- Moving
    local p=love.graphics.newParticleSystem(GC.load{1,1,
        {'clear',1,1,1,1},
    },260)
    p:setSizes(40)
    p:setColors(1,1,1,.26,1,1,1,0)
    p:setSpread(0)
    p:setSpeed(0)
    p:setParticleLifetime(.16)
    ps.rectShade=p
end

do-- Hold
    local texture=GC.newText(FONT.get(80,'symbols'),CHAR.icon.sync)
    local p={}
    function p:clone()
        return setmetatable({list={}},{__index=p})
    end
    function p:new(x,y,ifInit)
        table.insert(self.list,{
            x=x,y=y,t=0,
            a=math.random()*MATH.tau,
            va=ifInit and MATH.rand(16,22) or MATH.rand(2.6,6.2),
            lifeTime=.26,
        })
    end
    function p:update(dt)
        for i=#self.list,1,-1 do
            local v=self.list[i]
            v.t=v.t+dt/v.lifeTime
            if v.t>1 then
                table.remove(self.list,i)
            else
                v.a=v.a+v.va*dt
                v.va=math.max(v.va-dt*62,4.2)
            end
        end
    end
    function p:draw()
        local r,g,b,a=GC.getColor()
        a=a*.7023
        for i=1,#self.list do
            local v=self.list[i]
            local t=v.t
            GC.setColor(r,g,b,a*(1-t)^.626)
            GC.mDraw(texture,v.x,v.y,v.a,2.6*(.5+t^.5*.626))
        end
    end
    ps.spinArrow=p
end

do-- Clearing
    local p=love.graphics.newParticleSystem(GC.load{7,7,
        {'setLW',1},
        {'line',0,3.5,6.5,3.5},
        {'line',3.5,0,3.5,6.5},
        {'fRect',2,2,3,3},
    },2600)
    p:setSizes(.26,1,.8,.6,.4,.2,0)
    p:setSpread(MATH.tau)
    p:setSpeed(0,20)
    ps.star=p
end

do-- Rotate
    local p=love.graphics.newParticleSystem(GC.load{10,3,
        {'clear',1,1,1,1},
    },2600)
    p:setEmissionArea('uniform',40,40,MATH.tau,true)
    p:setSizes(.6,1,.5,.2,0)
    p:setRelativeRotation(true)
    ps.line=p
end

do-- Touching spark
    local p=love.graphics.newParticleSystem(GC.load{4,4,
        {'clear',1,1,1,1},
    },260)
    p:setSizes(.6,.9,1,1)
    p:setColors(1,1,1,1,1,1,1,0)
    p:setDirection(math.pi/2)
    p:setSpread(0)
    p:setSpeed(120,260)
    p:setLinearDamping(12,16)
    p:setParticleLifetime(.872)
    ps.hitSparkle=p
end

do-- Rotating corner check
    local p=love.graphics.newParticleSystem(GC.load{1,1,
        {'clear',1,1,1,1},
    },26)
    p:setSizes(26)
    p:setColors(1,1,1,.62,1,1,1,0)
    p:setRotation(0)
    p:setSpeed(0)
    p:setParticleLifetime(.126)
    ps.cornerCheck=p
end

do-- Piece controlling effect
    local p=love.graphics.newParticleSystem(GC.load{1,1,
        {'clear',1,1,1},
    },26)
    p:setSizes(60,50,25,0)
    p:setRotation(-.26,.26)
    p:setSpin(-2.6,2.6)
    p:setParticleLifetime(.26)
    ps.tiltRect=p
end

do-- Harddrop light
    local width=80
    local height=240
    local fadeLength=40
    local p=love.graphics.newParticleSystem((function()
        local L={width,height}
        for i=1,width/2 do
            table.insert(L,{'setCL',1,1,1,i/(width/2)})
            table.insert(L,{'fRect',i,0,1,height})
            table.insert(L,{'fRect',width-i,0,1,height})
        end
        table.insert(L,{'setBM','multiply','premultiplied'})
        table.insert(L,{'setCM',false,false,false,true})
        for i=0,height-1 do
            if i<height-fadeLength then
                table.insert(L,{'setCL',0,0,0,i/(height-fadeLength)})
            else
                table.insert(L,{'setCL',0,0,0,(height-i)/fadeLength})
            end
            table.insert(L,{'fRect',0,i,width,1})
        end
        return GC.load(L)
    end)(),12)
    p:setOffset(width/2,height)
    p:setParticleLifetime(.32)
    p:setColors(
        1,1,1,0.0,
        1,1,1,1.0,
        1,1,1,0.8,
        1,1,1,0.6,
        1,1,1,0.4,
        1,1,1,0.2,
        1,1,1,0.0
    )
    ps.trail=p
end

do-- Background light of mino map
    local p=love.graphics.newParticleSystem(GC.load{10,10,
        {'setCL',1,1,1,.5},
        {'fRect',0,0,10,10},
        {'fRect',1,1,8,8},
        {'fRect',2,2,6,6},
    },260)
    p:setSizes(26)
    p:setColors(1,1,1,0,1,1,1,.062,1,1,1,.162,1,1,1,.26,1,1,1,0)
    p:setRotation(0,MATH.tau)
    p:setSpin(-.26,.26)
    p:setSpread(2.6)
    p:setParticleLifetime(5.62,7.26)
    p:setSpeed(620,1260)
    p:setEmissionRate(10)
    ps.minoMapBack=p
end

return ps
