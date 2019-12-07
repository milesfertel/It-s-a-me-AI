

MarioLib = {}

-- Max Distances
distances = {}
distances["111"] = 3266    -- 1-1
distances["123"] = 3266    -- 1-2
distances["134"] = 2514    -- 1-3
distances["145"] = 2430    -- 1-4
distances["211"] = 3298    -- 2-1
distances["223"] = 3266    -- 2-2
distances["234"] = 3682    -- 2-3
distances["245"] = 2430    -- 2-4
distances["311"] = 3298    -- 3-1
distances["322"] = 3442    -- 3-2
distances["333"] = 2498    -- 3-3
distances["344"] = 2430    -- 3-4
distances["411"] = 3698    -- 4-1
distances["423"] = 3266    -- 4-2
distances["434"] = 2434    -- 4-3
distances["445"] = 2942    -- 4-4
distances["511"] = 3282    -- 5-1
distances["522"] = 3298    -- 5-2
distances["533"] = 2514    -- 5-3
distances["544"] = 2429    -- 5-4
distances["611"] = 3106    -- 6-1
distances["622"] = 3554    -- 6-2
distances["633"] = 2754    -- 6-3
distances["644"] = 2429    -- 6-4
distances["711"] = 2962    -- 7-1
distances["723"] = 3266    -- 7-2
distances["734"] = 3682    -- 7-3
distances["745"] = 3453    -- 7-4
distances["811"] = 6114    -- 8-1
distances["822"] = 3554    -- 8-2
distances["833"] = 3554    -- 8-3
distances["844"] = 4989    -- 8-4

MarioLib.distances = distances

-- Relevant Addresses
addrs = {}
addrs.world = 0x075f
addrs.level = 0x075c
addrs.area = 0x0760
addrs.playerState = 0x000e
addrs.yViewport = 0x00b5
addrs.curPage = 0x6d
addrs.xPos = 0x86

MarioLib.addrs = addrs

-- get_world_number - Returns current world number (1 to 8)
function MarioLib:getWorldNumber()
	return memory.readbyte(self.addrs.world) + 1
end

-- get_level_number - Returns current level number (1 to 4)
function MarioLib:getLevelNumber()
	return memory.readbyte(self.addrs.level) + 1
end

-- get_area_number - Returns current area number (1 to 5)
function MarioLib:getAreaNumber()
	return memory.readbyte(self.addrs.area) + 1
end

function MarioLib:getYViewport()
    	return memory.readbyte(self.addrs.yViewport);
end

function MarioLib:getXPos()
	return memory.readbyte(self.addrs.curPage) * 0x100 + memory.readbyte(self.addrs.xPos)
end

function MarioLib:getLevelStr()
	return tostring(self:getWorldNumber()) .. tostring(self:getLevelNumber()) .. tostring(self:getAreaNumber())
end

function MarioLib:getMaxDist()
	return self.distances[self:getLevelStr()] or 0
end

function MarioLib:finished()
	local maxDistance = self:getMaxDist()
	local xPos = self:getXPos()
	if ((xPos >= maxDistance - 15) and (xPos <= maxDistance)) then
		return true
	else
		return false
	end
end

function MarioLib:isDead()
    local playerState = memory.readbyte(self.addrs.playerState)
    local yViewport = self:getYViewport()
    if (playerState == 0x06) or (playerState == 0x0b) or (yViewport > 1) then
        return true
    else
        return false
    end
end

return MarioLib
