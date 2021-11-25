-- Trigger for XL3
function wait(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

--Reset the instrument to the default settings.
reset()

display.changescreen(display.SCREEN_HOME)
waitcomplete()

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
scan.scancount = 0  -- infinite reading
-- Set the amount of time for each scan.
scan.scaninterval = 7.0

-- Write the data to a USB flash drive at the end of the scan.
scan.export("/usb1/TestLogs_11", scan.WRITE_AFTER_SCAN, buffer.COL_ALL)

-- Set digio line 1 to output an indefinite external trigger.
digio.line[1].mode= digio.MODE_TRIGGER_OPEN_DRAIN
trigger.digout[1].logic = trigger.LOGIC_POSITIVE
trigger.digout[1].pulsewidth = 0
trigger.model.initiate()

wait(3)

OnOff = true
loopStartTime = refdefbuffer1.seconds[refdefbuffer1.startindex]
print("Start Time : ", loopStartTime)
referenceTemp = 24.5
delayCounter = 10000000

while(true)
do
	
	if refdefbuffer1.n != 0 and refdefbuffer1.readings[refdefbuffer1.n] > referenceTemp and trigger.digout[1].logic != trigger.LOGIC_NEGATIVE  then
		print("nTempLimitExceeded : Last Reading :",refdefbuffer1.n, refdefbuffer1.readings[refdefbuffer1.n])
		trigger.digout[1].logic = trigger.LOGIC_NEGATIVE -- Turn ON
		loopStartTime = refdefbuffer1.seconds[refdefbuffer1.n]
		--start = 0
		--while(start < delayCounter)
		--do
			--start = start+1
		--end
	end
	
	if refdefbuffer1.n != 0 and refdefbuffer1.seconds[refdefbuffer1.n] > (loopStartTime + 30) then
		trigger.digout[1].logic = trigger.LOGIC_POSITIVE
		loopStartTime = refdefbuffer1.seconds[refdefbuffer1.n]
		print("\nLoop Completed Turn Off Xl3 :", refdefbuffer1.seconds[refdefbuffer1.n])		
		print("\n*** Updated Start Time : ", loopStartTime)
	end
	
	print("\nCurrent Time :" , refdefbuffer1.seconds[refdefbuffer1.n])
	print("\nCurrent Temp :" , refdefbuffer1.readings[refdefbuffer1.n])
	--wait(10)
end