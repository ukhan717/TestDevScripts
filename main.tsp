-- Trigger for XL3
function wait(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

--Reset the instrument to the default settings.
reset()

--Establish variables to make a measurement every 60 seconds 1440 times (24 hours).
local scanCnt = 24 * 60 --1440 minutes = 24 hours
local chanCnt = 9
local totalRdgs = scanCnt * chanCnt

--display.changescreen(display.SCREEN_HOME)
--waitcomplete()

--Empty the buffer and set it to the capacity calculated by totalRdgs.
defbuffer1.clear()
--defbuffer1.capacity = totalRdgs
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

channel.setlabel("1","XL3_1_V")
channel.setlabel("2","XL3_2_V")
channel.setlabel("5","Ref_Chnl")
channel.setlabel("6","XL3_1_T")
channel.setlabel("7","XL3_2_T")

-- Set up the scan; channel 2 is first available channel on a 2001-TCSCAN card.
scan.create("1:2,5:7")
--scan.create("6,7")
--scan.addsinglestep("1,2,5")
scan.scancount = 0  -- infinite reading
-- Set the amount of time for each scan.
scan.scaninterval = 4.0
-- Write the data to a USB flash drive at the end of the scan.
--print(buffer)
scan.export("/usb1/TestLogs_10", scan.WRITE_AFTER_SCAN, buffer.COL_ALL)

-- Set digio line 1 to output an indefinite external trigger.
digio.line[1].mode= digio.MODE_TRIGGER_OPEN_DRAIN
trigger.digout[1].logic = trigger.LOGIC_POSITIVE
trigger.digout[1].pulsewidth = 0
trigger.model.initiate()

--for x=1,defbuffer1.n do
	--printbuffer(defbuffer1[x], defbuffer1.relativetimestamps[x])
--end

while(true)
do
	trigger.digout[1].assert()
	refdefbuffer1 = refdefbuffer1
	--for x=1,refdefbuffer1.n do
		--if refdefbuffer1.formattedreadings[x] == 
		--if refdefbuffer1.refdefbuffer1[x] > 0.3 && refdefbuffer1.refdefbuffer1[x] > 0.3 then
			--refdefbuffer1.relativetimestamps[x] = 7
		--end
		--print(refdefbuffer1.readings[x],refdefbuffer1.formattedreadings[x],refdefbuffer1.units[x])
	--end
	print(refdefbuffer1.readings[refdefbuffer1.n-1],refdefbuffer1.formattedreadings[refdefbuffer1.n-1],refdefbuffer1.units[refdefbuffer1.n-1])
	if refdefbuffer1.readings[refdefbuffer1.n-1] > 20 && refdefbuffer1.units[refdefbuffer1.n-1] == "Celsius" then
		trigger.digout[1].release()
		print("TempLimitExceeded")
	--wait(5)
	-- Release digio line 1.
	--trigger.digout[1].release()
	--wait(5)
	--print("\n ScanState : ScanCount : StepCount :",scanState, scanCount, stepCount)
	print("\nStep Count" , scan.stepcount) 
	print("\nTriggering XL3\r\n")
	print(buffer.COL_STANDARD)




	-- Get the data.-- Get the data.
	--dmm.measure.read(testData)-- Get the data.
	--print(testData.channels[1])
	--print("\ndefbufferChannel1 :",buffer.channels[3])
	--if defbuffer1.n > bufferSize then
		--print("\nMax Buffer Size Reached : ", defbuffer1.n)
	--end
end