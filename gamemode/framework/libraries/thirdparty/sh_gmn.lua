GMN = GMN or {}

local SysTime = SysTime

function GMN.RunTest( func, count )
    count = count or 1000000

    local startTime = SysTime()

    for _ = 1, count do
        func()
    end

    local endTime = SysTime()
    local totalTime = endTime - startTime

    local averageTime = totalTime / count
    return totalTime, averageTime
end

function GMN.TestCompare( func1, func2, count )
    count = count or 1000000

    local jitstatus = jit.status()

    print( "[GMN] Starting test.." )

    jit.on()
    jit.flush()
    collectgarbage()
    local totalTime1, averageTime1 = GMN.RunTest( func1, count )

    jit.on()
    jit.flush()
    collectgarbage()
    local totalTime2, averageTime2 = GMN.RunTest( func2, count )

    jit.off()
    jit.flush()
    collectgarbage()
    local totalTime3, averageTime3 = GMN.RunTest( func1, count )

    jit.off()
    jit.flush()
    collectgarbage()
    local totalTime4, averageTime4 = GMN.RunTest( func2, count )

    if jitstatus then
        jit.on()
    else
        jit.off()
    end

    print( "1 JIT ON took " .. totalTime1 .. " seconds to run " .. count .. " times, average: " .. averageTime1 .. " seconds" )
    print( "2 JIT ON took " .. totalTime2 .. " seconds to run " .. count .. " times, average: " .. averageTime2 .. " seconds" )
    print( "1 JIT OFF took " .. totalTime3 .. " seconds to run " .. count .. " times, average: " .. averageTime3 .. " seconds" )
    print( "2 JIT OFF took " .. totalTime4 .. " seconds to run " .. count .. " times, average: " .. averageTime4 .. " seconds" )

    if averageTime1 > averageTime2 then
        print( "JIT ON 2 is " .. math.Round( ( averageTime1 / averageTime2 ) * 100 - 100, 3 ) .. "% faster than test 1" )
    else
        print( "JIT ON 1 is " .. math.Round( ( averageTime2 / averageTime1 ) * 100 - 100, 3 ) .. "% faster than test 2" )
    end

    if averageTime3 > averageTime4 then
        print( "JIT OFF 2 is " .. math.Round( ( averageTime3 / averageTime4 ) * 100 - 100, 3 ) .. "% faster than test 1" )
    else
        print( "JIT OFF 1 is " .. math.Round( ( averageTime4 / averageTime3 ) * 100 - 100, 3 ) .. "% faster than test 2" )
    end
end