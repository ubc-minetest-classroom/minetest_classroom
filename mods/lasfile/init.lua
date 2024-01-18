local modname = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(modname)
local LIB_PATH = MOD_PATH .. "/lasdata/"
dofile(MOD_PATH .. "/struct.lua")

lasfile = {}
lasfile.meta = minetest.get_mod_storage()
lasfile.generating_lasdb = {}

local function getBit(byte, index)
    return math.floor(byte / (2 ^ index)) % 2
end

local function leftShift(value, numBits)
    return value * (2 ^ numBits)
end

local function bitwiseOR(a, b)
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        local bitA = a % 2
        local bitB = b % 2
        if bitA == 1 or bitB == 1 then
            result = result + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end

function lasfile.read_header(filename)
    local file = assert(io.open(LIB_PATH .. filename, "rb"))

    -- Read the file size
    local file_size = file:seek("end")

    -- Ensure the file is at least 227 bytes (minimum size of LAS header in version 1.0)
    if file_size < 227 then
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: File is too small to contain a valid LAS header.")
        file:close()
        return
    end

    -- Reset file position to the beginning
    file:seek("set", 0)

    -- Read the first 26 bytes of the LAS header information up to the version number with little-endian byte order (we do not know how long the header is yet)
    local header_format = "< c4 H H I H H L B B"
    local header_raw = file:read(26)
    local header = {struct.unpack(header_format, header_raw, 1)}
    
    -- LAS file version 1.0 is not currently supported
    if header[8] == 1 and header[9] == 0 then
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: File is too small to contain a valid LAS header.")
        file:close()
        return
    end
    
    -- LAS file version 1.1 or 1.2 (header is 227 bytes)
    if header[8] == 1 and (header[9] == 1 or header[9] == 2) then
        file:seek("set", 0)
        header_format = "< c4 H H I H H L B B c32 c32 H H H I I B H I I I I I I d d d d d d d d d d d d"
        header_raw = file:read(227)
        file:close()
        header = {struct.unpack(header_format, header_raw, 1)}
    end

    -- LAS file version 1.3 (header is 235 bytes)
    if header[8] == 1 and header[9] == 3 then
        file:seek("set", 0)
        header_format = "< c4 H H I H H L B B c32 c32 H H H I I B H I I I I I I d d d d d d d d d d d d"
        header_raw = file:read(235)
        file:close()
        header = {struct.unpack(header_format, header_raw, 1)}
    end

    -- LAS file version 1.4 (header is 375 bytes)
    if header[8] == 1 and header[9] == 4 then
        file:seek("set", 0)
        header_format = "< c4 H H I H H L B B c32 c32 H H H I I B H I I I I I I d d d d d d d d d d d d L L I L L L L L L L L L L L L L L L L"
        header_raw = file:read(375)
        file:close()
        header = {struct.unpack(header_format, header_raw, 1)}
    end

    -- Store header information
    local lasheader = {}

    -- Below fields are common to all las file versions
    lasheader.FileSignature = header[1]
    lasheader.FileSourceID = header[2]
    lasheader.GlobalEncoding = header[3]
    lasheader.ProjectIDGUIDData1 = header[4]
    lasheader.ProjectIDGUIDData2 = header[5]
    lasheader.ProjectIDGUIDData3 = header[6]
    lasheader.ProjectIDGUIDData4 = header[7]
    lasheader.VersionMajor = header[8]
    lasheader.VersionMinor = header[9]
    lasheader.SystemIdentifier = header[10]
    lasheader.GeneratingSoftware = header[11]
    lasheader.FileCreationDayofYear = header[12]
    lasheader.FileCreationYear = header[13]
    lasheader.HeaderSize = header[14]
    lasheader.OffsettoPointData = header[15]
    lasheader.NumberofVariableLengthRecords = header[16]
    lasheader.PointDataRecordFormat = header[17]
    lasheader.PointDataRecordLength = header[18]
    lasheader.LegacyNumberofPointRecords = header[19]
    lasheader.LegacyNumberofPointReturn1 = header[20]
    lasheader.LegacyNumberofPointReturn2 = header[21]
    lasheader.LegacyNumberofPointReturn3 = header[22]
    lasheader.LegacyNumberofPointReturn4 = header[23]
    lasheader.LegacyNumberofPointReturn5 = header[24]
    lasheader.XScaleFactor = header[25]
    lasheader.YScaleFactor = header[26]
    lasheader.ZScaleFactor = header[27]
    lasheader.XOffset = header[28]
    lasheader.YOffset = header[29]
    lasheader.ZOffset = header[30]
    lasheader.MaxX = header[31]
    lasheader.MinX = header[32]
    lasheader.MaxY = header[33]
    lasheader.MinY = header[34]
    lasheader.MaxZ = header[35]
    lasheader.MinZ = header[36]

    -- Field below was introduced in las file version 1.3
    if header[8] == "1" and header[9] == "3" then
        lasheader.StartofWaveformDataPacketRecord = header[37]
    end

    -- Fields below were introduced in las file version 1.4
    if header[8] == "1" and header[9] == "4" then
        lasheader.StartofFirstExtendedVariableLengthRecord = header[38]
        lasheader.NumberofExtendedVariableLengthRecords = header[39]
        lasheader.NumberofPointRecords = header[40]
        lasheader.NumberofPointsReturn1 = header[41]
        lasheader.NumberofPointsReturn2 = header[42]
        lasheader.NumberofPointsReturn3 = header[43]
        lasheader.NumberofPointsReturn4 = header[44]
        lasheader.NumberofPointsReturn5 = header[45]
        lasheader.NumberofPointsReturn6 = header[46]
        lasheader.NumberofPointsReturn7 = header[47]
        lasheader.NumberofPointsReturn8 = header[48]
        lasheader.NumberofPointsReturn9 = header[49]
        lasheader.NumberofPointsReturn10 = header[50]
        lasheader.NumberofPointsReturn11 = header[51]
        lasheader.NumberofPointsReturn12 = header[52]
        lasheader.NumberofPointsReturn13 = header[53]
        lasheader.NumberofPointsReturn14 = header[54]
        lasheader.NumberofPointsReturn15 = header[55]
    end

    return lasheader
end

function lasfile.read_points(filename, attributes, extent)
    -- Sanitize input attributes
    if attributes then
        attributes.Intensity = attributes.Intensity or nil
        attributes.ReturnNumber = attributes.ReturnNumber or nil
        attributes.NumberOfReturns = attributes.NumberOfReturns or nil
        attributes.ClassificationFlagSynthetic = attributes.ClassificationFlagSynthetic or nil
        attributes.ClassificationFlagKeyPoint = attributes.ClassificationFlagKeyPoint or nil
        attributes.ClassificationFlagWithheld = attributes.ClassificationFlagWithheld or nil
        attributes.ClassificationFlagOverlap = attributes.ClassificationFlagOverlap or nil
        attributes.ScannerChannel = attributes.ScannerChannel or nil
        attributes.ScanDirectionFlag = attributes.ScanDirectionFlag or nil
        attributes.EdgeOfFlightLine = attributes.EdgeOfFlightLine or nil
        attributes.Classification = attributes.Classification or nil
        attributes.UserData = attributes.UserData or nil
        attributes.ScanAngle = attributes.ScanAngle or nil
        attributes.PointSourceID = attributes.PointSourceID or nil
        attributes.GPSTime = attributes.PointSourceID or nil
        attributes.Red = attributes.Red or nil
        attributes.Green = attributes.Green or nil
        attributes.Blue = attributes.Blue or nil
        attributes.NIR = attributes.NIR or nil
        attributes.WavePacketDescriptorIndex = attributes.WavePacketDescriptorIndex or nil
        attributes.ByteOffsettoWaveformData = attributes.ByteOffsettoWaveformData or nil
        attributes.WaveformPacketSizeinBytes = attributes.WaveformPacketSizeinBytes or nil
        attributes.ReturnPointWaveformLocation = attributes.ReturnPointWaveformLocation or nil
        attributes.Xt = attributes.Xt or nil
        attributes.Yt = attributes.Yt or nil
        attributes.Zt = attributes.Zt or nil
    end

    if attributes["RGB"] then
        attributes.Red = true
        attributes.Green = true
        attributes.Blue = true
    end

    -- Sanitize input processing extent
    if extent then
        extent.xmin = tonumber(extent.xmin) or nil
        extent.xmax = tonumber(extent.xmax) or nil
        extent.ymin = tonumber(extent.ymin) or nil
        extent.ymax = tonumber(extent.ymax) or nil
    end

    local file = assert(io.open(LIB_PATH .. filename, "rb"))
    local lasheader = lasfile.read_header(filename)
    local xmin = lasheader.MinX
    local xmax = lasheader.MaxX
    local ymin = lasheader.MinY
    local ymax = lasheader.MaxY

    -- Check that we have valid processing extent values
    if (extent.xmin == nil and extent.xmax == nil and extent.ymin == nil and extent.ymax == nil) or (extent.xmin and extent.xmax and extent.ymin and extent.ymax) then
        -- Check that the processing extent values are specified correctly
        if (extent.xmin == nil and extent.xmax == nil and extent.ymin == nil and extent.ymax == nil) or (extent.xmin < extent.xmax and extent.ymin < extent.ymax) then
            -- Check if the processing extent intersects with the LAS file extent
            if (extent.xmin == nil and extent.xmax == nil and extent.ymin == nil and extent.ymax == nil) or ((extent.xmin >= xmin and extent.ymax >= ymin and extent.xmin <= xmax and extent.ymax <= ymax) or (extent.xmax >= xmin and extent.ymax >= ymin and extent.xmax <= xmax and extent.ymax <= ymax) or (extent.xmin >= xmin and extent.ymin <= ymax and extent.xmin <= xmax and extent.ymin >= ymin) or (extent.xmax >= xmin and extent.ymin <= ymax and extent.xmax <= xmax and extent.ymin >= ymin)) then
                -- Seek to the offset of the point data, this skips any variable length records that occur after the header
                file:seek("set", lasheader.OffsettoPointData)
                
                -- Read and parse point data records
                -- We need to first establish both the LAS file version and the Point Data Record Format (which varies by LAS file version) before proceeding to read point records
                local point_format
                
                -- LAS file version 1.1 (point record formats 0 or 1)
                if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 1 then
                    if lasheader.PointDataRecordFormat == 0 then
                        point_format = "< i i i H B B b B H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 1 then
                        point_format = "< i i i H B B B B H d" -- not tested!
                    end
                end
                
                -- LAS file version 1.2 (point record formats 0, 1, 2, or 3)
                if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 2 then
                    if lasheader.PointDataRecordFormat == 0 then
                        point_format = "< i i i H B B b B H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 1 then
                        point_format = "< i i i H B B b B H d" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 2 then
                        point_format = "< i i i H B B b B H H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 3 then
                        point_format = "< i i i H B B b B H d H H H" -- not tested!
                    end
                end                

                -- LAS file version 1.3 (point record formats 0, 1, 2, 3, 4, or 5)
                if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 3 then
                    if lasheader.PointDataRecordFormat == 0 then
                        point_format = "< i i i H B B b B H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 1 then
                        point_format = "< i i i H B B b B H d" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 2 then
                        point_format = "< i i i H B B b B H H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 3 then
                        point_format = "< i i i H B B b B H d H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 4 then
                        point_format = "< i i i H B B b B H d B L I f f f f" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 5 then
                        point_format = "< i i i H B B b B H d H H H B L I f f f f" -- not tested!
                    end
                end

                -- LAS file version 1.4 (point record formats 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, or 10)
                if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 4 then
                    if lasheader.PointDataRecordFormat == 0 then
                        point_format = "< i i i H B B b B H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 1 then
                        point_format = "< i i i H B B b B H d" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 2 then
                        point_format = "< i i i H B B b B H H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 3 then
                        point_format = "< i i i H B B b B H d H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 4 then
                        point_format = "< i i i H B B b B H d B L I f f f f" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 5 then
                        point_format = "< i i i H B B b B H d H H H B L I f f f f" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 6 then
                        point_format = "< i i i H B B B B h H d" -- this has been tested
                    elseif lasheader.PointDataRecordFormat == 7 then
                        point_format = "< i i i H B B B B h H d H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 8 then
                        point_format = "< i i i H B B B B h H d H H H H" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 9 then
                        point_format = "< i i i H B B B B h H d B L I f f f f" -- not tested!
                    elseif lasheader.PointDataRecordFormat == 10 then
                        point_format = "< i i i H B B B B h H d H H H B L I f f f f" -- not tested!
                    end
                end

                local time = os.date("*t")
                if extent.xmin == nil or extent.xmax == nil or extent.ymin == nil or extent.ymax == nil then
                    print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] No processing extent provided, returning all points...")
                else
                    print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Processing extent xmin="..tostring(extent.xmin).." xmax="..tostring(extent.xmax).." ymin="..tostring(extent.ymin).." ymax="..tostring(extent.ymax).." , returning points that intersect the processing extent...")
                end
                local points = {}
                local position = 1
                
                -- We read until the end of the file, without needing to know how many points we will read
                while true do
                    local point_raw = file:read(tonumber(lasheader.PointDataRecordLength)) -- Read one point data record
                    if not point_raw then break end -- If nothing to read, then stop here
                    local point_data = {struct.unpack(point_format, point_raw, 1)}

                    -- Before we bother doing anything with the point, check if it is within the processing extent
                    local xx = tonumber(point_data[1])*tonumber(lasheader.XScaleFactor)+tonumber(lasheader.XOffset)
                    local yy = tonumber(point_data[2])*tonumber(lasheader.YScaleFactor)+tonumber(lasheader.YOffset)
                    if (extent.xmin == nil and extent.xmax == nil and extent.ymin == nil and extent.ymax == nil) or (extent.xmin <= xx and xx <= extent.xmax and extent.ymin <= yy and yy <= extent.ymax) then                       
                        if position % 10000 == 0 then
                            minetest.chat_send_all("DEBUG: Gathering point "..position.." of "..lasheader.LegacyNumberofPointRecords)
                        end
                        local zz = tonumber(point_data[3])*tonumber(lasheader.ZScaleFactor)+tonumber(lasheader.ZOffset)
                        -- TODO: check that all attributes are supported here from all versions
                        local Intensity, ReturnNumber, NumberOfReturns, ClassificationFlagSynthetic, ClassificationFlagKeyPoint, ClassificationFlagWithheld, ClassificationFlagOverlap, ScannerChannel, ScanDirectionFlag, EdgeOfFlightLine, Classification, UserData, ScanAngle, PointSourceID, GPSTime, Red, Green, Blue, NIR, WavePacketDescriptorIndex, ByteOffsettoWaveformData, WaveformPacketSizeinBytes, ReturnPointWaveformLocation, Xt, Yt, Zt = nil


                        -- Intensity position is common amongst all versions
                        if attributes.Intensity then 
                            Intensity = point_data[4]
                        end

                        -- LAS file version 1.1
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 1 then
                        
                            -- These attributes are common to all formats

                            if attributes.ReturnNumber then
                                local return_number_bit_0 = getBit(point_data[5], 0)
                                local return_number_bit_1 = getBit(point_data[5], 1)
                                local return_number_bit_2 = getBit(point_data[5], 2)
                                ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                            end

                            if attributes.NumberOfReturns then
                                local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                            end

                            if attributes.ScanDirectionFlag then 
                                local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                ScanDirectionFlag = scan_direction_flag_bit_6
                            end
            
                            if attributes.EdgeOfFlightLine then 
                                local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                EdgeOfFlightLine = edge_of_flight_line_bit_7
                            end

                            if attributes.Classification then
                                local classification_flags_bit_0 = getBit(point_data[6], 0)
                                local classification_flags_bit_1 = getBit(point_data[6], 1)
                                local classification_flags_bit_2 = getBit(point_data[6], 2)
                                local classification_flags_bit_3 = getBit(point_data[6], 3)
                                local classification_flags_bit_4 = getBit(point_data[6], 4)
                                Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                            end

                            if attributes.ClassificationFlagSynthetic then
                                local classification_flags_bit_5 = getBit(point_data[6], 5)
                                ClassificationFlagSynthetic = classification_flags_bit_5
                            end
            
                            if attributes.ClassificationFlagKeyPoint then
                                local classification_flags_bit_6 = getBit(point_data[6], 6)
                                ClassificationFlagKeyPoint = classification_flags_bit_6
                            end
            
                            if attributes.ClassificationFlagWithheld then
                                local classification_flags_bit_7 = getBit(point_data[6], 7)
                                ClassificationFlagWithheld = classification_flags_bit_7
                            end

                            if attributes.ScanAngle then
                                ScanAngle = tonumber(point_data[7])*0.006
                            end

                            if attributes.UserData then 
                                UserData = point_data[8]
                            end

                            if attributes.PointSourceID then
                                PointSourceID = point_data[9]
                            end

                            -- Attributes below are specific to certain formats

                            if lasheader.PointDataRecordFormat == "1" then
                                if attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end
                            end
                        end

                        -- LAS file version 1.2
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 2 then
                            -- These attributes are common to all formats

                            if attributes.ReturnNumber then
                                local return_number_bit_0 = getBit(point_data[5], 0)
                                local return_number_bit_1 = getBit(point_data[5], 1)
                                local return_number_bit_2 = getBit(point_data[5], 2)
                                ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                            end

                            if attributes.NumberOfReturns then
                                local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                            end

                            if attributes.ScanDirectionFlag then 
                                local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                ScanDirectionFlag = scan_direction_flag_bit_6
                            end
            
                            if attributes.EdgeOfFlightLine then 
                                local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                EdgeOfFlightLine = edge_of_flight_line_bit_7
                            end

                            if attributes.Classification then
                                local classification_flags_bit_0 = getBit(point_data[6], 0)
                                local classification_flags_bit_1 = getBit(point_data[6], 1)
                                local classification_flags_bit_2 = getBit(point_data[6], 2)
                                local classification_flags_bit_3 = getBit(point_data[6], 3)
                                local classification_flags_bit_4 = getBit(point_data[6], 4)
                                Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                            end

                            if attributes.ClassificationFlagSynthetic then
                                local classification_flags_bit_5 = getBit(point_data[6], 5)
                                ClassificationFlagSynthetic = classification_flags_bit_5
                            end
            
                            if attributes.ClassificationFlagKeyPoint then
                                local classification_flags_bit_6 = getBit(point_data[6], 6)
                                ClassificationFlagKeyPoint = classification_flags_bit_6
                            end
            
                            if attributes.ClassificationFlagWithheld then
                                local classification_flags_bit_7 = getBit(point_data[6], 7)
                                ClassificationFlagWithheld = classification_flags_bit_7
                            end

                            if attributes.ScanAngle then
                                ScanAngle = tonumber(point_data[7])*0.006
                            end

                            if attributes.UserData then 
                                UserData = point_data[8]
                            end

                            if attributes.PointSourceID then
                                PointSourceID = point_data[9]
                            end

                            -- Attributes below are specific to certain formats

                            if lasheader.PointDataRecordFormat == 1 then
                                if attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end
                            elseif lasheader.PointDataRecordFormat == 2 then
                                if attributes.Red then
                                    Red = point_data[10]
                                end

                                if attributes.Green then
                                    Green = point_data[11]
                                end

                                if attributes.Blue then
                                    Blue = point_data[12]
                                end
                            elseif lasheader.PointDataRecordFormat == 3  then
                                if attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end

                                if attributes.Red then
                                    Red = point_data[11]
                                end

                                if attributes.Green then
                                    Green = point_data[12]
                                end

                                if attributes.Blue then
                                    Blue = point_data[13]
                                end
                            end

                            points[position] = {
                                X = xx,
                                Y = yy,
                                Z = zz,
                                Intensity = tonumber(Intensity),
                                ReturnNumber = tonumber(ReturnNumber),
                                NumberOfReturns = tonumber(NumberOfReturns),
                                ClassificationFlagSynthetic = tonumber(ClassificationFlagSynthetic),
                                ClassificationFlagKeyPoint = tonumber(ClassificationFlagKeyPoint),
                                ClassificationFlagWithheld = tonumber(ClassificationFlagWithheld),
                                ClassificationFlagOverlap = tonumber(ClassificationFlagOverlap),
                                ScannerChannel = tonumber(ScannerChannel),
                                ScanDirectionFlag = tonumber(ScanDirectionFlag),
                                EdgeOfFlightLine = tonumber(EdgeOfFlightLine),
                                Classification = tonumber(Classification),
                                UserData = tonumber(UserData),
                                ScanAngle = tonumber(ScanAngle),
                                PointSourceID = tonumber(PointSourceID),
                                GPSTime = tonumber(GPSTime),
                                Red = tonumber(Red),
                                Green = tonumber(Green),
                                Blue = tonumber(Blue),
                            }
                        end

                        -- LAS file version 1.3
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 3 then

                            -- These attributes are common to all formats

                            if attributes.ReturnNumber then
                                local return_number_bit_0 = getBit(point_data[5], 0)
                                local return_number_bit_1 = getBit(point_data[5], 1)
                                local return_number_bit_2 = getBit(point_data[5], 2)
                                ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                            end

                            if attributes.NumberOfReturns then
                                local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                            end

                            if attributes.ScanDirectionFlag then 
                                local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                ScanDirectionFlag = scan_direction_flag_bit_6
                            end
            
                            if attributes.EdgeOfFlightLine then 
                                local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                EdgeOfFlightLine = edge_of_flight_line_bit_7
                            end

                            if attributes.Classification then
                                local classification_flags_bit_0 = getBit(point_data[6], 0)
                                local classification_flags_bit_1 = getBit(point_data[6], 1)
                                local classification_flags_bit_2 = getBit(point_data[6], 2)
                                local classification_flags_bit_3 = getBit(point_data[6], 3)
                                local classification_flags_bit_4 = getBit(point_data[6], 4)
                                Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                            end

                            if attributes.ClassificationFlagSynthetic then
                                local classification_flags_bit_5 = getBit(point_data[6], 5)
                                ClassificationFlagSynthetic = classification_flags_bit_5
                            end
            
                            if attributes.ClassificationFlagKeyPoint then
                                local classification_flags_bit_6 = getBit(point_data[6], 6)
                                ClassificationFlagKeyPoint = classification_flags_bit_6
                            end
            
                            if attributes.ClassificationFlagWithheld then
                                local classification_flags_bit_7 = getBit(point_data[6], 7)
                                ClassificationFlagWithheld = classification_flags_bit_7
                            end

                            if attributes.ScanAngle then
                                ScanAngle = tonumber(point_data[7])*0.006
                            end

                            if attributes.UserData then 
                                UserData = point_data[8]
                            end

                            if attributes.PointSourceID then
                                PointSourceID = point_data[9]
                            end

                            -- Attributes below are specific to certain formats

                            if lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 3 then
                                if attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end
                            elseif lasheader.PointDataRecordFormat == 2 then
                                if attributes.Red then
                                    Red = point_data[10]
                                end

                                if attributes.Green then
                                    Green = point_data[11]
                                end

                                if attributes.Blue then
                                    Blue = point_data[12]
                                end
                            elseif lasheader.PointDataRecordFormat == 3 then
                                if attributes.Red then
                                    Red = point_data[11]
                                end

                                if attributes.Green then
                                    Green = point_data[12]
                                end

                                if attributes.Blue then
                                    Blue = point_data[13]
                                end
                            end
                        end

                        -- LAS file version 1.4
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 4 then
                            -- Formats 0-5
                            if lasheader.PointDataRecordFormat == 0 or lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 4 or lasheader.PointDataRecordFormat == 5 then
                                if attributes.ReturnNumber then
                                    local return_number_bit_0 = getBit(point_data[5], 0)
                                    local return_number_bit_1 = getBit(point_data[5], 1)
                                    local return_number_bit_2 = getBit(point_data[5], 2)
                                    ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                                end

                                if attributes.NumberOfReturns then
                                    local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                    local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                    local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                    NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                                end

                                if attributes.ScanDirectionFlag then 
                                    local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                    ScanDirectionFlag = scan_direction_flag_bit_6
                                end
                
                                if attributes.EdgeOfFlightLine then 
                                    local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                    EdgeOfFlightLine = edge_of_flight_line_bit_7
                                end

                                if attributes.Classification then
                                    local classification_flags_bit_0 = getBit(point_data[6], 0)
                                    local classification_flags_bit_1 = getBit(point_data[6], 1)
                                    local classification_flags_bit_2 = getBit(point_data[6], 2)
                                    local classification_flags_bit_3 = getBit(point_data[6], 3)
                                    local classification_flags_bit_4 = getBit(point_data[6], 4)
                                    Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                                end

                                if attributes.ClassificationFlagSynthetic then
                                    local classification_flags_bit_5 = getBit(point_data[6], 5)
                                    ClassificationFlagSynthetic = classification_flags_bit_5
                                end
                
                                if attributes.ClassificationFlagKeyPoint then
                                    local classification_flags_bit_6 = getBit(point_data[6], 6)
                                    ClassificationFlagKeyPoint = classification_flags_bit_6
                                end
                
                                if attributes.ClassificationFlagWithheld then
                                    local classification_flags_bit_7 = getBit(point_data[6], 7)
                                    ClassificationFlagWithheld = classification_flags_bit_7
                                end

                                if attributes.ScanAngle then
                                    ScanAngle = tonumber(point_data[7])*0.006
                                end

                                if attributes.UserData then 
                                    UserData = point_data[8]
                                end

                                if attributes.PointSourceID then
                                    PointSourceID = point_data[9]
                                end

                                -- Attributes below are specific to certain formats
                                
                                if attributes.GPSTime and (lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 4 or lasheader.PointDataRecordFormat == 5) then
                                    GPSTime = point_data[10]
                                end

                                if attributes.Red and (lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 5) then
                                    Red = point_data[11]
                                end

                                if attributes.Green and (lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 5) then
                                    Green = point_data[12]
                                end

                                if attributes.Blue and (lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 5) then
                                    Blue = point_data[13]
                                end

                                if attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[11]
                                elseif attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[14]
                                end

                                if attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[12]
                                elseif attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[15]
                                end

                                if attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[13]
                                elseif attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[16]
                                end

                                if attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[14]
                                elseif attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[17]
                                end

                                if attributes.Xt and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[15]
                                elseif attributes.Xt and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[18]
                                end

                                if attributes.Yt and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[16]
                                elseif attributes.Yt and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[19]
                                end

                                if attributes.Zt and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[17]
                                elseif attributes.Zt and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[20]
                                end

                            -- Formats 6-10
                            elseif lasheader.PointDataRecordFormat == 6 or lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 9 or lasheader.PointDataRecordFormat == 10 then
                                if attributes.ReturnNumber then
                                    local return_number_bit_0 = getBit(point_data[5], 0)
                                    local return_number_bit_1 = getBit(point_data[5], 1)
                                    local return_number_bit_2 = getBit(point_data[5], 2)
                                    local return_number_bit_3 = getBit(point_data[5], 3)
                                    ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_3, 3), leftShift(return_number_bit_2, 2)), bitwiseOR(leftShift(return_number_bit_1, 1), return_number_bit_0))
                                end
                                
                                if attributes.NumberOfReturns then
                                    local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                    local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                    local number_of_returns_bit_6 = getBit(point_data[5], 6)
                                    local number_of_returns_bit_7 = getBit(point_data[5], 7)
                                    NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_7, 3), leftShift(number_of_returns_bit_6, 2)), bitwiseOR(leftShift(number_of_returns_bit_5, 1), number_of_returns_bit_4))
                                end

                                if attributes.ClassificationFlagSynthetic then
                                    local classification_flags_bit_0 = getBit(point_data[6], 0)
                                    ClassificationFlagSynthetic = classification_flags_bit_0
                                end
                
                                if attributes.ClassificationFlagKeyPoint then
                                    local classification_flags_bit_1 = getBit(point_data[6], 1)
                                    ClassificationFlagKeyPoint = classification_flags_bit_1
                                end
                
                                if attributes.ClassificationFlagWithheld then
                                    local classification_flags_bit_2 = getBit(point_data[6], 2)
                                    ClassificationFlagWithheld = classification_flags_bit_2
                                end
                
                                if attributes.ClassificationFlagOverlap then
                                    local classification_flags_bit_3 = getBit(point_data[6], 3)
                                    ClassificationFlagOverlap = classification_flags_bit_3
                                end

                                if attributes.ScannerChannel then 
                                    local scanner_channel_bit_4 = getBit(point_data[6], 4)
                                    local scanner_channel_bit_5 = getBit(point_data[6], 5)
                                    ScannerChannel = bitwiseOR(leftShift(scanner_channel_bit_5, 1), scanner_channel_bit_4)
                                end
                
                                if attributes.ScanDirectionFlag then 
                                    local scan_direction_flag_bit_6 = getBit(point_data[6], 6)
                                    ScanDirectionFlag = scan_direction_flag_bit_6
                                end
                
                                if attributes.EdgeOfFlightLine then 
                                    local edge_of_flight_line_bit_7 = getBit(point_data[6], 7)
                                    EdgeOfFlightLine = edge_of_flight_line_bit_7
                                end

                                if attributes.Classification then 
                                    local classification_bit_0 = getBit(point_data[7], 0)
                                    local classification_bit_1 = getBit(point_data[7], 1)
                                    local classification_bit_2 = getBit(point_data[7], 2)
                                    local classification_bit_3 = getBit(point_data[7], 3)
                                    local classification_bit_4 = getBit(point_data[7], 4)
                                    Classification = bitwiseOR(bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_bit_4, 4), leftShift(classification_bit_3, 3)), leftShift(classification_bit_2, 2)), leftShift(classification_bit_1, 1)), classification_bit_0)
                                end
                
                                if attributes.UserData then 
                                    UserData = point_data[8]
                                end
                
                                if attributes.ScanAngle then
                                    ScanAngle = tonumber(point_data[9])*0.006
                                end
                
                                if attributes.PointSourceID then
                                    PointSourceID = point_data[10]
                                end
                
                                if attributes.GPSTime then
                                    GPSTime = point_data[11]
                                end

                                -- Attributes below are specific to certain formats

                                if attributes.Red and (lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    Red = point_data[12]
                                end

                                if attributes.Green and (lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    Green = point_data[13]
                                end

                                if attributes.Blue and (lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    Blue = point_data[14]
                                end

                                if attributes.NIR and (lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    NIR = point_data[15]
                                end

                                if attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[12]
                                elseif attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[16]
                                end

                                if attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[13]
                                elseif attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[17]
                                end

                                if attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[14]
                                elseif attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[18]
                                end

                                if attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[15]
                                elseif attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[19]
                                end

                                if attributes.Xt and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[16]
                                elseif attributes.Xt and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[20]
                                end

                                if attributes.Yt and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[17]
                                elseif attributes.Yt and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[21]
                                end

                                if attributes.Zt and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[18]
                                elseif attributes.Zt and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[22]
                                end
                            end

                            points[position] = {
                                X = xx,
                                Y = yy,
                                Z = zz,
                                Intensity = tonumber(Intensity),
                                ReturnNumber = tonumber(ReturnNumber),
                                NumberOfReturns = tonumber(NumberOfReturns),
                                ClassificationFlagSynthetic = tonumber(ClassificationFlagSynthetic),
                                ClassificationFlagKeyPoint = tonumber(ClassificationFlagKeyPoint),
                                ClassificationFlagWithheld = tonumber(ClassificationFlagWithheld),
                                ClassificationFlagOverlap = tonumber(ClassificationFlagOverlap),
                                ScannerChannel = tonumber(ScannerChannel),
                                ScanDirectionFlag = tonumber(ScanDirectionFlag),
                                EdgeOfFlightLine = tonumber(EdgeOfFlightLine),
                                Classification = tonumber(Classification),
                                UserData = tonumber(UserData),
                                ScanAngle = tonumber(ScanAngle),
                                PointSourceID = tonumber(PointSourceID),
                                GPSTime = tonumber(GPSTime),
                                Red = tonumber(Red),
                                Green = tonumber(Green),
                                Blue = tonumber(Blue),
                                NIR = tonumber(NIR),
                                WavePacketDescriptorIndex = tonumber(WavePacketDescriptorIndex),
                                ByteOffsettoWaveformData = tonumber(ByteOffsettoWaveformData),
                                WaveformPacketSizeinBytes = tonumber(WaveformPacketSizeinBytes),
                                ReturnPointWaveformLocation = tonumber(ReturnPointWaveformLocation),
                                Xt = tonumber(Xt),
                                Yt = tonumber(Yt),
                                Zt = tonumber(Zt),
                            }
                        end
                        
                        position = position + 1
                    end

                end
                file:close()
                return points, attributes
            else
                local time = os.date("*t")
                print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: LAS file does not intersect with the processing extent.")
                file:close()
                return
            end
        else
            local time = os.date("*t")
            print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: Processing extent was not defined correctly.")
            file:close()
            return
        end
    else
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: Processing extent was not defined correctly or completely.")
        file:close()
        return
    end
end

function lasfile.get_points_by_class(points,classcode)
    local classPoints = {}
    for _, point in ipairs(points) do
        if point.Classification == tonumber(classcode) then
            table.insert(classPoints, point)
        end
    end
    return classPoints
end

function lasfile.get_voxels(points, xmin, ymin, zmin, xmax, ymax, zmax, attributes)

    -- Get the dims
    xmin = tonumber(xmin) or math.huge
    ymin = tonumber(ymin) or math.huge
    zmin = tonumber(zmin) or math.huge
    xmax = tonumber(xmax) or -math.huge
    ymax = tonumber(ymax) or -math.huge
    zmax = tonumber(zmax) or -math.huge

    -- Find the bounding extent of the class points
    for _, point in ipairs(points) do
        xmin = math.min(xmin, point.X)
        ymin = math.min(ymin, point.Y)
        zmin = math.min(zmin, point.Z)
        xmax = math.max(xmax, point.X)
        ymax = math.max(ymax, point.Y)
        zmax = math.max(zmax, point.Z)
    end

    local xdim, ydim, zdim
    xdim = math.ceil(xmax - xmin) + 1
    ydim = math.ceil(ymax - ymin) + 1
    zdim = math.ceil(zmax - zmin) + 1

    -- Initialize the voxels structure to store statistics
    --minetest.chat_send_all("DEBUG: Initializing voxel structure with size {x="..xdim..", y="..ydim..", z="..zdim.."}")
    local voxels = {}
--[[     for x = 1, xdim do
        voxels[x] = {}
        for y = 1, ydim do
            voxels[x][y] = {}
            for z = 1, zdim do
                voxels[x][y][z] = { 
                    class = {}, 
                    intensity = {}, 
                    point_count = 0,
                    return_number = {},
                    red = {},
                    green = {},
                    blue = {}, 
                    nir = {}
                }
            end
        end
    end ]]

    minetest.chat_send_all("DEBUG: Calculating requested statistics on the voxels for:")
    for attribute_name, bool in pairs(attributes) do
        if bool then
            minetest.chat_send_all("           "..attribute_name)
        end
    end
    for _, point in ipairs(points) do
        local x = math.floor(point.X - xmin) + 1
        local y = math.floor(point.Y - ymin) + 1
        local z = math.floor(point.Z - zmin) + 1

        -- We only hold voxels for locations where we have points
        if not voxels[x] then voxels[x] = {} end
        if not voxels[x][y] then voxels[x][y] = {} end
        if not voxels[x][y][z] then 
            voxels[x][y][z] = { 
                class = {}, 
                intensity = {}, 
                point_count = 0,
                return_number = {},
                red = {},
                green = {},
                blue = {}, 
                nir = {}
            }
        end

        -- Classification code statistics
        if attributes["Classification"] then
            local c = point.Classification
            if c then
                voxels[x][y][z].class[c] = (voxels[x][y][z].class[c] or 0) + 1
            end
        end

        -- Intensity statistics
        if attributes["Intensity"] then
            local intensity = point.Intensity
            if intensity then
                table.insert(voxels[x][y][z].intensity, intensity)
            end
        end

        -- Return number statistics
        if attributes["ReturnNumber"] then
            local r = point.ReturnNumber
            if r then
                voxels[x][y][z].return_number[r] = (voxels[x][y][z].return_number[r] or 0) + 1
            end
        end

        -- Count of points in each voxel
        voxels[x][y][z].point_count = voxels[x][y][z].point_count + 1

        -- RGB + NIR values
        if attributes["Red"] then
            local red = point.Red
            if red then
                table.insert(voxels[x][y][z].red, red)
            end
        end
        if attributes["Green"] then
            local green = point.Green
            if green then
                table.insert(voxels[x][y][z].green, green)
            end
        end
        if attributes["Blue"] then
            local blue = point.Blue
            if blue then
                table.insert(voxels[x][y][z].blue, blue)
            end
        end
        if attributes["NIR"] then
            local nir = point.NIR
            if nir then
                table.insert(voxels[x][y][z].nir, nir)
            end
        end
    end

    -- Calculate statistics for all non-empty voxels
    for x = 1, xdim do
        for y = 1, ydim do
            for z = 1, zdim do
                if voxels[x] and voxels[x][y] and voxels[x][y][z] then
                    -- Calculate class statistics
                    if attributes["Classification"] then
                        local class_statistics = {}
                        for class_code, count in pairs(voxels[x][y][z].class) do
                            table.insert(class_statistics, { class = class_code, count = count })
                        end
                    
                        -- Find majority class code
                        local majority_class, majority_count = nil, 0
                        for class_code, count in pairs(voxels[x][y][z].class) do
                            if count > majority_count then
                                majority_class = class_code
                                majority_count = count
                            end
                        end
                        voxels[x][y][z].class_statistics = class_statistics
                        voxels[x][y][z].majority_class = majority_class
                        voxels[x][y][z].majority_count = majority_count
                    end

                    -- Calculate intensity statistics
                    if attributes["Intensity"] then
                        local intensity_values = voxels[x][y][z].intensity
                        local min_intensity, max_intensity, mean_intensity, range_intensity
                        if intensity_values and #intensity_values > 0 then
                            min_intensity = math.min(unpack(intensity_values))
                            max_intensity = math.max(unpack(intensity_values))
                            mean_intensity = 0
                            for _, value in ipairs(intensity_values) do
                                mean_intensity = mean_intensity + value
                            end
                            mean_intensity = mean_intensity / #intensity_values
                            range_intensity = max_intensity - min_intensity
                        end
                        voxels[x][y][z].intensity_statistics = {
                            min = min_intensity,
                            max = max_intensity,
                            mean = mean_intensity,
                            range = range_intensity,
                        }
                    end

                    -- Find majority return number
                    if attributes["ReturnNumber"] then
                        local majority_return, majority_return_count = nil, 0
                        for return_number, count in pairs(voxels[x][y][z].return_number) do
                            if count > majority_return_count then
                                majority_return = return_number
                                majority_return_count = count
                            end
                        end
                        voxels[x][y][z].majority_return = majority_return
                        voxels[x][y][z].majority_return_count = majority_return_count
                    end

                    -- Calculate Red, Green, Blue, NIR statistics
                    if attributes["Red"] then
                        local min_red, max_red, mean_red, range_red
                        local red_values = voxels[x][y][z].red
                        if red_values and #red_values > 0 then
                            min_red = math.min(unpack(red_values))
                            max_red = math.max(unpack(red_values))
                            mean_red = 0
                            for _, value in ipairs(red_values) do
                                mean_red = mean_red + value
                            end
                            mean_red = mean_red / #red_values
                            range_red = max_red - min_red
                        end
                        voxels[x][y][z].red_statistics = {
                            min = min_red,
                            max = max_red,
                            mean = mean_red,
                            range = range_red,
                        }
                    end
                    if attributes["Green"] then
                        local min_green, max_green, mean_green, range_green
                        local green_values = voxels[x][y][z].green
                        if green_values and #green_values > 0 then
                            min_green = math.min(unpack(green_values))
                            max_green = math.max(unpack(green_values))
                            mean_green = 0
                            for _, value in ipairs(green_values) do
                                mean_green = mean_green + value
                            end
                            mean_green = mean_green / #green_values
                            range_green = max_green - min_green
                        end
                        voxels[x][y][z].green_statistics = {
                            min = min_green,
                            max = max_green,
                            mean = mean_green,
                            range = range_green,
                        }
                    end
                    if attributes["Blue"] then
                        local min_blue, max_blue, mean_blue, range_blue
                        local blue_values = voxels[x][y][z].blue
                        if blue_values and #blue_values > 0 then
                            min_blue = math.min(unpack(blue_values))
                            max_blue = math.max(unpack(blue_values))
                            mean_blue = 0
                            for _, value in ipairs(blue_values) do
                                mean_blue = mean_blue + value
                            end
                            mean_blue = mean_blue / #blue_values
                            range_blue = max_blue - min_blue
                        end
                        voxels[x][y][z].blue_statistics = {
                            min = min_blue,
                            max = max_blue,
                            mean = mean_blue,
                            range = range_blue,
                        }
                    end
                    if attributes["NIR"] then
                        local min_nir, max_nir, mean_nir, range_nir
                        local nir_values = voxels[x][y][z].nir_values
                        if nir_values and #nir_values > 0 then
                            min_nir = math.min(unpack(nir_values))
                            max_nir = math.max(unpack(nir_values))
                            mean_nir = 0
                            for _, value in ipairs(nir_values) do
                                mean_nir = mean_nir + value
                            end
                            mean_nir = mean_nir / #nir_values
                            range_nir = max_nir - min_nir
                        end
                        voxels[x][y][z].nir_statistics = {
                            min = min_nir,
                            max = max_nir,
                            mean = mean_nir,
                            range = range_nir,
                        }
                    end
                end
            end
        end
    end

    return voxels, xmin, ymin, zmin, xmax, ymax, zmax
end

function lasfile.file_exists(filename)
    local file = io.open(LIB_PATH..filename, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

function lasfile.create_classroom(filename, realmName, pname, sizeX, sizeY, sizeZ, attribute, palette)
    local newRealm = Realm:New(realmName, { x = sizeX, y = sizeY, z = sizeZ }, false)
    -- Remove the buffer from the EndPos x,z so that the map fits snuggly in the new realm (add 1 for the barrier)
    newRealm.EndPos.x = newRealm.StartPos.x + sizeX + 1
    newRealm.EndPos.y = newRealm.StartPos.y + sizeY + 1
    newRealm.EndPos.z = newRealm.StartPos.z + sizeZ + 1
    newRealm.MetaStorage.emerge = true
    newRealm.MetaStorage.las_filename = filename
    -- Symbology settings are used below only for visualizing LiDAR point clouds
    newRealm.MetaStorage.symbology_attribute = attribute or nil
    newRealm.MetaStorage.symbology_palette = palette or nil
    newRealm:set_data("owner", pname)
    newRealm:CreateBarriersFast()
    newRealm:CallOnCreateCallbacks()
    return newRealm
end

function lasfile.ChunkInRealm(pos1, pos2, pos3, pos4)
    -- Get min/max coordinates for each space
    local minX1, maxX1 = math.min(pos1.x, pos2.x), math.max(pos1.x, pos2.x)
    local minY1, maxY1 = math.min(pos1.y, pos2.y), math.max(pos1.y, pos2.y)
    local minZ1, maxZ1 = math.min(pos1.z, pos2.z), math.max(pos1.z, pos2.z)
    local minX2, maxX2 = math.min(pos3.x, pos4.x), math.max(pos3.x, pos4.x)
    local minY2, maxY2 = math.min(pos3.y, pos4.y), math.max(pos3.y, pos4.y)
    local minZ2, maxZ2 = math.min(pos3.z, pos4.z), math.max(pos3.z, pos4.z)
    
    -- Check for overlap in all three dimensions
    return maxX1 >= minX2 and minX1 <= maxX2
        and maxY1 >= minY2 and minY1 <= maxY2
        and maxZ1 >= minZ2 and minZ1 <= maxZ2
end

function lasfile.generate(minp, maxp, loadRealm, filename)
    if loadRealm then

         -- Check if the chunk intersects the realm
        if maxp.x < loadRealm.StartPos.x and maxp.y < loadRealm.StartPos.y and maxp.z < loadRealm.StartPos.z and minp.x > loadRealm.EndPos.x and minp.y > loadRealm.EndPos.y and minp.z > loadRealm.EndPos.z  then
            -- Chunk is not in the realm, skip
            return 
        end
        
        -- Chunk is in the realm, continue processing
        local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
        local area = VoxelArea:new { MinEdge = emin, MaxEdge = emax }
        local data = vm:get_data()
        local param2 = vm:get_param2_data() 
        local voxels = lasfile.generating_lasdb.voxels[filename]

        for z = minp.z, maxp.z do
            -- Check that the z of the chunk is within the realm
            if z > loadRealm.StartPos.z and z < loadRealm.EndPos.z then  
                for y = minp.y, maxp.y do
                    -- Check that the y of the chunk is within the realm
                    if y > loadRealm.StartPos.y and y < loadRealm.EndPos.y then 
                        for x = minp.x, maxp.x do
                            -- Check that the x of the chunk is within the realm
                            if x > loadRealm.StartPos.x and x < loadRealm.EndPos.x then 
                                local xx = math.floor(x - loadRealm.StartPos.x)
                                local yy = math.floor(y - loadRealm.StartPos.y) -- Note: Minetest Y is LiDAR Z
                                local zz = math.floor(z - loadRealm.StartPos.z) -- Note: Minetest Z is LiDAR Y
                                
                                if loadRealm.MetaStorage.symbology_attribute == "Classification" and voxels[xx][zz][yy] then
                                    local class = voxels[xx][zz][yy].majority_class
                                    if class then
                                        -- Prepare and index the voxel manipulator
                                        local vi = area:index(x, y, z)
                                        if class == 0 then
                                            data[vi] = minetest.get_content_id("default:lava_source")
                                        elseif class == 1 then
                                            data[vi] = minetest.get_content_id("default:bronzeblock")
                                        elseif class == 2 then
                                            data[vi] = minetest.get_content_id("default:dirt")
                                        elseif class == 3 then
                                            data[vi] = minetest.get_content_id("default:fern_3")
                                        elseif class == 4 then
                                            data[vi] = minetest.get_content_id("default:papyrus")
                                        elseif class == 5 then
                                            data[vi] = minetest.get_content_id("default:pine_needles")
                                        elseif class == 6 then
                                            data[vi] = minetest.get_content_id("default:tinblock")
                                        elseif class == 7 then
                                            data[vi] = minetest.get_content_id("default:mese")
                                        elseif class == 9 then
                                            data[vi] = minetest.get_content_id("default:water_source")
                                        end
                                    end
                                elseif loadRealm.MetaStorage.symbology_attribute == "RGB" then
                                    if voxels and voxels[xx] and voxels[xx][zz] and voxels[xx][zz][yy] and voxels[xx][zz][yy].red_statistics and voxels[xx][zz][yy].red_statistics.mean and voxels[xx][zz][yy].green_statistics and voxels[xx][zz][yy].green_statistics.mean and voxels[xx][zz][yy].blue_statistics and voxels[xx][zz][yy].blue_statistics.mean then
                                            local vi = area:index(x, y, z)
                                            -- TODO: allow user input for the logical ranges below
                                            local red = rgb8bit.map_value_to_3_bits(voxels[xx][zz][yy].red_statistics.mean, 0, 255) -- max is usually 255 (short) or 65535 (long)
                                            local green = rgb8bit.map_value_to_3_bits(voxels[xx][zz][yy].green_statistics.mean, 0, 255)
                                            local blue = rgb8bit.map_value_to_2_bits(voxels[xx][zz][yy].blue_statistics.mean, 0, 255)
                                            data[vi] = minetest.get_content_id("rgb8bit:rgb8bit")
                                            param2[vi] = rgb8bit.get_palette_index_from_rgb(red, green, blue)
                                    end
                                elseif loadRealm.MetaStorage.symbology_attribute == "Red" then
                                    if voxels and voxels[xx] and voxels[xx][zz] and voxels[xx][zz][yy] and voxels[xx][zz][yy].red_statistics and voxels[xx][zz][yy].red_statistics.mean then
                                        local vi = area:index(x, y, z)
                                        data[vi] = minetest.get_content_id(loadRealm.MetaStorage.symbology_palette)
                                        -- TODO: allow user input for the logical range below
                                        param2[vi] = lasfile.map_to_8bit(voxels[xx][zz][yy].red_statistics.mean, 0, 65535)
                                    end
                                elseif loadRealm.MetaStorage.symbology_attribute == "Green" then 
                                    if voxels and voxels[xx] and voxels[xx][zz] and voxels[xx][zz][yy] and voxels[xx][zz][yy].green_statistics and voxels[xx][zz][yy].green_statistics.mean then
                                        local vi = area:index(x, y, z)
                                        data[vi] = minetest.get_content_id(loadRealm.MetaStorage.symbology_palette)
                                        -- TODO: allow user input for the logical range below
                                        param2[vi] = lasfile.map_to_8bit(voxels[xx][zz][yy].green_statistics.mean, 0, 65535)
                                    end
                                elseif loadRealm.MetaStorage.symbology_attribute == "Blue" then
                                    if voxels and voxels[xx] and voxels[xx][zz] and voxels[xx][zz][yy] and voxels[xx][zz][yy].blue_statistics and voxels[xx][zz][yy].blue_statistics.mean then
                                        local vi = area:index(x, y, z)
                                        data[vi] = minetest.get_content_id(loadRealm.MetaStorage.symbology_palette)
                                        -- TODO: allow user input for the logical range below
                                        param2[vi] = lasfile.map_to_8bit(voxels[xx][zz][yy].blue_statistics.mean, 0, 65535)
                                    end
                                elseif loadRealm.MetaStorage.symbology_attribute == "NIR" then 
                                    if voxels and voxels[xx] and voxels[xx][zz] and voxels[xx][zz][yy] and voxels[xx][zz][yy].nir_statistics and voxels[xx][zz][yy].nir_statistics.mean then
                                        local vi = area:index(x, y, z)
                                        data[vi] = minetest.get_content_id(loadRealm.MetaStorage.symbology_palette)
                                        -- TODO: allow user input for the logical range below
                                        param2[vi] = lasfile.map_to_8bit(voxels[xx][zz][yy].nir_statistics.mean, 0, 65535)
                                    end
                                elseif loadRealm.MetaStorage.symbology_attribute == "Intensity" then
                                    if voxels and voxels[xx] and voxels[xx][zz] and voxels[xx][zz][yy] and voxels[xx][zz][yy].intensity_statistics and voxels[xx][zz][yy].intensity_statistics.mean then
                                        local vi = area:index(x, y, z)
                                        data[vi] = minetest.get_content_id(loadRealm.MetaStorage.symbology_palette)
                                        -- TODO: allow user input for the logical range below
                                        param2[vi] = lasfile.map_to_8bit(voxels[xx][zz][yy].intensity_statistics.mean, 0, 65535)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        vm:set_data(data)    
        vm:set_param2_data(param2)
        vm:write_to_map(true)
        
    end
end

function lasfile.map_to_8bit(value, min_range, max_range)
    -- Ensure that the value is within the specified range
    value = math.max(min_range, math.min(max_range, value))

    -- Map the value to the 0-255 range
    local mapped_value = math.floor((value - min_range) / (max_range - min_range) * 255 + 0.5)

    return mapped_value
end

minetest.register_on_generated(function(minp, maxp, seed)
    -- Loop through registered realms and check if the coordinate is contained by one
    for _, loadRealm in pairs(Realm.realmDict) do
        if lasfile.ChunkInRealm(minp, maxp, loadRealm.StartPos, loadRealm.EndPos) then
            -- Our coordinate is in a realm now check if we need to emerge this realm
            if loadRealm.MetaStorage.emerge then
                lasfile.generate(minp, maxp, loadRealm, loadRealm.MetaStorage.las_filename)
            end
            return -- We found it so exit unncessary checks
        end
    end
end)

--- TODO: Retire these chat command and move these function calls to the teacher controller GUI, this is for testing only.
minetest.register_chatcommand("las2ground", {
    params = "<file_name> <realm_name> <xmin> <xmax> <ymin> <ymax> <attribute> <palette>",
    description = "generate the map from las",
    func = function (name,params)
        local filename, realmname, xmin, xmax, ymin, ymax, attribute, palette = params:match("^(%S*%.las)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)%s*(%S*)$")
        if not filename then
            minetest.chat_send_player(name,"Expected .las filename, but none was provided or not formatted correctly.") 
            return
        end

        if not lasfile.file_exists(filename) then 
            minetest.chat_send_player(name,"Filename provided does not exist: "..filename)
            return
        end

        local realmname2, xmin2, xmax2, ymin2, ymax2, attribute2, palette2
        realmname2 = realmname or "nil"
        xmin2 = xmin or "nil"
        xmax2 = xmax or "nil"
        ymin2 = ymin or "nil"
        ymax2 = ymax or "nil"
        attribute2 = attribute or "nil"
        palette2 = palette or "nil"
        minetest.chat_send_all("DEBUG: Command was parsed as: <file_name> "..filename.." <realm_name> "..realmname2.." <xmin> "..xmin2.." <xmax> "..xmax2.." <ymin> "..ymin2.." <ymax> "..ymax2.." <attribute> "..attribute2.." <palette> "..palette2)

        -- Initialize the data structure for the las file
        local lasdb = minetest.deserialize(lasfile.meta:get_string("las_db")) or {header = {}, points = {}, voxels = {}, extent = {}, size = {}, crs = {}}
        if not lasdb.header[filename] then 
            lasdb.header[filename] = lasfile.read_header(filename)
        end
        if not realmname then realmname = filename end

        -- TODO: pass these as arguments CAUTION: flags below are currently set to disallow symbolizing some attributes
        local attributes = {
            ReturnNumber = false,
            NumberOfReturns = false,
            ClassificationFlagSynthetic = false,
            ClassificationFlagKeyPoint = false,
            ClassificationFlagWithheld = false,
            ClassificationFlagOverlap = false,
            ScannerChannel = false,
            ScanDirectionFlag = false,
            EdgeOfFlightLine = false,
            Classification = false,
            Intensity = false,
            UserData = false,
            ScanAngle = false,
            PointSourceID = false,
            GPSTime = false,
            Red = false,
            Green = false,
            Blue = false,
            NIR = false,
            WavePacketDescriptorIndex = false,
            ByteOffsettoWaveformData = false,
            WaveformPacketSizeinBytes = false,
            ReturnPointWaveformLocation = false,
            Xt = false,
            Yt = false,
            Zt = false,
        }

        -- Default to classification
        if not attributes[attribute] and not attribute == "RGB" then 
            attribute = "Classification"
            attributes["Classification"] = true
        end
        -- User defines textures, not a palette
        if attribute and attribute == "Classification" then palette = nil end
        -- Handle special case of RGB
        -- TODO: Implement NIR and false color band combinations
        if attribute == "RGB" then
            attributes["Red"] = true
            attributes["Green"] = true
            attributes["Blue"] = true
        end

        xmin = xmin or nil
        xmax = xmax or nil
        ymin = ymin or nil
        ymax = ymax or nil
        zmin = zmin or nil
        zmax = zmax or nil
        local extent = {
            xmin = tonumber(xmin) or nil,
            xmax = tonumber(xmax) or nil,
            ymin = tonumber(ymin) or nil,
            ymax = tonumber(ymax) or nil,
            zmin = tonumber(zmin) or nil,
            zmax = tonumber(zmax) or nil,
        }

        -- Collect the points
        if not lasdb.voxels[filename] then
            local points, attributes = lasfile.read_points(filename, attributes, extent)
            local time = os.date("*t")
            if points and #points > 0 then
                minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Returned "..tostring(#points).." points that intersected the processing extent.")
                -- TODO: implement sqlite backend in order to handle the points, currently too large for mod storage
                --lasdb.points[filename] = points
            else
                minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] No points intersected the processing extent.")
                return
            end
            local voxels, xmin, ymin, zmin, xmax, ymax, zmax = lasfile.get_voxels(points, xmin, ymin, zmin, xmax, ymax, zmax, attributes)
            lasdb.voxels[filename] = voxels

            -- Size refers to the calculated Minetest dimensions of the classroom to contain all voxels (Note: Y dimension in Minetest is equivalent to Z in LAS)
            local size = {
                X = math.ceil(xmax - xmin) + 1,
                -- The height (Y) will always be a minimum of 80 nodes or a buffer of 80 nodes above the max Z of the LAS
                Y = math.max(math.ceil(lasdb.header[filename].MaxZ + 80), 80),
                Z = math.ceil(ymax - ymin) + 1,
            }
            lasdb.size[filename] = size

            -- Extent refers to the min and max of raw LAS X, Y, Z coordinates
            local extent = {
                min = {
                    X = xmin,
                    Y = ymin,
                    Z = zmin,
                },
                max = {
                    X = xmax,
                    Y = ymax,
                    Z = zmax,
                }
            }
            lasdb.extent[filename] = extent

            -- Save
            -- TODO: switch to sqlite backend to also store the points
            --lasfile.meta:set_string("las_db", minetest.serialize(lasdb))
        end

        lasfile.generating_lasdb = lasdb

        -- Create the realm, we do not need to capture the output here
        _ = lasfile.create_classroom(filename, realmname, name, lasdb.size[filename].X, lasdb.size[filename].Y, lasdb.size[filename].Z, attribute, palette)
    end
})

minetest.register_chatcommand("h", {
    description = "dump all values of the las header to chat",
    func = function (name,params)
        local filename, _ = params:match("^(%S*%.las)%s*(%S*)$")
        --local lasheader = lasfile.read_header(filename)
        local lasdb_string = lasfile.meta:get_string("las_db")
        local lasdb = minetest.deserialize(lasdb_string) or {header = {}, points = {}, voxels = {}, extent = {}, size = {}, crs = {}}
        if lasdb and lasdb.header and lasdb.header[filename] then
            local lasheader = lasdb.header[filename]
            minetest.chat_send_player(name,"------------ LAS FILE HEADER -----------")
            for k,v in pairs(lasheader) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                minetest.chat_send_player(name,'[' .. k .. '] = ' .. dump(v))
            end
        else
            local lasheader = lasfile.read_header(filename)
            minetest.chat_send_player(name,"------------ LAS FILE HEADER -----------")
            for k,v in pairs(lasheader) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                minetest.chat_send_player(name,'[' .. k .. '] = ' .. dump(v))
            end
            --local time = os.date("*t")
            --minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: Reading header failed.")
        end
    end
})

minetest.register_chatcommand("d", {
    description = "dump all values of a table to chat",
    func = function (name,params)
        local lasdb_string = lasfile.meta:get_string("las_db")
        local lasdb = minetest.deserialize(lasdb_string) or {header = {}, points = {}, voxels = {}, extent = {}, size = {}, crs = {}}
        minetest.chat_send_player(name,"------------ TABLE DUMP -----------")
        for k,v in pairs(lasdb) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            minetest.chat_send_player(name,'[' .. k .. '] = ' .. dump(v))
        end
    end
})

minetest.register_chatcommand("v", {
    description = "dump value of specific key in las header to chat",
    func = function (name,params)
        local filename, key = params:match("^(%S*%.las)%s*(%S*)$")
        local lasheader = lasfile.read_header(filename)
        if lasheader then
            for k,v in pairs(lasheader) do
                if key == k then minetest.chat_send_player(name,'[' .. k .. '] = ' .. dump(v)) end
            end
        else
            local time = os.date("*t")
            minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [lasfile] Error: Reading header failed.")
        end
    end
})

return lasfile