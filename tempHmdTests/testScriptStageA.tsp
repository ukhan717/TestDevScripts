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
scan.scaninterval = 60.0

-- Write the data to a USB flash drive at the end of the scan.
scan.export("/usb1/TestLogs_StageA_1", scan.WRITE_AFTER_SCAN, buffer.COL_ALL)

-- Set digio line 1 to output an indefinite external trigger.
digio.line[1].mode = digio.MODE_TRIGGER_OPEN_DRAIN
trigger.digout[1].logic = trigger.LOGIC_POSITIVE
trigger.digout[1].pulsewidth = 0
trigger.model.initiate()

wait(3)

OnOff = true
--loopStartTime = refdefbuffer1.seconds[refdefbuffer1.startindex]
--print("Start Time : ", loopStartTime)

local lastIndex = refdefbuffer1.n
local onLoopTime = 180 -- 3mins
local offLoopTime = 420 -- 7mins
local loopEndTime = 0
local loopStartTime = 0

while (true) do
    if (refdefbuffer1.n ~= 0 and trigger.digout[1].logic ~= trigger.LOGIC_NEGATIVE) then
        if loopEndTime == 0 then
            print(
                "\n *********** First Turn On XL3 : Reading :",
                refdefbuffer1.n,
                refdefbuffer1.readings[refdefbuffer1.n]
            )
            trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
            loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
            print("\n*** First Start Time : ", loopStartTime)
            print("First Stage : Channel ", currentStage, refdefbuffer1.channels[refdefbuffer1.endindex])
            loopEndTime = 1
        elseif refdefbuffer1.seconds[refdefbuffer1.endindex] > (loopEndTime + offLoopTime) then
            print(
                "\n *********** Consecutive Turn On XL3 : Reading :",
                refdefbuffer1.n,
                refdefbuffer1.readings[refdefbuffer1.n]
            )
            trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
            loopStartTime = refdefbuffer1.seconds[refdefbuffer1.endindex]
            print("\n*** Consecutive Loop Start Time : ", loopStartTime)
            print("Consecutive Stage : Channel ", currentStage, refdefbuffer1.channels[refdefbuffer1.endindex])
        end
    end

    if
        refdefbuffer1.n ~= 0 and refdefbuffer1.seconds[refdefbuffer1.endindex] > (loopStartTime + onLoopTime) and
            trigger.digout[1].logic ~= trigger.LOGIC_POSITIVE
     then
        trigger.digout[1].logic = trigger.LOGIC_POSITIVE -- Turn OFF after onLoopTime secs
        loopEndTime = refdefbuffer1.seconds[refdefbuffer1.endindex] -- Take loopEndTime
        print("\n*** Loop End Time : ", loopStartTime)
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
end
