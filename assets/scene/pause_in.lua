local scene={}

local pauseText

function scene.enter()
    PROGRESS.setInteriorBG()
    pauseText=GC.newText(FONT.get(80,'bold'),Text.pause)
end
function scene.leave()
    SCN.scenes['game_in'].leave()
end

local function sysAction(action)
    if action=='quit' then
        SCN.back('none')
    elseif action=='back' then
        SCN.swapTo('game_in','none')
    elseif action=='restart' then
        SCN.swapTo('game_in','none',GAME.mode.name)
    elseif action=='setting' then
        SCN.go('setting_in','none')
    end
end
function scene.keyDown(key,isRep)
    if isRep then return end
    sysAction(KEYMAP.sys:getAction(key))
end

function scene.touchDown(x,y,id) if SETTINGS.system.touchControl then VCTRL.press(x,y,id) end end
function scene.touchMove(x,y,_,_,id) if SETTINGS.system.touchControl then VCTRL.move(x,y,id) end end
function scene.touchUp(_,_,id) if SETTINGS.system.touchControl then VCTRL.release(id) end end

scene.mouseDown=scene.touchDown
function scene.mouseMove(x,y,dx,dy) scene.touchMove(x,y,dx,dy,1) end
scene.mouseUp=scene.touchUp

function scene.draw()
    GAME.render()

    GC.replaceTransform(SCR.origin)
    GC.setColor(0,0,0,.626)
    GC.rectangle('fill',0,0,SCR.w,SCR.h)

    GC.replaceTransform(SCR.xOy)
    if SETTINGS.system.touchControl then VCTRL.draw() end

    GC.replaceTransform(SCR.xOy_m)
    GC.scale(2)
    GC.setColor(COLOR.L)
    GC.mDraw(pauseText,0,0)
end

scene.widgetList={
    {type='button',pos={0,.5},x=210,y=-360,w=200,h=80,lineWidth=4,cornerR=0,sound_trigger='button_back',fontSize=60,text=CHAR.icon.back,code=WIDGET.c_backScn('none')},
    {type='button',pos={.5,.5},x=300*-1,y=-160,w=260,h=100,lineWidth=4,cornerR=0,fontSize=60,text=CHAR.icon.play,    code=function() sysAction('back') end},
    {type='button',pos={.5,.5},x=300*0,y=-160,w=260,h=100,lineWidth=4,cornerR=0,fontSize=60,text=CHAR.icon.retry,    code=function() sysAction('restart') end},
    {type='button',pos={.5,.5},x=300*1,y=-160,w=260,h=100,lineWidth=4,cornerR=0,fontSize=60,text=CHAR.icon.settings,
        code=function()
            if PROGRESS.get('main')<=2 or isCtrlPressed() then
                sysAction('setting')
            else
                FMOD.effect('move_failed')
                FMOD.effect('suffocate',{tune=MATH.rand(-6,2)})
            end
        end,
    },
}
return scene
