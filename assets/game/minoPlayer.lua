local gc=love.graphics
local gc_push,gc_pop=gc.push,gc.pop
local gc_translate,gc_scale,gc_rotate=gc.translate,gc.scale,gc.rotate
local gc_setColor=gc.setColor
local gc_draw=gc.draw

local max,min,rnd=math.max,math.min,math.random
local floor,ceil=math.floor,math.ceil
local ins,rem=table.insert,table.remove

local clamp,expApproach=MATH.clamp,MATH.expApproach

---@class Techmino.Player.mino: Techmino.Player
---@field field Techmino.RectField
local MP=setmetatable({},{__index=require'assets.game.basePlayer',__metatable=true})

--------------------------------------------------------------
-- Function tables
local defaultSoundFunc={
    countDown=function(num)
        if num==0 then -- 6, 3+6+6
            playSample('sine',{'A3',.8})
            playSample('square',{'A4',.9},{'E5',.9},{'A5',.9})
        elseif num==1 then -- 5, 3+7
            playSample('sine',{'G3',.9})
            playSample('square',{'B4',.9},{'E5',.9})
        elseif num==2 then -- 4, 6+2
            playSample('sine',{'F3'})
            playSample('square',{'A4',.8},{'D5',.8})
        elseif num==3 then -- 6+6
            playSample('sine',{'A3',.9},{'E4',.9})
            playSample('square',{'A4',.8})
        elseif num==4 then -- 5+7, 5
            playSample('sine',{'G3',.9},{'B3',.9})
            playSample('square',{'G4',.6})
        elseif num==5 then -- 4+6, 4
            playSample('sine',{'F3',.8},{'A3',.8})
            playSample('square',{'F4',.3})
        elseif num<=10 then
            playSample('sine',{'A2',2.2-num/5},{'E3',2.2-num/5})
        end
    end,
    move=           function() FMOD.effect('move')               end,
    move_down=      function() FMOD.effect('move_down')          end,
    move_failed=    function() FMOD.effect('move_failed')        end,
    tuck=           function() FMOD.effect('tuck')               end,
    rotate=         function() FMOD.effect('rotate')             end,
    rotate_init=    function() FMOD.effect('rotate_init')        end,
    rotate_locked=  function() FMOD.effect('rotate_locked')      end,
    rotate_corners= function() FMOD.effect('rotate_corners')     end,
    rotate_failed=  function() FMOD.effect('rotate_failed')      end,
    rotate_special= function() FMOD.effect('rotate_special')     end,
    hold=           function() FMOD.effect('hold')               end,
    hold_init=      function() FMOD.effect('hold_init')          end,
    touch=          function() FMOD.effect('touch')              end,
    drop=           function() FMOD.effect('drop')               end,
    lock=           function() FMOD.effect('lock')               end,
    b2b=            function(lv) FMOD.effect('b2b_'..min(lv,10)) end,
    b2b_break=      function() FMOD.effect('b2b_break')          end,
    clear=function(lines)
        FMOD.effect(
            lines<=6 and 'clear_'..lines or
            lines<=18 and 'clear_'..(lines-lines%2) or
            lines<=22 and 'clear_'..lines or
            lines<=26 and 'clear_'..(lines-lines%2) or
            'clear_26'
        )
    end,
    spin=function(lines)
        if lines==0 then     FMOD.effect('spin_0')
        elseif lines==1 then FMOD.effect('spin_1')
        elseif lines==2 then FMOD.effect('spin_2')
        elseif lines==3 then FMOD.effect('spin_3')
        elseif lines==4 then FMOD.effect('spin_4')
        else                 FMOD.effect('spin_mega')
        end
    end,
    combo=setmetatable({
        function() playSample('sine',{'A2',.70,420}) end, -- 1
        function() playSample('sine',{'C3',.75,410}) end, -- 2
        function() playSample('sine',{'D3',.80,400}) end, -- 3
        function() playSample('sine',{'E3',.85,390}) end, -- 4
        function() playSample('sine',{'G3',.90,380}) end, -- 5
        function() playSample('sine',{'A3',.90,370},'square',{'A2',.20,420,620}) end, -- 6
        function() playSample('sine',{'C4',.75,360},'square',{'C3',.40,400,620}) end, -- 7
        function() playSample('sine',{'D4',.60,350},'square',{'D3',.60,380,620}) end, -- 8
        function() playSample('sine',{'E4',.40,340},'square',{'E3',.75,360,620}) end, -- 9
        function() playSample('sine',{'G4',.20,330},'square',{'G3',.90,340,620}) end, -- 10
        function() playSample('sine',{'A4',.20,320},'square',{'A3',.85,320,620}) end, -- 11
        function() playSample('sine',{'A4',.40,310},'square',{'C4',.80,300,620}) end, -- 12
        function() playSample('sine',{'A4',.60,300},'square',{'D4',.75,280,620}) end, -- 13
        function() playSample('sine',{'A4',.75,290},'square',{'E4',.70,270,620}) end, -- 14
        function() playSample('sine',{'A4',.90,280},'square',{'G4',.65,260,640}) end, -- 15
        function() playSample('sine',{'A4',.90,270},{'E5',.70},'square',{'A4',1,250,660}) end, -- 16
        function() playSample('sine',{'A4',.85,260},{'E5',.75},'square',{'C5',1,240,680}) end, -- 17
        function() playSample('sine',{'A4',.80,250},{'E5',.80},'square',{'D5',1,230,700}) end, -- 18
        function() playSample('sine',{'A4',.75,240},{'E5',.85},'square',{'E5',1,220,720}) end, -- 19
        function() playSample('sine',{'A4',.70,230},{'E5',.90},'square',{'G5',1,210,740}) end, -- 20
    },{__call=function(self,combo)
        if self[combo] then
            self[combo]()
        else
            playSample('sine',{'A4',.626-.01*combo,430-10*combo})
            local phase=(combo-21)%12
            playSample('square',{40+phase,1-((11-phase)/12)^2,400-10*combo,700+20*combo}) -- E4+
            playSample('square',{45+phase,1-((11-phase)/12)^2,400-10*combo,700+20*combo}) -- A4+
            playSample('square',{52+phase,1-(phase/12)^2,400-10*combo,700+20*combo}) -- E5+
            playSample('square',{57+phase,1-(phase/12)^2,400-10*combo,700+20*combo}) -- A5+
        end
    end,__metatable=true}),
    frenzy=      function() FMOD.effect('frenzy')      end,
    allClear=    function() FMOD.effect('clear_all')   end,
    halfClear=   function() FMOD.effect('clear_half')  end,
    suffocate=   function() FMOD.effect('suffocate')   end,
    desuffocate= function() FMOD.effect('desuffocate') end,
    reach=       function() FMOD.effect('beep_rise')   end,
    notice=      function() FMOD.effect('beep_notice') end,
    win=         function() FMOD.effect('win')         end,
    fail=        function() FMOD.effect('fail')        end,
}
MP.scriptCmd={
    clearHold=function(P) P:clearHold() end,
    clearNext=function(P) P:clearNext() end,
    pushNext=function(P,arg) P:pushNext(arg) end,
    setField=function(P,arg) P:setField(arg) end,
    switchAction=function(P,arg) P:switchAction(arg) end,
}
--------------------------------------------------------------
-- Actions
MP._actions={}
for k,v in next,mechLib.mino.actions do MP._actions[k]=MP:_getActionObj(v) end
--------------------------------------------------------------
-- Effects
function MP:createMoveEffect(x1,y1,x2,y2)
    local p=self.particles.rectShade
    local dx,dy=self:getSmoothPos()
    for x=x1,x2,x2>x1 and 1 or -1 do for y=y1,y2,y2>y1 and 1 or -1 do
        p:setPosition((x-.5)*40+dx,-(y-.5)*40+dy)
        p:emit(1)
    end end
end
function MP:createRotateEffect(dir,ifInit)
    local minoData=minoRotSys[self.settings.rotSys][self.hand.shape]
    local state=minoData[self.hand.direction]
    local centerPos=state and state.center or type(minoData.center)=='function' and minoData.center(self)
    local cx,cy
    if centerPos then
        cx,cy=self.handX+centerPos[1]-.5,self.handY+centerPos[2]-.5
    else
        cx,cy=self.handX+#self.hand.matrix[1]/2-.5,self.handY+#self.hand.matrix/2-.5
    end
    local p=self.particles.line
    p:setParticleLifetime(.26,.42)
    if ifInit then
        p:setSpeed(260,620)
    else
        p:setSpeed(80,120)
    end
    p:setTangentialAcceleration(dir=='L' and -2600 or 0,dir=='R' and 2600 or 0)
    p:setPosition((cx-.5)*40,-(cy-.5)*40)
    p:emit(12)
end
function MP:createRotateCornerEffect(cx,cy)
    local p=self.particles.cornerCheck
    for x=-1,1,2 do
        for y=-1,1,2 do
            p:setPosition(
                (cx+x-.5)*40,
                -(cy+y-.5)*40
            )
            p:emit(1)
        end
    end
end
function MP:createHandEffect(r,g,b,a)
    local CB,bx,by=self.hand.matrix,self.handX,self.handY
    local dx,dy=self:getSmoothPos()
    local p=self.particles.tiltRect
    p:setColors(r,g,b,a or 1,r,g,b,0)
    for y=1,#CB do for x=1,#CB[1] do
        local c=CB[y][x]
        if c then
            p:setPosition(
                (bx+x-1.5)*40+dx,
                -(by+y-1.5)*40+dy
            )
            p:emit(1)
        end
    end end
end
local _oneCell={{true}}
function MP:createTouchEffect()
    local p=self.particles.hitSparkle
    local mat=self.hand.matrix
    local cx,cy=self.handX,self.handY
    for x=1,#mat[1] do for y=1,#mat do
        if mat[y][x] and self:ifoverlap(_oneCell,cx+x-1,cy+y-2) then
            for _=1,rnd(3,4) do
                p:setPosition(
                    (cx+x-2+rnd())*40,
                    -(cy+y-2)*40
                )
                p:emit(1)
            end
        end
    end end
end
function MP:createTuckEffect()
end
function MP:createHoldEffect(ifInit)
    if not self.handX then return end
    local cx,cy=self.handX+#self.hand.matrix[1]/2-.5,self.handY+#self.hand.matrix/2-.5
    local p=self.particles.spinArrow
    p:new((cx-.5)*40,-(cy-.5)*40,ifInit)
end
function MP:createFrenzyEffect(amount)
    local p=self.particles.star
    p:setEmissionArea('uniform',200,400,0,true)
    p:setParticleLifetime(.626,1.6)
    p:setPosition(200,-400)
    p:emit(amount)
end
function MP:createLockEffect()
    local p=self.particles.trail
    p:setPosition(
        (self.handX+#self.hand.matrix[1]/2-1)*40,
        -(self.handY+#self.hand.matrix/2-1)*40
    )
    p:emit(1)
end
function MP:createSuffocateEffect()
end
function MP:createDesuffocateEffect()
end
function MP:setCellBias(x,y,bias)
    local c=self.field:getCell(x,y)
    if c then
        bias.x=40*(bias.x or 0)
        bias.y=-40*(bias.y or 0)
        if c.bias then
            bias.x=bias.x+c.bias.x
            bias.y=bias.y+c.bias.y
        end
        c.bias=bias
    end
end
function MP:showInvis(visStep,visMax)
    for y=1,self.field:getHeight() do
        for x=1,self.settings.fieldW do
            local c=self.field:getCell(x,y)
            if c then
                c.visTimer=c.visTimer or 0
                c.visStep=visStep or 1
                c.visMax=visMax
            end
        end
    end
end
function MP:getSmoothPos()
    if self.deathTimer then
        return 0,0
    else
        return
            self.moveDir and self.moveCharge<self.settings.asd and 15*self.moveDir*(max(self.moveCharge,0)/self.settings.asd-.5) or 0,
            self.ghostY and self.handY>self.ghostY and 40*(max(1-self.dropTimer/self.settings.dropDelay*2.6,0))^2.6 or 0
    end
end
--------------------------------------------------------------
-- Game methods
---@param action 'moveX'|'moveY'|'drop'|'rotate'|'reset'
function MP:moveHand(action,A,B,C,D)
    --[[
        moveX:  dx,noShade
        moveY:  dy,noShade
        drop:   dy,noShade
        rotate: x,y,dir,ifInit
        reset:  x,y
    ]]
    local SET=self.settings
    if action=='moveX' then
        self.handX=self.handX+A
        self:checkLanding()
        if SET.particles then
            local hx,hy=self.handX,self.handY
            local mat=self.hand.matrix
            local w,h=#mat[1],#mat
            if not B then
                if A<0 then
                    for y=1,h do for x=w,1,-1 do
                        if mat[y][x] then
                            self:createMoveEffect(hx+x-1+1,hy+y-1,hx+x-1+1-A-1,hy+y-1)
                            break
                        end end
                    end
                elseif A>0 then
                    for y=1,h do for x=1,w do
                        if mat[y][x] then
                            self:createMoveEffect(hx+x-1-1,hy+y-1,hx+x-1-1-A+1,hy+y-1)
                            break
                        end end
                    end
                end
            end
        end
    elseif action=='moveY' or action=='drop' then
        self.handY=self.handY+A
        self.dropTimer=SET.dropDelay
        self:checkLanding(true,true)
        if SET.particles then
            local hx,hy=self.handX,self.handY
            local mat=self.hand.matrix
            local w,h=#mat[1],#mat
            if not B then
                if A<0 then
                    for x=1,w do for y=h,1,-1 do
                        if mat[y][x] then
                            self:createMoveEffect(hx+x-1,hy+y-1+1,hx+x-1,hy+y-1+1-A-1)
                            break
                        end end
                    end
                elseif A>0 then
                    for x=1,w do for y=1,h do
                        if mat[y][x] then
                            self:createMoveEffect(hx+x-1,hy+y-1-1,hx+x-1,hy+y-1-1-A+1)
                            break
                        end end
                    end
                end
            end
        end
    elseif action=='rotate' or action=='reset' then
        self.handX,self.handY=A,B
        self:checkLanding()
    else
        error("WTF why action is "..tostring(action))
    end

    if self.handX%1~=0 or self.handY%1~=0 then error("EUREKA! Decimal position") end

    local movement={
        action=action,
        mino=self.hand,
        x=self.handX,y=self.handY,
    }

    if action=='moveX' then
        if
            not self.ghostState and
            SET.tuck and
            self:ifoverlap(self.hand.matrix,self.handX,self.handY-1) and
            self:ifoverlap(self.hand.matrix,self.handX,self.handY+1)
        then
            movement.tuck=true
            self:playSound('tuck')
            if SET.particles then
                self:createTuckEffect()
            end
        end
    elseif action=='moveY' then
    elseif action=='rotate' then
        if not self.ghostState then
            if
                SET.spin_immobile and
                self:ifoverlap(self.hand.matrix,self.handX,self.handY-1) and
                self:ifoverlap(self.hand.matrix,self.handX,self.handY+1) and
                self:ifoverlap(self.hand.matrix,self.handX-1,self.handY) and
                self:ifoverlap(self.hand.matrix,self.handX+1,self.handY)
            then
                movement.immobile=true
                self:shakeBoard(C=='L' and '-ccw' or C=='R' and '-cw' or '-180')
                self:playSound('rotate_locked')
                if SET.particles then
                    self:createHandEffect(.942,1,1)
                end
            end
            if SET.spin_corners then
                local minoData=minoRotSys[SET.rotSys][self.hand.shape]
                local state=minoData[self.hand.direction]
                local centerPos=state and state.center or type(minoData.center)=='function' and minoData.center(self)
                if centerPos then
                    local cx,cy=self.handX+centerPos[1]-.5,self.handY+centerPos[2]-.5
                    if cx%1+cy%1==0 then
                        local corners=0
                        if self.field:getCell(cx-1,cy-1) then corners=corners+1 end
                        if self.field:getCell(cx+1,cy-1) then corners=corners+1 end
                        if self.field:getCell(cx-1,cy+1) then corners=corners+1 end
                        if self.field:getCell(cx+1,cy+1) then corners=corners+1 end
                        if corners>=SET.spin_corners then
                            movement.corners=true
                            self:playSound('rotate_corners')
                            if SET.particles then
                                self:createRotateCornerEffect(cx,cy)
                            end
                        end
                    end
                end
            end
        end
        self:playSound(D and 'rotate_init' or 'rotate')
        if SET.particles then
            self:createRotateEffect(C,D)
        end
    end
    self.lastMovement=movement

    self:tryCancelSuffocate()
end
function MP:restoreMinoState(mino) -- Restore a mino object's state (only inside, like shape, name, direction)
    if mino._origin then
        for k,v in next,mino._origin do
            mino[k]=v
        end
    end
    return mino
end
function MP:resetPos() -- Move hand piece to the normal spawn position
    self:moveHand('reset',floor(self.settings.fieldW/2-#self.hand.matrix[1]/2+1),self.settings.spawnH+1+ceil(self.fieldDived/40))

    self:triggerEvent('changeSpawnPos')

    self.deathTimer=false
    self.ghostState=false

    while self:isSuffocate() and self.handY<self.settings.spawnH+self.settings.extraSpawnH+1 do self.handY=self.handY+1 end
    self.minY=self.handY
    self.ghostY=false
    self:resetPosCheck()

    self:triggerEvent('afterResetPos')

end
function MP:resetPosCheck()
    local suffocated
    if self.deathTimer then
        self.ghostState=false
        suffocated=self:isSuffocate()
        self.ghostState=true
    else
        suffocated=self:isSuffocate()
    end

    if suffocated then
        if self.settings.deathDelay>0 then
            self.deathTimer=self.settings.deathDelay
            self.ghostState=true

            -- Suffocate IMS, always trigger when held
            if self.keyState.softDrop then self:moveDown() end
            if self.keyState.moveRight~=self.keyState.moveLeft then
                if self.keyState.moveRight then self:moveRight() else self:moveLeft() end
            end

            -- Suffocate IRS
            if self.settings.initRotate then
                if self.settings.initRotate=='hold' then
                    if self.keyState.rotate180 then
                        self:rotate('F',true)
                    elseif self.keyState.rotateCW~=self.keyState.rotateCCW then
                        self:rotate(self.keyState.rotateCW and 'R' or 'L',true)
                    end
                elseif self.settings.initRotate=='buffer' then
                    if self.keyBuffer.rotate then
                        self:rotate(self.keyBuffer.rotate,true)
                        if not self.keyBuffer.hold then
                            self.keyBuffer.rotate=false
                        end
                    end
                end
            end
            self:tryCancelSuffocate()
            self:freshGhost()

            if self.deathTimer then
                self:playSound('suffocate')
                if self.settings.particles then
                    self:createSuffocateEffect()
                end
            end
        else

            self:triggerEvent('whenSuffocate')
            self:freshGhost()

            if self:isSuffocate() then
                self:lock()
                self:finish('WA')
            end
            return
        end
    else
        -- IMS
        if self.settings.initMove then
            if self.settings.initMove=='hold' then
                if self.keyState.softDrop then self:moveDown() end
                if self.keyState.moveRight~=self.keyState.moveLeft then
                    if self.keyState.moveRight then self:moveRight(true) else self:moveLeft(true) end
                end
            elseif self.settings.initMove=='buffer' then
                if self.keyBuffer.move then
                    if self.keyBuffer.move=='L' then
                        self:moveLeft(true)
                    elseif self.keyBuffer.move=='R' then
                        self:moveRight(true)
                    end
                    self.keyBuffer.move=false
                end
            end
        end

        -- IRS
        if self.settings.initRotate then
            if self.settings.initRotate=='hold' then
                if self.keyState.rotate180 then
                    self:rotate('F',true)
                elseif self.keyState.rotateCW~=self.keyState.rotateCCW then
                    self:rotate(self.keyState.rotateCW and 'R' or 'L',true)
                end
            elseif self.settings.initRotate=='buffer' then
                if self.keyBuffer.rotate then
                    self:rotate(self.keyBuffer.rotate,true)
                    if not self.keyBuffer.hold then
                        self.keyBuffer.rotate=false
                    end
                end
            end
        end

        self:freshGhost()
        self:freshDelay('spawn')
    end

    if self.settings.stopMoveWhenSpawn then
        self.moveDir=false
        self.moveCharge=0
    elseif self.settings.ash>0 then
        self.moveCharge=min(self.moveCharge,self.settings.asd-self.settings.ash)
    end
end
function MP:freshGhost()
    if self.hand then
        if self.ghostState then
            self.ghostY=false
        else
            self.ghostY=min(self.field:getHeight()+1,self.handY)

            -- Move ghost to bottom
            while not self:ifoverlap(self.hand.matrix,self.handX,self.ghostY-1) do
                self.ghostY=self.ghostY-1
            end

            -- 20G check
            if (self.settings.dropDelay<=0 or self.downCharge and self.settings.asp==0) and self.ghostY<self.handY then
                local dY=self.ghostY-self.handY
                self:moveHand('drop',dY)
                self:freshDelay('drop')
                self:shakeBoard('-drop',-dY/self.settings.spawnH)
            else
                self:freshDelay('move')
            end
        end
    end
end
function MP:tryCancelSuffocate()
    if self.deathTimer then
        self.ghostState=false
        if self:isSuffocate() then
            self.ghostState=true
        else
            self.deathTimer=false
            self:playSound('desuffocate')
            if self.settings.particles then
                self:createDesuffocateEffect()
            end
        end
    end
end
local freshRuleMap={-- Normal: cost 1 chance, F: free, S: step (fall only) R: reset all, _: none
    move=  {any='N',fall='S',never='_'},
    rotate={any='N',fall='S',never='_'},
    moving={any='N',fall='S',never='_'},
    drop=  {any='F',fall='S',never='_'},
    spawn= {any='R',fall='R',never='R'},
}
---@param reason 'move'|'rotate'|'moving'|'drop'|'spawn'
function MP:freshDelay(reason)
    local fell=self.handY<self.minY
    if fell then self.minY=self.handY end

    local mode=freshRuleMap[reason][self.settings.freshCondition]

    if mode=='S' then mode=fell and 'N' or '_' end
    if mode=='N' or mode=='F' then
        local add=min(self.settings.lockDelay-self.lockTimer,self.freshTime)
        if self.freshChance>0 and self.lockTimer<self.settings.lockDelay and add>0 then
            self.lockTimer=self.lockTimer+add
            self.freshTime=self.freshTime-add
            self.freshChance=self.freshChance-(mode=='N' and 1 or 0)
            return true
        end
    elseif mode=='R' then
        self.dropTimer=self.settings.dropDelay
        self.lockTimer=self.settings.lockDelay
        self.freshChance=self.settings.maxFreshChance
        self.freshTime=self.settings.maxFreshTime
        return true
    elseif not mode then
        error("WTF why settings.freshCondition is "..tostring(self.settings.freshCondition))
    end
end
function MP:freshNextQueue()
    while #self.nextQueue<max(self.settings.nextSlot,1) do
        local shape=self:seqGen(self.seqData)
        if type(shape)=='number' then
            self:pushNext(shape)
        elseif type(shape)=='string' then
            self:pushNext(shape)
        elseif type(shape)=='table' then
            if shape[1] then
                self:pushNext(shape)
            else
                ins(self.nextQueue,self:getMino(shape))
            end
        else
            break
        end
    end
end
function MP:clearHold()
    TABLE.cut(self.holdQueue)
end
function MP:clearNext()
    TABLE.cut(self.nextQueue)
end
---@param piece string|number|table
function MP:pushNext(piece)
    if type(piece)=='number' then
        ins(self.nextQueue,self:getMino(Mino.get(piece)))
    elseif type(piece)=='string' then
        for i=1,#piece do
            ins(self.nextQueue,self:getMino(Mino.get(piece:sub(i,i))))
        end
    elseif type(piece)=='table' then
        for i=1,#piece do
            assert(type(piece[i])=='number' or type(piece[i])=='string',"Must be simple table")
            self:pushNext(piece[i])
        end
    else
        error("arg must be string or table")
    end
end
function MP:popNext(ifHold)
    if self.nextQueue[1] then -- Normally there area pieces in next queue
        self.hand=rem(self.nextQueue,1)
        self:freshNextQueue()
        if not ifHold then
            self.holdTime=0
        end
    else -- Next queue is empty
        if self.holdQueue[1] then -- Force using hold
            ins(self.nextQueue,rem(self.holdQueue,1))
            self:popNext()
        else -- No piece to use, game over
            self:finish('ILE')
        end
        return
    end

    -- IHS
    local IHStriggered
    if not ifHold and self.settings.initHold then
        if self.settings.initHold=='hold' then
            if self.keyState.holdPiece then
                self:hold(true)
                IHStriggered=true
            end
        elseif self.settings.initHold=='buffer' then
            if self.keyBuffer.hold then
                self.keyBuffer.hold=false
                self:hold(true)
                IHStriggered=true
            end
        end
    end

    if not IHStriggered then
        self:resetPos()
    end

    self:triggerEvent('afterSpawn')

    if self.keyBuffer.hardDrop then -- IHdS
        self.keyBuffer.hardDrop=false
        self:minoDropped()
    end
end
---@return Techmino.Cell
function MP:newCell(color,id)
    self.totalCellCount=self.totalCellCount+1
    local c={
        cid='_'..STRING.toHex(self.totalCellCount),
        id=id,
        color=color or 0,
        conn={},
    }
    return c
end
function MP:getMino(shapeData)
    local shapeID,shapeName,shapeMat,shapeColor
    if type(shapeData)=='table' then
        shapeID=shapeData.id
        shapeName=shapeData.name or "?"
        shapeMat=TABLE.shift(shapeData.shape)
        shapeColor=shapeData.color or defaultMinoColor[shapeID] or self:random(64)
    else
        shapeID=shapeData
        assert(type(shapeID)=='number',"shapeID must be number")
        shapeName=Mino.getName(shapeID)
        shapeMat=TABLE.shift(Mino.getShape(shapeID))
        shapeColor=defaultMinoColor[shapeID]
    end
    self.pieceCount=self.pieceCount+1

    -- Generate cell matrix from bool matrix
    for y=1,#shapeMat do for x=1,#shapeMat[1] do
        shapeMat[y][x]=shapeMat[y][x] and self:newCell(shapeColor,self.pieceCount)
    end end

    -- Connect cells
    for y=1,#shapeMat do for x=1,#shapeMat[1] do
        if shapeMat[y][x] then
            local L=shapeMat[y][x].conn
            local b
            b=shapeMat[y]   if b and b[x-1] then L[b[x-1].cid]=0 end
            b=shapeMat[y]   if b and b[x+1] then L[b[x+1].cid]=0 end
            b=shapeMat[y-1] if b and b[x]   then L[b[x]  .cid]=0 end
            b=shapeMat[y+1] if b and b[x]   then L[b[x]  .cid]=0 end
            b=shapeMat[y-1] if b and b[x-1] then L[b[x-1].cid]=0 end
            b=shapeMat[y-1] if b and b[x+1] then L[b[x+1].cid]=0 end
            b=shapeMat[y+1] if b and b[x-1] then L[b[x-1].cid]=0 end
            b=shapeMat[y+1] if b and b[x+1] then L[b[x+1].cid]=0 end
        end
    end end

    local mino={
        id=self.pieceCount,
        shape=shapeID,
        direction=0,
        name=shapeName,
        matrix=shapeMat,
    }
    mino._origin=TABLE.copy(mino,0)
    return mino
end
function MP:getConnectedCells(x0,y0)
    local F=self.field
    local cell=F:getCell(x0,y0)
    if cell then
        local list={{x0,y0,cell},[cell]=true}
        local ptr=1
        while list[ptr] do
            local x,y,c0=list[ptr][1],list[ptr][2],list[ptr][3]
            if c0.conn then
                local c1
                c1=F:getCell(x+1,y) if c1 and not list[c1] and c0.conn[c1.cid] then ins(list,{x+1,y,c1}) list[c1]=true end
                c1=F:getCell(x-1,y) if c1 and not list[c1] and c0.conn[c1.cid] then ins(list,{x-1,y,c1}) list[c1]=true end
                c1=F:getCell(x,y+1) if c1 and not list[c1] and c0.conn[c1.cid] then ins(list,{x,y+1,c1}) list[c1]=true end
                c1=F:getCell(x,y-1) if c1 and not list[c1] and c0.conn[c1.cid] then ins(list,{x,y-1,c1}) list[c1]=true end
            end
            ptr=ptr+1
        end
        return list
    else
        return {}
    end
end
function MP:compareMatrix(S1,S2)
    if not S2 then
        if not self.hand then return false end
        S2=self.hand.matrix
    end
    if #S1~=#S2 then return false end
    for y=1,#S1 do
        if #S1[y]~=#S2[y] then return false end
        for x=1,#S1[1] do
            if not not S1[y][x]~=not not S2[y][x] then
                return false
            end
        end
    end
    return true
end
function MP:cutConnection(y) -- y is cutting line height to ground
    local F=self.field
    if y<1 or y>F:getHeight() then return end
    for x=1,self.settings.fieldW do
        local cell=F:getCell(x,y)
        if cell then
            local listLo=self:getConnectedCells(x,y)
            local listHi={}
            for i=#listLo,1,-1 do
                if listLo[i][2]>y then
                    ins(listHi,rem(listLo,i))
                end
            end
            for i=1,#listLo do
                for j=1,#listHi do
                    listLo[i][3].conn[listHi[j][3].cid]=nil
                    listHi[j][3].conn[listLo[i][3].cid]=nil
                end
            end
        end
    end
end
function MP:ifoverlap(CB,cx,cy)
    local F=self.field

    -- Must in wall
    if cx<=0 or cx+#CB[1]-1>self.settings.fieldW or cy<=0 then return true end

    -- Special check
    for i=1,#self.event.extraSolidCheck do
        local res=self.event.extraSolidCheck[i](self,CB,cx,cy)
        if res~=nil then return res end
    end

    -- Must in air
    if cy>F:getHeight() then return false end

    if not self.ghostState then
        -- Check field
        for y=1,#CB do for x=1,#CB[1] do
            if CB[y][x] and self.field:getCell(cx+x-1,cy+y-1) then
                return true
            end
        end end
    end

    -- No collision
    return false
end
function MP:checkLanding(sparkles,drop)
    if self.handY==self.ghostY then
        if drop then
            self:playSound('touch')
        end
        if sparkles and self.settings.particles then
            self:createTouchEffect()
        end
    end
end
function MP:isSuffocate()
    return self.hand and self:ifoverlap(self.hand.matrix,self.handX,self.handY)
end
function MP:parseAtkInfo(g)
    -- TODO: 'speed' not applied

    -- Calculate hole count and splitting probabality
    local count=1+max((g.fatal-50)/20,0)
    local splitRate=0
    if count~=floor(count) then
        if self:random()>count%1 then
            splitRate=count%1/2
            count=floor(count)
        else
            splitRate=-(count%1/2)
            count=ceil(count)
        end
    end

    local copyRate=1-g.fatal/40
    local sandwichRate=(g.fatal-20)/120

    return count,splitRate,copyRate,sandwichRate
end
function MP:calculateHolePos(count,splitRate,copyRate,sandwichRate)
    local holePos={}
    local F=self.field
    local weights=TABLE.new(.03,self.settings.fieldW)

    -- Check bottom state of every column and calculate weight
    for x=1,#weights do
        if F:getCell(x,1) then
            if not F:getCell(x,2) then
                weights[x]=weights[x]+sandwichRate
            elseif not F:getCell(x,3) then
                weights[x]=weights[x]+sandwichRate/2
            end
        else
            -- Get hole height
            local y=2
            while y<4 and not F:getCell(x,y) do
                y=y+1
            end
            -- Height-Score rate: 2 → 1x, 3 → 1.5x, 4(max) → 2x
            weights[x]=weights[x]+copyRate*y/2
        end
        weights[x]=clamp(weights[x],.03,1)
    end

    -- Pick hole position
    for _=1,count do
        local sum=0
        for i=1,#weights do sum=sum+weights[i] end

        -- local str=""
        -- for i=1,#weights do
        --     str=str..string.format("%03d",weights[i]*100).." "
        -- end
        -- print(str)

        local r=sum*self:random()
        if sum>0 then
            for i=1,#weights do
                r=r-weights[i]
                if r<=0 then
                    r=i
                    break
                end
            end
            weights[r]=.03
            if r>1        then weights[r-1]=clamp(weights[r-1]-splitRate,.03,1) end
            if r<#weights then weights[r+1]=clamp(weights[r+1]-splitRate,.03,1) end
        else
            error("WTF why sum of weights is 0")
        end
        ins(holePos,r)
    end
    return holePos
end
function MP:moveLeft(ifInit)
    if not self:ifoverlap(self.hand.matrix,self.handX-1,self.handY) then
        self:moveHand('moveX',-1,true)
        if not ifInit then self:freshGhost() end
        return true
    end
end
function MP:moveRight(ifInit)
    if not self:ifoverlap(self.hand.matrix,self.handX+1,self.handY) then
        self:moveHand('moveX',1,true)
        if not ifInit then self:freshGhost() end
        return true
    end
end
function MP:moveDown()
    if not self:ifoverlap(self.hand.matrix,self.handX,self.handY-1) then
        self:moveHand('moveY',-1,true)
        self:freshDelay('drop')
        return true
    end
end
function MP:moveUp() -- ?
    if not self:ifoverlap(self.hand.matrix,self.handX,self.handY+1) then
        self:moveHand('moveY',1,true)
        return true
    end
end
function MP:rotate(dir,ifInit)
    if self.settings.stopMoveWhenRotate then
        self.moveDir=false
        self.moveCharge=0
    end

    if not self.hand then return end
    if dir~='R' and dir~='L' and dir~='F' then error("WTF why dir isn't R/L/F ("..tostring(dir)..")") end

    local minoData=minoRotSys[self.settings.rotSys][self.hand.shape]
    if not minoData then return end

    local origY=self.handY -- For IRS pushing up
    if minoData.rotate then -- Custom rotate function
        minoData.rotate(self,dir,ifInit)
        if self.ghostState and self.settings.IRSpushUp then self:moveHand('moveY',origY-self.handY) end
        self:freshGhost()
    else -- Normal rotate procedure
        local preState=minoData[self.hand.direction]
        if preState then
            -- Rotate matrix
            local kick=preState[dir]
            if not kick then return end -- This RS doesn't define this rotation

            local cb=self.hand.matrix
            local icb=TABLE.rotate(cb,dir)
            local baseX,baseY

            local afterState=minoData[kick.target]
            if kick.base then
                baseX=kick.base[1]
                baseY=kick.base[2]
            elseif preState.center and afterState.center then
                baseX=preState.center[1]-afterState.center[1]
                baseY=preState.center[2]-afterState.center[2]
            else
                error("Cannot get baseX/Y")
            end

            for n=1,#kick.test do
                local ix,iy=self.handX+baseX+kick.test[n][1],self.handY+baseY+kick.test[n][2]
                if not self:ifoverlap(icb,ix,iy) then
                    self.hand.matrix=icb
                    self.hand.direction=kick.target
                    self:moveHand('rotate',ix,iy,dir,ifInit)
                    if self.ghostState and self.settings.IRSpushUp then self:moveHand('moveY',origY-self.handY) end
                    self:freshGhost()
                    return
                end
            end
            if not ifInit then self:freshDelay('rotate') end
            self:playSound('rotate_failed')
            if self.settings.particles then
                self:createHandEffect(1,.26,.26)
            end
        else
            error("WTF why no state in minoData")
        end
    end
end
function MP:hold(ifInit)
    if self.holdTime>=self.settings.holdSlot and not self.settings.infHold then return end

    if self.settings.particles then
        self:createHoldEffect(ifInit)
    end
    if self.settings.stopMoveWhenHold then
        self.moveDir=false
        self.moveCharge=0
    end

    local mode=self.settings.holdMode
    if     mode=='hold'  then self:hold_hold()
    elseif mode=='swap'  then self:hold_swap()
    elseif mode=='float' then self:hold_float()
    else   error("WTF why hold mode is "..tostring(mode))
    end

    self.holdTime=self.holdTime+1
    self:playSound(ifInit and 'hold_init' or 'hold')
end
function MP:hold_hold()
    if not self.settings.holdKeepState then
        self.hand=self:restoreMinoState(self.hand)
    end

    -- Swap hand and hold
    local swapN=self.holdTime%self.settings.holdSlot+1
    self.hand,self.holdQueue[swapN]=self.holdQueue[swapN],self.hand

    -- Reset position or pop next out
    if self.hand then
        self:resetPos()
    else
        self:popNext(true)
    end
end
function MP:hold_swap()
    local swapN=self.holdTime%self.settings.holdSlot+1
    if self.nextQueue[swapN] then
        if not self.settings.holdKeepState then
            self.hand=self:restoreMinoState(self.hand)
        end
        self.hand,self.nextQueue[swapN]=self.nextQueue[swapN],self.hand
        self:resetPos()
    end
end
function MP:hold_float()
    local swapN=self.holdTime%self.settings.holdSlot+1
    if self.floatHolds[swapN] then
        local h=self.floatHolds[swapN]
        h.hand,self.hand=self.hand,h.hand
        h.handX,self.handX=self.handX,h.handX
        h.handY,self.handY=self.handY,h.handY
        h.lastMovement,self.lastMovement=self.lastMovement,h.lastMovement
        h.minY,self.minY=self.minY,h.minY
        while self:isSuffocate() and self.handY<self.settings.spawnH+self.settings.extraSpawnH+1 do self.handY=self.handY+1 end
        self:resetPosCheck()
    else
        self.floatHolds[swapN]={
            hand=self.hand,
            handX=self.handX,
            handY=self.handY,
            lastMovement=self.lastMovement,
            minY=self.minY,
        }
        self.hand=false
        self.handX,self.handY=false,false
        self:popNext(true)
    end
end
function MP:doClear(fullLines)
    mechLib.mino.clearRule[self.settings.clearRule].clear(self,fullLines)
    local n=#fullLines
    local his={
        combo=self.combo,
        line=n,
        linePos=fullLines,
        time=self.time,
    }
    ins(self.clearHistory,his)
    self:shakeBoard('-clear',n)
    self:playSound('clear',n)
    if self.settings.particles then
        self:createFrenzyEffect(min(n^2*6,260))
    end

    self:triggerEvent('afterClear',his)

end

function MP:minoDropped() -- Drop & lock mino, and trigger a lot of things
    if not self.hand or self.ghostState then return end

    local SET=self.settings

    -- Move down
    if self.ghostY and self.handY>self.ghostY then
        self.soundTimeHistory.touch=self.time -- Cancel touching sound
        self:moveHand('drop',self.ghostY-self.handY)
        self:shakeBoard('-drop',1)
        self:playSound('drop')
    end

    self:triggerEvent('afterDrop')
    if not self.hand or self.finished then return end

    if SET.particles then
        self:createLockEffect()
    end

    -- Lock to field
    self:lock()
    ins(self.dropHistory,{
        id=self.hand.id,
        direction=self.hand.direction,
        x=self.handX,
        y=self.handY,
        time=self.time,
    })
    if self.handY+#self.hand.matrix-1>SET.deathH then
        self:finish('MLE')
        return
    end
    self:playSound('lock')

    self:triggerEvent('afterLock')
    if self.finished then return end

    -- Clear
    local fullLines=mechLib.mino.clearRule[SET.clearRule].getFill(self)
    if fullLines then
        self.combo=self.combo+1
        self.lastMovement.clear=fullLines
        self.lastMovement.combo=self.combo
        self:doClear(fullLines)
    else
        self.combo=0
    end

    -- Attack
    local atk=GAME.initAtk(mechLib.mino.attackSys[SET.atkSys].drop(self))
    if atk then

        self:triggerEvent('beforeCancel',atk)

        if SET.allowCancel then
            while atk and self.garbageBuffer[1] do
                local ap=atk.power*(atk.cancelRate or 1)
                local gbg=self.garbageBuffer[1]
                local gp=gbg.power*(gbg.defendRate or 1)
                local cancel=min(ap,gp)
                ap=ap-cancel
                gp=gp-cancel
                local newGP=floor(gp/(gbg.defendRate or 1)+.5)
                if newGP==0 then
                    atk.power=ap/(atk.cancelRate or 1)
                    self.garbageSum=self.garbageSum-gbg.power
                    rem(self.garbageBuffer,1)
                else
                    self.garbageSum=self.garbageSum+newGP-gbg.power
                    gbg.power=newGP
                end
                if ap==0 then
                    atk=nil
                    break
                end
            end
        end
        if atk and atk.power>=.5 then
            atk.power=floor(atk.power+.5)

            self:triggerEvent('beforeSend',atk)

            GAME.send(self,atk)
        end
        if self.finished then return end
    end

    -- Lockout check
    if self.handY>SET.lockoutH and (SET.strictLockout or not fullLines)  then
        self:finish('CE')
        return
    end

    self:triggerEvent('beforeDiscard')

    -- Discard hand
    self.hand=false
    self.handX,self.handY=false,false
    if self.finished then return end

    -- Update & Release garbage
    if not (SET.clearStuck and fullLines) then
        local iBuffer=1
        while true do
            local g=self.garbageBuffer[iBuffer]
            if not g then break end
            if g._time==g.time then
                local holePos=self:calculateHolePos(self:parseAtkInfo(g))

                -- Pushing up
                for _=1,g.power do
                    self:riseGarbage(holePos)
                end

                rem(self.garbageBuffer,iBuffer)
                self.garbageSum=self.garbageSum-g.power
                iBuffer=iBuffer-1 -- Avoid index error
            elseif g.mode==1 then
                g._time=g._time+1
            end
            iBuffer=iBuffer+1
        end
    end

    self.spawnTimer=SET.spawnDelay+(fullLines and mechLib.mino.clearRule[SET.clearRule].getDelay(self,fullLines) or 0)

    -- Fresh hand
    if self.spawnTimer<=0 then
        self:popNext()
    end
end
function MP:lock() -- Put mino into field
    local CB=self.hand.matrix
    local F=self.field
    for y=1,#CB do for x=1,#CB[1] do
        local c=CB[y][x]
        if c then
            if self.settings.pieceVisTime then
                if self.settings.pieceVisTime==0 then
                    c.alpha=0
                else
                    c.visTimer=self.settings.pieceVisTime
                    c.fadeTime=self.settings.pieceFadeTime
                end
            end
            F:setCell(c,self.handX+x-1,self.handY+y-1)
        end
    end end
end
function MP:diveDown(cells)
    if self.fieldDived==0 then
        self.fieldRisingSpeed=self.settings.initialRisingSpeed
    end
    self.fieldDived=self.fieldDived+cells*40
end
function MP:riseGarbage(holePos)
    local w=self.settings.fieldW
    local L={}

    -- Generate line
    for x=1,w do
        L[x]=self:newCell(0)
    end

    -- Generate hole
    if type(holePos)=='number' then
        L[holePos]=false
    elseif type(holePos)=='table' then
        for i=1,#holePos do
            L[holePos[i]]=false
        end
    else
        L[rnd(w)]=false
    end

    -- Add connection
    for x=1,w do
        if L[x] then
            if L[x-1] then L[x].conn[L[x-1].cid]=0 end
            if L[x+1] then L[x].conn[L[x+1].cid]=0 end
        end
    end
    ins(self.field._matrix,1,L)

    -- Update buried depth and rising speed
    self:diveDown(1)

    -- Update hand position (if exist)
    if self.hand then
        self.handY=self.handY+1
        self.minY=self.minY+1
        self:freshGhost()
    end
end
--[[ arg table={
    -- map matrix (will display as you see, any height)
    {7,7,7,7,0,0,0,0,1,1},
    {4,6,6,3,0,0,0,1,1,5},
    {4,6,6,3,0,0,2,2,5,5},
    {4,4,3,3,0,0,0,2,2,5},
}]]
---@param arg {color:'template'|'absolute'|nil, resetHand?:boolean, sudden?:boolean, number:table<number, number>}
function MP:setField(arg)
    local F=self.field
    local w=self.settings.fieldW
    local f={}

    local color=arg.color
    if color==nil then color='template' end
    assert(color=='template' or color=='absolute',"arg.color must be <'template'|'absolute'>")

    local sudden=arg.sudden
    if sudden==nil then sudden=true end
    assert(type(sudden)=='boolean' ,"arg.sudden must be boolean")

    local resetHand=arg.resetHand
    if resetHand==nil then resetHand=true end
    assert(type(resetHand)=='boolean' ,"arg.resetHand must be boolean")

    -- Translate field matrix
    for y=1,#arg do
        f[y]={}
        for x=1,w do
            local c=arg[y][x]
            if type(c)=='number' then
                if color=='template' then
                    if c%1==0 and c>=1 and c<=7 then
                        c=defaultMinoColor[c]
                    elseif c==8 then
                        c=0
                    else
                        c=false
                    end
                end
                if c and c%1==0 and c>=0 and c<=64 then
                    f[y][x]=self:newCell(c)
                else
                    f[y][x]=false
                end
            end
        end
    end

    -- Create connection
    for y=1,#arg do
        for x=1,w do
            if f[y][x] then
                if f[y]   and f[y][x-1] then f[y][x].conn[f[y][x-1]]=0 end
                if f[y]   and f[y][x+1] then f[y][x].conn[f[y][x+1]]=0 end
                if f[y-1] and f[y-1][x] then f[y][x].conn[f[y-1][x]]=0 end
                if f[y+1] and f[y+1][x] then f[y][x].conn[f[y+1][x]]=0 end
            end
        end
    end

    -- Apply field
    TABLE.cut(F._matrix)
    for y=1,#arg do
        F._matrix[y]=f[#arg+1-y]
    end

    -- Field rising animation
    self.fieldRisingSpeed=0
    self.fieldDived=0
    if not sudden then self:diveDown(#arg) end

    -- Reset current block
    if self.hand and (resetHand==true or self:isSuffocate()) then
        self:resetPos()
    end
    self:freshGhost()
end
function MP:changeFieldWidth(w,origPos)
    if w>0 and w%1==0 then
        if not origPos then origPos=1 end
        local w0=self.settings.fieldW
        for y=1,#self.field:getHeight() do
            local L=TABLE.new(false,w)
            for x=1,w0 do
                local newX=origPos+x-1
                if newX>=1 and newX<=w then
                    L[newX]=self.field._matrix[y][x]
                end
            end
        end
        self.settings.fieldW=w
        self.field._width=w
        self.field:fresh()
    end
end
function MP:receive(data)
    local B={
        power=data.power,
        cancelRate=data.cancelRate,
        defendRate=data.defendRate,
        mode=data.mode,
        time=floor(data.time+.5),
        _time=0,
        fatal=data.fatal,
        speed=data.speed,
    }
    ins(self.garbageBuffer,B)
    self.garbageSum=self.garbageSum+data.power
end
function MP:getScriptValue(arg)
    return
        arg.d=='field_width' and self.settings.fieldW or
        arg.d=='field_height' and self.field:getHeight() or
        arg.d=='cell' and (self.field:getCell(arg.x,arg.y) and 1 or 0)
end
--------------------------------------------------------------
-- Press & Release & Update & Render
function MP:updateFrame()
    local SET=self.settings

    -- Hard-drop lock
    if self.aHdLockTimer>0 then self.aHdLockTimer=self.aHdLockTimer-1 end
    if self.mHdLockTimer>0 then self.mHdLockTimer=self.mHdLockTimer-1 end

    -- Current controlling piece
    if not self.deathTimer then
        -- Auto shift
        if self.moveDir and (self.moveDir==-1 and self.keyState.moveLeft or self.moveDir==1 and self.keyState.moveRight) then
            if self.hand and not self:ifoverlap(self.hand.matrix,self.handX+self.moveDir,self.handY) then
                local dist=0
                if self.moveCharge>=SET.asd then
                    if SET.asp==0 then
                        dist=1e99
                    elseif (self.moveCharge-SET.asd)%SET.asp==0 then
                        dist=1
                    end
                end
                if dist>0 then
                    local ox=self.handX
                    while dist>0 and not self:ifoverlap(self.hand.matrix,self.handX+self.moveDir,self.handY) do
                        self:moveHand('moveX',self.moveDir)
                        self:freshGhost()
                        dist=dist-1
                    end
                    if self.handX~=ox then
                        self:playSound('move')
                    end
                end
                self.moveCharge=self.moveCharge+1 -- NOTICE: this may have problem
            else
                if not self.hand then
                    if SET.entryChrg=='full' then
                        self.moveCharge=SET.asd
                    elseif SET.entryChrg=='on' then
                        self.moveCharge=min(self.moveCharge+1,SET.asd)
                    elseif SET.entryChrg=='break' then
                        self.moveDir=false
                        self.moveCharge=0
                    end
                else
                    if SET.wallChrg=='full' then
                        self.moveCharge=SET.asd
                        self:shakeBoard(self.moveDir>0 and '-right' or '-left')
                    elseif SET.wallChrg=='on' then
                        self.moveCharge=min(self.moveCharge+1,SET.asd)
                        self:shakeBoard(self.moveDir>0 and '-right' or '-left')
                    elseif SET.wallChrg=='break' then
                        self.moveDir=false
                        self.moveCharge=0
                    end
                end
            end
        end

        -- Auto drop
        if self.downCharge and self.keyState.softDrop then
            local dropASD=SET.softdropSkipAsd and SET.asp or SET.asd
            if self.hand and not self:ifoverlap(self.hand.matrix,self.handX,self.handY-1) then
                local dist=0
                if self.downCharge>=dropASD then
                    if SET.asp==0 then
                        dist=1e99
                    elseif (self.downCharge-dropASD)%SET.asp==0 then
                        dist=1
                    end
                end
                if dist>0 then
                    local oy=self.handY
                    while dist>0 do
                        if not self:moveDown() then break end
                        dist=dist-1
                    end
                    if oy~=self.handY then
                        self:freshDelay('drop')
                        self:playSound('move_down')
                        if self.handY==self.ghostY then
                            self:shakeBoard('-down')
                        end
                        if self.settings.particles then
                            self:createTouchEffect()
                        end
                    end
                end
                self.downCharge=self.downCharge+1
            else
                self.downCharge=dropASD
                if self.hand then
                    self:shakeBoard('-down')
                end
            end
        else
            self.downCharge=false
        end

        -- Update hand
        repeat
            -- Try spawn mino if don't have one
            if self.spawnTimer>0 then
                self.spawnTimer=self.spawnTimer-1
                if self.spawnTimer<=0 then
                    self:popNext()
                end
                break
            elseif not self.hand then
                self:popNext()
            end

            -- Try lock/drop mino
            if self.handY==self.ghostY then
                self.lockTimer=self.lockTimer-1
                if self.lockTimer<=0 then
                    -- Yield LockDelay for moving
                    if self.moveDir and not self:ifoverlap(self.hand.matrix,self.handX+self.moveDir,self.handY) then
                        local inASD=self.moveCharge<SET.asd-SET.asp
                        if inASD and SET.freshLockInASD or not inASD and SET.freshLockInASP then
                            if self:freshDelay('move') then break end
                        end
                    end
                    self.aHdLockTimer=self.settings.aHdLock
                    self:minoDropped()
                end
                break
            else
                if self.dropTimer>0 then
                    self.dropTimer=self.dropTimer-1
                    if self.dropTimer<=0 then
                        self:moveHand('drop',-1,true)
                    end
                elseif self.handY~=self.ghostY then -- If switch to 20G during game, mino won't dropped to bottom instantly so we force fresh it
                    self:freshDelay('drop')
                end
            end
        until true
    else
        self.deathTimer=self.deathTimer-1
        if self.deathTimer<=0 then
            self.deathTimer=false
            self.ghostState=false

            self:triggerEvent('whenSuffocate')
            self:freshGhost()

            if self:isSuffocate() then
                self:lock()
                self:finish('WA')
            end
            return
        end
    end

    -- Update garbage
    for i=1,#self.garbageBuffer do
        local g=self.garbageBuffer[i]
        if g.mode==0 and g._time<g.time then
            g._time=g._time+1
        end
    end

    -- Update field cells' visiblity
    local F=self.field._matrix
    for y=1,#F do for x=1,#F[1] do
        local C=F[y][x]
        if C then
            if C.visTimer then
                local step=C.visStep or -1
                C.visTimer=C.visTimer+step
                C.alpha=clamp(C.visTimer/C.fadeTime,0,1)
                if step<0 and C.visTimer<=0 or step>0 and C.visTimer>=(C.visMax or C.fadeTime) then
                    C.visTimer=nil
                end
            end
            local b=C.bias
            if b then
                if b.expBack then
                    b.x=expApproach(b.x,0,b.expBack)
                    b.y=expApproach(b.y,0,b.expBack)
                    if b.x^2+b.y^2<=.26^2 then
                        C.bias=nil
                    end
                elseif b.lineBack then
                    local dist=(b.x^2+b.y^2)^.5
                    if b.lineBack>=dist then
                        C.bias=nil
                    else
                        local k=1-b.lineBack/dist
                        b.x,b.y=b.x*k,b.y*k
                    end
                elseif b.teleBack then
                    b.teleBack=b.teleBack-1
                    if b.teleBack<=0 then
                        C.bias=nil
                    end
                end
            end
        end
    end end

    -- Update field depth
    if self.fieldDived>0 then
        -- Update fieldRisingSpeed first
        if self.fieldRisingSpeed>SET.maxRisingSpeed then
            self.fieldRisingSpeed=max(self.fieldRisingSpeed-SET.risingDeceleration,SET.maxRisingSpeed)
        elseif self.fieldRisingSpeed<SET.minRisingSpeed then
            self.fieldRisingSpeed=min(self.fieldRisingSpeed+SET.risingAcceleration,SET.minRisingSpeed)
        end
        self.fieldRisingSpeed=min(self.fieldRisingSpeed,(2*self.fieldDived*SET.risingDeceleration)^.5)

        -- Change fieldDived
        self.fieldDived=self.fieldDived-self.fieldRisingSpeed
        if self.fieldDived<=0 then
            self.fieldDived=0
            self.fieldRisingSpeed=0
        end
    end
end
function MP:render()
    local SET=self.settings
    local skin=SKIN.get(SET.skin)
    SKIN.time=self.time

    gc_push('transform')

    -- Player's transform
    local pos=self.pos
    gc_translate(pos.x,pos.y)
    gc_scale(pos.k*(1+pos.dk))
    gc_translate(pos.dx,pos.dy)
    gc_rotate(pos.a+pos.da)

    -- Field's transform
    gc_push('transform')

        gc_translate(-200,400)

        -- Start field stencil
        GC.stc_setComp('equal',1)
        GC.stc_rect(0,0,400,-1600)
        gc_scale(10/SET.fieldW)

            self:triggerEvent('drawBelowField') -- From frame's bottom-left, 40px a cell

            -- Grid & Cells
            skin.drawFieldBackground(SET.fieldW)

            gc_translate(0,self.fieldDived)

                do -- Field
                    local matrix=self.field._matrix
                    gc_push('transform')
                    gc_translate(0,-40) -- Move to up-left corner of first cell

                    local width=SET.fieldW
                    for y=1,#matrix do
                        for x=1,width do
                            local C=matrix[y][x]
                            if C then
                                if C.bias then
                                    gc_translate(C.bias.x,C.bias.y)
                                    skin.drawFieldCell(C,matrix,x,y)
                                    gc_translate(-C.bias.x,-C.bias.y)
                                else
                                    skin.drawFieldCell(C,matrix,x,y)
                                end
                            end
                            gc_translate(40,0)
                        end
                        gc_translate(-40*width,-40) -- \r\n (Return + Newline)
                    end
                    gc_pop()
                end

                self:triggerEvent('drawBelowBlock') -- From field's bottom-left, 40px a cell

                gc_setColor(1,1,1)
                gc_draw(self.particles.rectShade)
                gc_draw(self.particles.tiltRect)

                if self.hand then
                    local CB=self.hand.matrix

                    -- Ghost
                    if not self.deathTimer and self.ghostY then
                        skin.drawGhost(CB,self.handX,self.ghostY)
                    end

                    -- Hand
                    if not self.deathTimer or (2600/(self.deathTimer+260)-self.deathTimer/260)%1>.5 then
                        -- Smooth
                        local dx,dy=self:getSmoothPos()
                        gc_translate(dx,dy)

                        skin.drawHandStroke(CB,self.handX,self.handY)
                        skin.drawHand(CB,self.handX,self.handY)

                        local RS=minoRotSys[SET.rotSys]
                        local minoData=RS[self.hand.shape]
                        if minoData then
                            local state=minoData[self.hand.direction]
                            local centerPos=state and state.center or type(minoData.center)=='function' and minoData.center(self)
                            if centerPos then
                                gc_setColor(1,1,1,.8)
                                GC.mDraw(RS.centerTex,(self.handX+centerPos[1]-1)*40,-(self.handY+centerPos[2]-1)*40,nil,1.26)
                            end
                        end

                        gc_translate(-dx,-dy)
                    end
                end

                -- Float hold
                if #self.floatHolds>0 then
                    for n=1,#self.floatHolds do
                        local H=self.floatHolds[n]
                        skin.drawFloatHold(n,H.hand.matrix,H.handX,H.handY,SET.holdMode=='float' and not SET.infHold and n<=self.holdTime)
                    end
                end

                self:triggerEvent('drawBelowMarks') -- From field's bottom-left, 40px a cell

            -- Height lines
            skin.drawHeightLines(     -- All unit are pixel
                SET.fieldW*40,   -- Field Width
                (SET.spawnH+SET.extraSpawnH)*40, -- Max Spawning height
                SET.spawnH*40,   -- Spawning height
                SET.lockoutH*40, -- Lock-out height
                SET.deathH*40,   -- Death height
                SET.voidH*40     -- Void height
            )

            self:triggerEvent('drawInField') -- From frame's bottom-left, 40px a cell

            gc_setColor(1,1,1)
            gc_draw(self.particles.cornerCheck)
            self.particles.spinArrow:draw()
            gc_draw(self.particles.trail)
            gc_draw(self.particles.hitSparkle)

            gc_translate(0,-self.fieldDived)

        -- Stop field stencil
        GC.stc_stop()

        gc_setColor(1,1,1)
        gc_draw(self.particles.boardSmoke)
        gc_draw(self.particles.star)
        gc_draw(self.particles.line)

    gc_pop()

    -- Field border
    skin.drawFieldBorder()

    -- Asd indicator
    skin.drawAsdIndicator(self.moveDir,self.moveCharge,SET.asd,SET.asp,SET.ash)

    -- Delay indicator
    if not self.hand then -- Spawn
        skin.drawDelayIndicator(COLOR.lB,self.spawnTimer/SET.spawnDelay)
    elseif self.deathTimer then -- Death
        skin.drawDelayIndicator(COLOR.R,self.deathTimer/SET.deathDelay)
    else -- Lock
        skin.drawDelayIndicator(COLOR.lY,self.lockTimer/SET.lockDelay)
    end

    -- Garbage buffer
    skin.drawGarbageBuffer(self.garbageBuffer)

    -- Lock delay indicator
    skin.drawLockDelayIndicator(SET.freshCondition,self.freshChance,self.time<SET.readyDelay and (self.time/SET.readyDelay)^2.6 or self.freshTime/SET.maxFreshTime)

    -- Next (Almost same as drawing hold(s), don't forget to change both)
    gc_push('transform')
    gc_translate(200,-400)
    skin.drawNextBorder(SET.nextSlot)
    for n=1,min(#self.nextQueue,SET.nextSlot) do
        skin.drawNext(n,self.nextQueue[n].matrix,SET.holdMode=='swap' and not SET.infHold and n<=self.holdTime)
    end
    gc_pop()

    -- Hold (Almost same as drawing next(s), don't forget to change both)
    gc_push('transform')
    gc_translate(-200,-400)
    skin.drawHoldBorder(SET.holdMode,SET.holdSlot)
    if #self.holdQueue>0 then
        for n=1,#self.holdQueue do
            skin.drawHold(n,self.holdQueue[n].matrix,SET.holdMode=='hold' and not SET.infHold and n<=self.holdTime)
        end
    end
    gc_pop()

    -- Timer
    skin.drawTime(self.gameTime)

    -- Texts
    self.texts:draw()

    self:triggerEvent('drawOnPlayer') -- From player's center

    -- Starting counter
    if self.time<SET.readyDelay then
        skin.drawStartingCounter(SET.readyDelay)
    end

    -- Fade out at top
    -- gc.setBlendMode('multiply','premultiplied')
    -- gc.setColorMask(false,false,false,true)
    -- for i=0,99,2 do
    --     gc.setColor(0,0,0,(1-i/100)^2)
    --     gc.rectangle('fill',-200,-422-i,400,-2)
    -- end
    -- gc.setBlendMode('alpha')
    -- gc.setColorMask()

    gc_pop()
end
--------------------------------------------------------------
-- Other
function MP:decodeScript(line,errMsg)
    if line.cmd=='setField' then
    elseif line.cmd=='switchAction' then
    elseif line.cmd=='clearHold' then
        line.arg=nil
    elseif line.cmd=='clearNext' then
        line.arg=nil
    elseif line.cmd=='pushNext' then
        if line.arg:find(",") then
            line.arg=line.arg:split(",")
        else
            assert(not line.arg:find("[^0-9a-zA-Z]"),errMsg.."Wrong arg")
        end
    else
        error(errMsg.."No string command '"..line.cmd.."'")
    end
end
function MP:checkScriptSyntax(cmd,arg,errMsg)
    if cmd=='setField' then
        -- TODO
    elseif cmd=='switchAction' then
        assert(self._actions[arg],"Invalid action name '"..arg.."'")
    elseif cmd=='clearHold' then
        assert(arg==nil,errMsg.."No arg needed")
    elseif cmd=='clearNext' then
        assert(arg==nil,errMsg.."No arg needed")
    elseif cmd=='pushNext' then
        if type(arg)=='string' then
            -- TODO
        elseif type(arg)=='table' then
            for i=1,#arg do
                assert(Mino.get(arg[i]),errMsg.."Invalid mino id '"..arg[i].."'")
            end
        end
    end
end
--------------------------------------------------------------
-- Builder
---@class Techmino.Mode.Setting.Mino
local baseEnv={
    -- Size
    fieldW=10, -- [WARNING] This is not the real field width, just for generate field object. Change real field size with 'self:changeFieldWidth'
    spawnH=20,
    extraSpawnH=1,
    lockoutH=1e99,
    deathH=1e99,
    voidH=1260,

    -- Clear
    clearRule='line',
    clearMovement='lineBack',

    -- Sequence
    seqType='bag7',
    nextSlot=6,
    holdSlot=1,
    infHold=false,
    holdMode='hold',
    holdKeepState=false,

    -- Delay
    readyDelay=3000,
    dropDelay=1000,
    lockDelay=1000,
    spawnDelay=0,
    clearDelay=0,
    deathDelay=260,

    -- Fresh
    freshCondition='any',
    maxFreshChance=15,
    maxFreshTime=6200,

    -- Hidden
    pieceVisTime=false,
    pieceFadeTime=1000,

    -- Garbage
    initialRisingSpeed=1,
    risingAcceleration=.001,
    risingDeceleration=.003,
    maxRisingSpeed=1,
    minRisingSpeed=1,

    -- Attack
    rotSys='TRS',
    tuck=false,
    spin_immobile=false,
    spin_corners=false,
    atkSys='none',
    allowCancel=true,
    clearStuck=true,

    -- Control
    asd=122, -- *Auto shift delay
    asp=26, -- *Auto shift period
    ash=26, -- *Auto Shift Halt, discharge asd when piece spawn
    softdropSkipAsd=true, -- *Skip asd when softdrop
    entryChrg='on', -- on/off/full/cancel charge when move before spawn
    wallChrg='on', -- on/off/full/cancel charge when move towards wall
    stopMoveWhenSpawn=false, -- Stop moving when piece spawn
    stopMoveWhenRotate=false, -- Stop moving when rotate
    stopMoveWhenHold=false, -- Stop moving when hold
    dblMoveCover=true, -- Use second dir (Press 2)
    dblMoveChrg='reset', -- reset/keep/raw/full charge (Press 2)
    dblMoveStep=true, -- Move (Press 2)
    dblMoveRelChrg='raw', -- reset/keep/raw/full charge (Release 1)
    dblMoveRelStep=false, -- Move (Release 1)
    dblMoveRelInvChrg='reset', -- reset/keep/raw/full charge (Release 2)
    dblMoveRelInvStep=true, -- Move (Release 2)
    dblMoveRelInvRedir=true, -- Change direction (Release 2)
    initMove='buffer', -- buffer/hold to do initial move
    initRotate='buffer', -- buffer/hold to do initial rotate
    initHold='buffer', -- buffer/hold to do initial hold
    aHdLock=60, -- Auto harddrop lock
    mHdLock=40, -- Manual harddrop lock
    freshLockInASD=true, -- Fresh lockDelay in auto shift delay
    freshLockInASP=true, -- Fresh lockDelay in auto shift period

    -- Other
    IRSpushUp=true, -- Use bottom-align when IRS or suffocate
    strictLockout=false, -- Lockout causes game over
    script=false,
    allowTransform=true,
    skin='mino_plastic',
    particles=true,
    shakeness=.26, -- *
    inputDelay=0,
}
local soundEventMeta={
    __index=defaultSoundFunc,
    __metatable=true,
}
function MP.new()
    local self=setmetatable(require'assets.game.basePlayer'.new(),{__index=MP,__metatable=true})
    self.settings=TABLE.copy(baseEnv)
    self.event={
        -- Press & Release
        beforePress={},
        afterPress={},
        beforeRelease={},
        afterRelease={},

        -- Start & End
        playerInit={},
        gameStart={},
        gameOver={},

        -- Drop
        afterResetPos={},
        afterSpawn={},
        afterDrop={},
        afterLock={},
        afterClear={},
        beforeCancel={},
        beforeSend={},
        beforeDiscard={},

        -- Update
        always={},

        -- Graphics
        drawBelowField={},
        drawBelowBlock={},
        drawBelowMarks={},
        drawInField={},
        drawOnPlayer={},

        -- Other
        whenSuffocate={},
        changeSpawnPos={},

        -- Special
        extraSolidCheck={}, -- Manually called
    }
    self.soundEvent=setmetatable({},soundEventMeta)

    mechLib.mino.statistics.event_playerInit[2](self)

    return self
end
function MP:initialize()
    require'assets.game.basePlayer'.initialize(self)

    self.field=require'assets.game.rectField'.new(self.settings.fieldW)
    self.fieldDived=0
    self.fieldRisingSpeed=0

    self.pieceCount=0
    self.combo=0

    self.atkSysData={}
    mechLib.mino.attackSys[self.settings.atkSys].init(self)
    self.garbageBuffer={}
    self.garbageSum=0

    self.totalCellCount=0
    self.nextQueue={}
    self.seqData={}
    self.seqGen=mechLib.mino.sequence[self.settings.seqType] or self.settings.seqType
    self:seqGen(self.seqData,true)
    self:freshNextQueue()

    self.holdQueue={}
    self.holdTime=0
    self.floatHolds={}

    self.dropTimer=0
    self.lockTimer=0
    self.spawnTimer=self.settings.readyDelay
    self.deathTimer=false
    self.ghostState=false

    self.freshChance=self.settings.maxFreshChance
    self.freshTime=0

    self.hand=false -- Controlling mino object
    self.handX=false
    self.handY=false
    self.lastMovement=false -- Table contain last movement info of mino, for spin/tuck/... checking
    self.ghostY=false
    self.minY=false

    self.moveDir=false
    self.moveCharge=0
    self.downCharge=false

    self.aHdLockTimer=0
    self.mHdLockTimer=0

    self.keyBuffer={
        move=false,
        rotate=false,
        hold=false,
        hardDrop=false,
    }
    self.dropHistory={
        --[[
            int id,
            int x,y,direction,
            int time,
        ]]
    }
    self.clearHistory={
        --[[
            int combo,
            int line,
            int[] lines,
            int time,
        ]]
    }

    self:loadScript(self.settings.script)
end
function MP:unserialize_custom()
    -- Recover field object
    local f=self.field
    self.field=require'assets.game.rectField'.new(self.settings.fieldW)
    self.field._width=f._width
    self.field._matrix=f._matrix

    self.soundEvent=setmetatable({},soundEventMeta)
end
--------------------------------------------------------------

return MP
