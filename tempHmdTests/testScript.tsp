-- Trigger for XL3
function wait(seconds)
    local start = os.time()
    repeat
    until os.time() > start + seconds
end

--Reset the instrument to the default settings.
reset()

display.changescreen(display.SCREEN_HOME)
waitcomplete()

--Empty the buffer and set it to the capacity calculated by totalRdgs.
defbuffer1.clear()
defbuffer1.capacity = 6000000
refdefbuffer1 = defbuffer1

-- Set up the channels to measure temperature using type K thermocouples using internal reference junction.
channel.setdmm("6:7", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
channel.setdmm("6:7", dmm.ATTR_MEAS_UNIT, dmm.UNIT_CELSIUS)
channel.setdmm("6:7", dmm.ATTR_MEAS_NPLC, 1)
channel.setdmm("6:7", dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_5_5)
channel.setdmm("6:7", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE)
channel.setdmm("6:7", dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K)

channel.setdmm("1:2,5", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)

channel.setlabel("1", "XL3_1_V")
channel.setlabel("2", "XL3_2_V")
channel.setlabel("5", "Ref_Chnl")
channel.setlabel("6", "XL3_1_T")
channel.setlabel("7", "XL3_2_T")

-- Set up the scan; channel 2 is first available channel on a 2001-TCSCAN card.
scan.create("1:2,5:7")
scan.scancount = 0 -- infinite reading
-- Set the amount of time for each scan. ~2mins
scan.scaninterval = 20 -- 120.0

-- Write the data to a USB flash drive at the end of the scan.
scan.export("/usb1/TestLogs_2", scan.WRITE_AFTER_SCAN, buffer.COL_ALL)

-- Set digio line 1 to output an indefinite external trigger.
digio.line[1].mode = digio.MODE_TRIGGER_OPEN_DRAIN
trigger.digout[1].logic = trigger.LOGIC_POSITIVE
trigger.digout[1].pulsewidth = 0
trigger.model.initiate()

wait(3)

OnOff = true
loopStartTime = refdefbuffer1.seconds[refdefbuffer1.startindex]
print("Start Time : ", loopStartTime)

local refTemp = {
    firstThrsh = -10,
    secThrsh = 5,
    thirdThrsh = 25, --40,
    fourthThrsh = 50
}

local testStage = {
    first = 1,
    second = 2,
    third = 3,
    fourth = 4
}
currentStage = testStage.first

local loopTime = 30 --300 -- 5mins
local lastIndex = refdefbuffer1.n
local tempRefChnl = "7"
local voltRefChnl = "5"
local voltRefVal = 5
local lowerCapVolt = 0.019
local currentChnl = 0

while (true) do
    if
        (refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n] > refTemp.firstThrsh and
            trigger.digout[1].logic ~= trigger.LOGIC_NEGATIVE and
            currentStage == testStage.first and
            refdefbuffer1.channels[refdefbuffer1.n] == tempRefChnl)
     then
        currentChnl = refdefbuffer1.channels[refdefbuffer1.n]
        print("currentChnl", refdefbuffer1.channels[refdefbuffer1.n])
        print(
            "\n ***********First TempLimitExceeded : Last Reading :",
            refdefbuffer1.n,
            refdefbuffer1.readings[refdefbuffer1.n]
        )
        trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
        loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
        print("\n*** Next Start Time : ", loopStartTime)
        print("Stage : Channel ", currentStage, refdefbuffer1.channels[refdefbuffer1.endindex])
        currentStage = testStage.second
        currentChnl = 0
    elseif
        refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n] > refTemp.secThrsh and
            trigger.digout[1].logic ~= trigger.LOGIC_NEGATIVE and
            currentStage == testStage.second and
            refdefbuffer1.channels[refdefbuffer1.n] == tempRefChnl
     then
        currentChnl = refdefbuffer1.channels[refdefbuffer1.n]
        print("currentChnl", refdefbuffer1.channels[refdefbuffer1.n])
        print(
            "\n ***********Sec TempLimitExceeded : Last Reading :",
            refdefbuffer1.n,
            refdefbuffer1.readings[refdefbuffer1.n]
        )
        trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
        loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
        print("\n*** Next Start Time : ", loopStartTime)
        print("Stage : Channel ", currentStage, refdefbuffer1.channels[refdefbuffer1.endindex])
        currentStage = testStage.third
    elseif
        refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n] > refTemp.thirdThrsh and
            trigger.digout[1].logic ~= trigger.LOGIC_NEGATIVE and
            currentStage == testStage.third and
            refdefbuffer1.channels[refdefbuffer1.n] == tempRefChnl
     then
        currentChnl = refdefbuffer1.channels[refdefbuffer1.n]
        print("currentChnl", refdefbuffer1.channels[refdefbuffer1.n])
        print(
            "\n ***********Third TempLimitExceeded : Last Reading :",
            refdefbuffer1.n,
            refdefbuffer1.readings[refdefbuffer1.n]
        )
        trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
        loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
        print("\n*** Next Start Time : ", loopStartTime)
        print("Stage : Channel ", currentStage, refdefbuffer1.channels[refdefbuffer1.endindex])
        currentStage = testStage.fourth
    elseif
        refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n] > refTemp.fourthThrsh and
            trigger.digout[1].logic ~= trigger.LOGIC_NEGATIVE and
            currentStage == testStage.fourth and
            refdefbuffer1.channels[refdefbuffer1.n] == tempRefChnl
     then
        currentChnl = refdefbuffer1.channels[refdefbuffer1.n]
        print("currentChnl", refdefbuffer1.channels[refdefbuffer1.n])
        print(
            "\n ***********Fourth TempLimitExceeded : Last Reading :",
            refdefbuffer1.n,
            refdefbuffer1.readings[refdefbuffer1.n]
        )
        trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
        loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
        print("\n*** Next Start Time : ", loopStartTime)
        print("Stage : Channel ", currentStage, refdefbuffer1.channels[refdefbuffer1.endindex])
        currentStage = testStage.first
    end

    if
        refdefbuffer1.n ~= 0 and refdefbuffer1.seconds[refdefbuffer1.endindex] > (loopStartTime + loopTime) and
            trigger.digout[1].logic ~= trigger.LOGIC_POSITIVE
     then
        trigger.digout[1].logic = trigger.LOGIC_POSITIVE -- Turn OFF after loopTime secs
        loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
        print("\n*** Updated Start Time : ", loopStartTime)
        print("\nLoop Completed Turn Off Xl3 :", refdefbuffer1.seconds[refdefbuffer1.n])
    end

    if refdefbuffer1.seconds[refdefbuffer1.n] > (loopStartTime + 25) and (refdefbuffer1.n - lastIndex) > 0 then
        lastIndex = refdefbuffer1.n
        print("Index : ", refdefbuffer1.n)
        print("Channel : Readings", refdefbuffer1.channels[refdefbuffer1.n], refdefbuffer1.readings[refdefbuffer1.n])
    else
        print(
            "\n**Current Time : Reading :**\n",
            refdefbuffer1.times[refdefbuffer1.n],
            refdefbuffer1.formattedreadings[refdefbuffer1.n]
        )
    end
    if
        refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n] > voltRefVal and
            refdefbuffer1.channels[refdefbuffer1.n] == voltRefChnl
     then
        if refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n - 1] < lowerCapVolt then
            print(
                "<?>Channel  : Readings",
                refdefbuffer1.channels[refdefbuffer1.n - 1],
                refdefbuffer1.readings[refdefbuffer1.n - 1]
            )
        end
        if refdefbuffer1.n ~= 0 and refdefbuffer1.readings[refdefbuffer1.n - 2] < lowerCapVolt then
            print(
                "<?>Channel : Readings",
                refdefbuffer1.channels[refdefbuffer1.n - 2],
                refdefbuffer1.readings[refdefbuffer1.n - 2]
            )
        end
    end
end
