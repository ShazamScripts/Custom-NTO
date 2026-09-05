CaveBot.Recorder={}

local _=nil
local __=nil

local function _S(...)
    local t={...}
    for i=1,#t do
        t[i]=string.char(t[i])
    end
    return table.concat(t)
end

local _A=_S(103,111,116,111)
local _B=_S(117,115,101)
local _C=_S(117,115,101,119,105,116,104)
local _D=_S(73,78,73,67,73,79,32,67,65,86,69,66,79,84)

local _I=9

local _G1=g_game
local _M=modules
local _CB=CaveBot
local _MA=math.abs
local _MM=math.max

local function _0()
    local p=_G1.getLocalPlayer()
    if not p then return end

    local q=p:getPosition()
    if not q then return end

    local m=_M and _M.game_minimap
    if not m then return end

    local w=m.minimapWidget
    if not w then return end

    local ok,f=pcall(function()
        return w:getFlag(q)
    end)

    if ok and f then
        return
    end

    local z={
        x=q.x,
        y=q.y,
        z=q.z
    }

    pcall(function()
        w:addFlag(z,_I,_D)
    end)

    pcall(function()
        w:save()
    end)
end

local function _1()

    local function _2(p)
        _CB.addAction(
            _A,
            p.x..","..p.y..","..p.z,
            true
        )

        __=p
    end

    local function _3(p)
        _CB.addAction(
            _A,
            p.x..","..p.y..","..p.z..",0",
            true
        )

        __=p
    end

    onPlayerPositionChange(function(a,b)

        if _CB.isOn() then
            return
        end

        if not _ then
            return
        end

        local x

        if not __ then
            x=1

        elseif a.z~=b.z then
            x=2

        elseif _MA(b.x-a.x)>1 then
            x=2

        elseif _MA(b.y-a.y)>1 then
            x=2

        elseif _MM(
            _MA(__.x-a.x),
            _MA(__.y-a.y)
        )>5 then
            x=3

        else
            x=0
        end

        if x==1 then
            _2(b)

        elseif x==2 then
            _3(b)

        elseif x==3 then
            _2(a)
        end
    end)

    onUse(function(a,b,c,d)

        if _CB.isOn() or not _ then
            return
        end

        if a.x==65535 then
            return
        end

        __=a

        _CB.addAction(
            _B,
            a.x..","..a.y..","..a.z,
            true
        )
    end)

    onUseWith(function(a,b,c,d)

        if _CB.isOn() or not _ then
            return
        end

        if not c:isItem() then
            return
        end

        local e=c:getPosition()

        if e.x==65535 then
            return
        end

        __=a

        local v=
            b..","..
            e.x..","..
            e.y..","..
            e.z

        _CB.addAction(
            _C,
            v,
            true
        )
    end)
end

_CB.Recorder.isOn=function()
    return _
end

_CB.Recorder.enable=function()

    _CB.setOff()

    if _==nil then
        _1()
    end

    local e=_CB.Editor
    local u=e and e.ui

    if u and u.autoRecording then
        u.autoRecording:setOn(true)
    end

    _=true
    __=nil

    _0()
end

_CB.Recorder.disable=function()

    if _==true then
        _=false
    end

    local e=_CB.Editor
    local u=e and e.ui

    if u and u.autoRecording then
        u.autoRecording:setOn(false)
    end

    _CB.save()
end