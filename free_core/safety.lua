-- Shazam Safety Core 2.4
-- Camada central de protecao contra argumentos nil/incompletos que podem
-- chegar ao executor durante troca de target, logout, troca de andar ou
-- desaparecimento de criaturas.
if FREE_SAFETY_BOOTSTRAPPED == true then
    return
end
FREE_SAFETY_BOOTSTRAPPED = true

FREE_IS_VALID_POSITION = function(value)
    return type(value) == "table"
        and type(value.x) == "number"
        and type(value.y) == "number"
        and type(value.z) == "number"
end

FREE_SAFE_POSITION = function(thing)
    if thing == nil then
        return nil
    end

    if FREE_IS_VALID_POSITION(thing) then
        return thing
    end

    if type(thing.getPosition) ~= "function" then
        return nil
    end

    local ok, value = pcall(function()
        return thing:getPosition()
    end)

    if ok and FREE_IS_VALID_POSITION(value) then
        return value
    end

    return nil
end

FREE_SAFE_DISTANCE = function(p1, p2)
    if not FREE_IS_VALID_POSITION(p1) or not FREE_IS_VALID_POSITION(p2) then
        return math.huge
    end

    if type(getDistanceBetween) ~= "function" then
        return math.huge
    end

    local ok, value = pcall(getDistanceBetween, p1, p2)
    if ok and type(value) == "number" then
        return value
    end

    return math.huge
end

FREE_SAFE_FIND_PATH = function(p1, p2, maxDist, flags)
    if not FREE_IS_VALID_POSITION(p1) or not FREE_IS_VALID_POSITION(p2) then
        return nil
    end

    if type(findPath) ~= "function" then
        return nil
    end

    local ok, path = pcall(findPath, p1, p2, maxDist, flags)
    if ok and type(path) == "table" then
        return path
    end

    return nil
end

-- Protege a funcao global que o executor do OTCv8 chama diretamente.
do
    if type(getDistanceBetween) == "function" and not FREE_SAFE_DISTANCE_WRAPPED then
        local original = getDistanceBetween
        getDistanceBetween = function(p1, p2)
            if not FREE_IS_VALID_POSITION(p1) or not FREE_IS_VALID_POSITION(p2) then
                return math.huge
            end

            local ok, value = pcall(original, p1, p2)
            if ok and type(value) == "number" then
                return value
            end

            return math.huge
        end
        FREE_SAFE_DISTANCE_WRAPPED = true
    end
end

-- Protege findPath contra posicoes que somem no mesmo frame.
do
    if type(findPath) == "function" and not FREE_SAFE_FIND_PATH_WRAPPED then
        local original = findPath
        findPath = function(p1, p2, maxDist, flags)
            if not FREE_IS_VALID_POSITION(p1) or not FREE_IS_VALID_POSITION(p2) then
                return nil
            end

            local ok, path = pcall(original, p1, p2, maxDist, flags)
            if ok then
                return path
            end

            return nil
        end
        FREE_SAFE_FIND_PATH_WRAPPED = true
    end
end

FREE_GET_ATTACKING_CREATURE = function()
    local game = g_game
    if game and type(game.getAttackingCreature) == "function" then
        local ok, creature = pcall(game.getAttackingCreature)
        if ok then
            return creature
        end
    end
    return nil
end

FREE_GET_FOLLOWING_CREATURE = function()
    local game = g_game
    if game and type(game.getFollowingCreature) == "function" then
        local ok, creature = pcall(game.getFollowingCreature)
        if ok then
            return creature
        end
    end
    return nil
end

FREE_WARN_ONCE = function(key, message, interval)
    FREE_SAFETY_WARNINGS = FREE_SAFETY_WARNINGS or {}
    local current = now or 0
    local previous = FREE_SAFETY_WARNINGS[key] or 0
    interval = interval or 5000
    if current < previous + interval then
        return
    end
    FREE_SAFETY_WARNINGS[key] = current
    if type(warn) == "function" then
        warn("[Shazam Safety] " .. tostring(message))
    elseif type(print) == "function" then
        print("[Shazam Safety] " .. tostring(message))
    end
end

print("[Shazam Safety] Camada de protecao ativa.")
