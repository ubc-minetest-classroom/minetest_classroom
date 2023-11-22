local modname = minetest.get_current_modname()
local MOD_PATH = minetest.get_modpath(modname)
local LIB_PATH = MOD_PATH .. "/lasdata/"
dofile(MOD_PATH .. "/struct.lua")

LASFile = {
    xdim = {},
    ydim = {},
    zdim = {},
    voxelMap = {},
    attributes = {
        ReturnNumber = true,
        NumberOfReturns = true,
        ClassificationFlagSynthetic = true,
        ClassificationFlagKeyPoint = true,
        ClassificationFlagWithheld = true,
        ClassificationFlagOverlap = true,
        ScannerChannel = true,
        ScanDirectionFlag = true,
        EdgeOfFlightLine = true,
        Classification = true,
        Intensity = true,
        UserData = true,
        ScanAngle = true,
        PointSourceID = true,
        GPSTime = true,
    },
    place_low_veg = true,
    place_medium_veg = true,
    place_high_veg = true,
    place_tree_stems = true,
    place_buildings = true,
    extent = {
        xmin = nil,
        xmax = nil,
        ymin = nil,
        ymax = nil,
    },
    las_files = {},
    temp = {},
}

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

function LASFile.header(filename)
    local file = assert(io.open(LIB_PATH .. filename, "rb"))

    -- Read the file size
    local file_size = file:seek("end")

    -- Ensure the file is at least 227 bytes (minimum size of LAS header in version 1.0)
    if file_size < 227 then
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: File is too small to contain a valid LAS header.")
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
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: File is too small to contain a valid LAS header.")
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

function LASFile.read_points(filename, attributes, extent, lasheader)
    minetest.chat_send_all("DEBUG read_points: filename "..filename)
    if lasheader then minetest.chat_send_all("DEBUG read_points: lasheader provided") else minetest.chat_send_all("DEBUG read_points: lasheader missing") end
    -- Sanitize input attributes
    if attributes then
        LASFile.attributes.Intensity = attributes.Intensity or nil
        LASFile.attributes.ReturnNumber = attributes.ReturnNumber or nil
        LASFile.attributes.NumberOfReturns = attributes.NumberOfReturns
        LASFile.attributes.ClassificationFlagSynthetic = attributes.ClassificationFlagSynthetic or nil
        LASFile.attributes.ClassificationFlagKeyPoint = attributes.ClassificationFlagKeyPoint or nil
        LASFile.attributes.ClassificationFlagWithheld = attributes.ClassificationFlagWithheld or nil
        LASFile.attributes.ClassificationFlagOverlap = attributes.ClassificationFlagOverlap or nil
        LASFile.attributes.ScannerChannel = attributes.ScannerChannel or nil
        LASFile.attributes.ScanDirectionFlag = attributes.ScanDirectionFlag or nil
        LASFile.attributes.EdgeOfFlightLine = attributes.EdgeOfFlightLine or nil
        LASFile.attributes.Classification = attributes.Classification or nil
        LASFile.attributes.UserData = attributes.UserData or nil
        LASFile.attributes.ScanAngle = attributes.ScanAngle or nil
        LASFile.attributes.PointSourceID = attributes.PointSourceID or nil
        LASFile.attributes.Red = attributes.Red or nil
        LASFile.attributes.Green = attributes.Green or nil
        LASFile.attributes.Blue = attributes.Blue or nil
        LASFile.attributes.NIR = attributes.NIR or nil
        LASFile.attributes.WavePacketDescriptorIndex = attributes.WavePacketDescriptorIndex or nil
        LASFile.attributes.ByteOffsettoWaveformData = attributes.ByteOffsettoWaveformData or nil
        LASFile.attributes.WaveformPacketSizeinBytes = attributes.WaveformPacketSizeinBytes or nil
        LASFile.attributes.ReturnPointWaveformLocation = attributes.ReturnPointWaveformLocation or nil
        LASFile.attributes.Xt = attributes.Xt or nil
        LASFile.attributes.Yt = attributes.Yt or nil
        LASFile.attributes.Zt = attributes.Zt or nil
    end

    -- Sanitize input processing extent
    if extent then
        LASFile.extent.xmin = tonumber(extent.xmin) or nil
        LASFile.extent.xmax = tonumber(extent.xmax) or nil
        LASFile.extent.ymin = tonumber(extent.ymin) or nil
        LASFile.extent.ymax = tonumber(extent.ymax) or nil
    end

    minetest.chat_send_all("DEBUG read_points: opening file at path "..LIB_PATH..filename)
    local file = assert(io.open(LIB_PATH .. filename, "rb"))
    if file then minetest.chat_send_all("DEBUG read_points: file is open") else minetest.chat_send_all("DEBUG read_points: file is nil") end
    local xmin = lasheader.MinX
    local xmax = lasheader.MaxX
    local ymin = lasheader.MinY
    local ymax = lasheader.MaxY
    minetest.chat_send_all("DEBUG read_points: xmin="..xmin.." xmax="..xmax.." ymin="..ymin.." ymax="..ymax)

    -- Check that we have valid processing extent values
    if (LASFile.extent.xmin == nil and LASFile.extent.xmax == nil and LASFile.extent.ymin == nil and LASFile.extent.ymax == nil) or (LASFile.extent.xmin and LASFile.extent.xmax and LASFile.extent.ymin and LASFile.extent.ymax) then
        minetest.chat_send_all("DEBUG read_points: passed the first check")
        -- Check that the processing extent values are specified correctly
        if (LASFile.extent.xmin == nil and LASFile.extent.xmax == nil and LASFile.extent.ymin == nil and LASFile.extent.ymax == nil) or (LASFile.extent.xmin < LASFile.extent.xmax and LASFile.extent.ymin < LASFile.extent.ymax) then
            minetest.chat_send_all("DEBUG read_points: passed the second check")
            -- Check if the processing extent intersects with the LAS file extent
            if (LASFile.extent.xmin == nil and LASFile.extent.xmax == nil and LASFile.extent.ymin == nil and LASFile.extent.ymax == nil) or ((LASFile.extent.xmin >= xmin and LASFile.extent.ymax >= ymin and LASFile.extent.xmin <= xmax and LASFile.extent.ymax <= ymax) or (LASFile.extent.xmax >= xmin and LASFile.extent.ymax >= ymin and LASFile.extent.xmax <= xmax and LASFile.extent.ymax <= ymax) or (LASFile.extent.xmin >= xmin and LASFile.extent.ymin <= ymax and LASFile.extent.xmin <= xmax and LASFile.extent.ymin >= ymin) or (LASFile.extent.xmax >= xmin and LASFile.extent.ymin <= ymax and LASFile.extent.xmax <= xmax and LASFile.extent.ymin >= ymin)) then
                minetest.chat_send_all("DEBUG read_points: passed the third check")
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
                    minetest.chat_send_all("DEBUG read_points: expec 1.2 opened here")
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

                minetest.chat_send_all("DEBUG read_points: point format is "..point_format)

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
                if LASFile.extent.xmin == nil or LASFile.extent.xmax == nil or LASFile.extent.ymin == nil or LASFile.extent.ymax == nil then
                    print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] No processing extent provided, returning all points...")
                else
                    print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Processing extent xmin="..tostring(LASFile.extent.xmin).." xmax="..tostring(LASFile.extent.xmax).." ymin="..tostring(LASFile.extent.ymin).." ymax="..tostring(LASFile.extent.ymax).." , returning points that intersect the processing extent...")
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
                    if (LASFile.extent.xmin == nil and LASFile.extent.xmax == nil and LASFile.extent.ymin == nil and LASFile.extent.ymax == nil) or (LASFile.extent.xmin <= xx and xx <= LASFile.extent.xmax and LASFile.extent.ymin <= yy and yy <= LASFile.extent.ymax) then                       
                        local zz = tonumber(point_data[3])*tonumber(lasheader.ZScaleFactor)+tonumber(lasheader.ZOffset)
                        --minetest.chat_send_all("DEBUG read_points: point at x="..xx.." y="..yy.." z="..zz)
                        -- TODO: check that all attributes are supported here from all versions
                        local Intensity, ReturnNumber, NumberOfReturns, ClassificationFlagSynthetic, ClassificationFlagKeyPoint, ClassificationFlagWithheld, ClassificationFlagOverlap, ScannerChannel, ScanDirectionFlag, EdgeOfFlightLine, Classification, UserData, ScanAngle, PointSourceID, GPSTime, Red, Green, Blue, NIR, WavePacketDescriptorIndex, ByteOffsettoWaveformData, WaveformPacketSizeinBytes, ReturnPointWaveformLocation, Xt, Yt, Zt = nil

                        -- Intensity position is common amongst all versions
                        if LASFile.attributes.Intensity then 
                            Intensity = point_data[4]
                        end

                        -- LAS file version 1.1
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 1 then
                        
                            -- These attributes are common to all formats

                            if LASFile.attributes.ReturnNumber then
                                local return_number_bit_0 = getBit(point_data[5], 0)
                                local return_number_bit_1 = getBit(point_data[5], 1)
                                local return_number_bit_2 = getBit(point_data[5], 2)
                                ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                            end

                            if LASFile.attributes.NumberOfReturns then
                                local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                            end

                            if LASFile.attributes.ScanDirectionFlag then 
                                local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                ScanDirectionFlag = scan_direction_flag_bit_6
                            end
            
                            if LASFile.attributes.EdgeOfFlightLine then 
                                local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                EdgeOfFlightLine = edge_of_flight_line_bit_7
                            end

                            if LASFile.attributes.Classification then
                                local classification_flags_bit_0 = getBit(point_data[6], 0)
                                local classification_flags_bit_1 = getBit(point_data[6], 1)
                                local classification_flags_bit_2 = getBit(point_data[6], 2)
                                local classification_flags_bit_3 = getBit(point_data[6], 3)
                                local classification_flags_bit_4 = getBit(point_data[6], 4)
                                Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                            end

                            if LASFile.attributes.ClassificationFlagSynthetic then
                                local classification_flags_bit_5 = getBit(point_data[6], 5)
                                ClassificationFlagSynthetic = classification_flags_bit_5
                            end
            
                            if LASFile.attributes.ClassificationFlagKeyPoint then
                                local classification_flags_bit_6 = getBit(point_data[6], 6)
                                ClassificationFlagKeyPoint = classification_flags_bit_6
                            end
            
                            if LASFile.attributes.ClassificationFlagWithheld then
                                local classification_flags_bit_7 = getBit(point_data[6], 7)
                                ClassificationFlagWithheld = classification_flags_bit_7
                            end

                            if LASFile.attributes.ScanAngle then
                                ScanAngle = tonumber(point_data[7])*0.006
                            end

                            if LASFile.attributes.UserData then 
                                UserData = point_data[8]
                            end

                            if LASFile.attributes.PointSourceID then
                                PointSourceID = point_data[9]
                            end

                            -- Attributes below are specific to certain formats

                            if lasheader.PointDataRecordFormat == "1" then
                                if LASFile.attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end
                            end
                        end

                        -- LAS file version 1.2
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 2 then

                            -- These attributes are common to all formats

                            if LASFile.attributes.ReturnNumber then
                                local return_number_bit_0 = getBit(point_data[5], 0)
                                local return_number_bit_1 = getBit(point_data[5], 1)
                                local return_number_bit_2 = getBit(point_data[5], 2)
                                ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                            end

                            if LASFile.attributes.NumberOfReturns then
                                local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                            end

                            if LASFile.attributes.ScanDirectionFlag then 
                                local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                ScanDirectionFlag = scan_direction_flag_bit_6
                            end
            
                            if LASFile.attributes.EdgeOfFlightLine then 
                                local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                EdgeOfFlightLine = edge_of_flight_line_bit_7
                            end

                            if LASFile.attributes.Classification then
                                local classification_flags_bit_0 = getBit(point_data[6], 0)
                                local classification_flags_bit_1 = getBit(point_data[6], 1)
                                local classification_flags_bit_2 = getBit(point_data[6], 2)
                                local classification_flags_bit_3 = getBit(point_data[6], 3)
                                local classification_flags_bit_4 = getBit(point_data[6], 4)
                                Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                                minetest.chat_send_all("DEBUG read_points: classification "..Classification)
                            end

                            if LASFile.attributes.ClassificationFlagSynthetic then
                                local classification_flags_bit_5 = getBit(point_data[6], 5)
                                ClassificationFlagSynthetic = classification_flags_bit_5
                            end
            
                            if LASFile.attributes.ClassificationFlagKeyPoint then
                                local classification_flags_bit_6 = getBit(point_data[6], 6)
                                ClassificationFlagKeyPoint = classification_flags_bit_6
                            end
            
                            if LASFile.attributes.ClassificationFlagWithheld then
                                local classification_flags_bit_7 = getBit(point_data[6], 7)
                                ClassificationFlagWithheld = classification_flags_bit_7
                            end

                            if LASFile.attributes.ScanAngle then
                                ScanAngle = tonumber(point_data[7])*0.006
                            end

                            if LASFile.attributes.UserData then 
                                UserData = point_data[8]
                            end

                            if LASFile.attributes.PointSourceID then
                                PointSourceID = point_data[9]
                            end

                            -- Attributes below are specific to certain formats

                            if lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 3 then
                                if LASFile.attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end
                            elseif lasheader.PointDataRecordFormat == 2 then
                                if LASFile.attributes.Red then
                                    Red = point_data[10]
                                end

                                if LASFile.attributes.Green then
                                    Green = point_data[11]
                                end

                                if LASFile.attributes.Blue then
                                    Blue = point_data[12]
                                end
                            elseif lasheader.PointDataRecordFormat == 3  then
                                minetest.chat_send_all("DEBUG read_points: expect PointDataRecordFormat 3 ")
                                if LASFile.attributes.Red then
                                    Red = point_data[11]
                                end

                                if LASFile.attributes.Green then
                                    Green = point_data[12]
                                end

                                if LASFile.attributes.Blue then
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
                            --minetest.chat_send_all("DEBUG read_points: point data X="..xx.." Y="..yy.." Z="..zz.." class="..Classification)
                        end

                        -- LAS file version 1.3
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 3 then

                            -- These attributes are common to all formats

                            if LASFile.attributes.ReturnNumber then
                                local return_number_bit_0 = getBit(point_data[5], 0)
                                local return_number_bit_1 = getBit(point_data[5], 1)
                                local return_number_bit_2 = getBit(point_data[5], 2)
                                ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                            end

                            if LASFile.attributes.NumberOfReturns then
                                local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                            end

                            if LASFile.attributes.ScanDirectionFlag then 
                                local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                ScanDirectionFlag = scan_direction_flag_bit_6
                            end
            
                            if LASFile.attributes.EdgeOfFlightLine then 
                                local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                EdgeOfFlightLine = edge_of_flight_line_bit_7
                            end

                            if LASFile.attributes.Classification then
                                local classification_flags_bit_0 = getBit(point_data[6], 0)
                                local classification_flags_bit_1 = getBit(point_data[6], 1)
                                local classification_flags_bit_2 = getBit(point_data[6], 2)
                                local classification_flags_bit_3 = getBit(point_data[6], 3)
                                local classification_flags_bit_4 = getBit(point_data[6], 4)
                                Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                            end

                            if LASFile.attributes.ClassificationFlagSynthetic then
                                local classification_flags_bit_5 = getBit(point_data[6], 5)
                                ClassificationFlagSynthetic = classification_flags_bit_5
                            end
            
                            if LASFile.attributes.ClassificationFlagKeyPoint then
                                local classification_flags_bit_6 = getBit(point_data[6], 6)
                                ClassificationFlagKeyPoint = classification_flags_bit_6
                            end
            
                            if LASFile.attributes.ClassificationFlagWithheld then
                                local classification_flags_bit_7 = getBit(point_data[6], 7)
                                ClassificationFlagWithheld = classification_flags_bit_7
                            end

                            if LASFile.attributes.ScanAngle then
                                ScanAngle = tonumber(point_data[7])*0.006
                            end

                            if LASFile.attributes.UserData then 
                                UserData = point_data[8]
                            end

                            if LASFile.attributes.PointSourceID then
                                PointSourceID = point_data[9]
                            end

                            -- Attributes below are specific to certain formats

                            if lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 3 then
                                if LASFile.attributes.GPSTime then
                                    GPSTime = point_data[10]
                                end
                            elseif lasheader.PointDataRecordFormat == 2 then
                                if LASFile.attributes.Red then
                                    Red = point_data[10]
                                end

                                if LASFile.attributes.Green then
                                    Green = point_data[11]
                                end

                                if LASFile.attributes.Blue then
                                    Blue = point_data[12]
                                end
                            elseif lasheader.PointDataRecordFormat == 3 then
                                if LASFile.attributes.Red then
                                    Red = point_data[11]
                                end

                                if LASFile.attributes.Green then
                                    Green = point_data[12]
                                end

                                if LASFile.attributes.Blue then
                                    Blue = point_data[13]
                                end
                            end
                        end

                        -- LAS file version 1.4
                        if lasheader.VersionMajor == 1 and lasheader.VersionMinor == 4 then
                            -- Formats 0-5
                            if lasheader.PointDataRecordFormat == 0 or lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 4 or lasheader.PointDataRecordFormat == 5 then
                                if LASFile.attributes.ReturnNumber then
                                    local return_number_bit_0 = getBit(point_data[5], 0)
                                    local return_number_bit_1 = getBit(point_data[5], 1)
                                    local return_number_bit_2 = getBit(point_data[5], 2)
                                    ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_2, 2), leftShift(return_number_bit_1, 1)), return_number_bit_0)
                                end

                                if LASFile.attributes.NumberOfReturns then
                                    local number_of_returns_bit_3 = getBit(point_data[5], 3)
                                    local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                    local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                    NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_5, 2), leftShift(number_of_returns_bit_4, 1)), number_of_returns_bit_3)
                                end

                                if LASFile.attributes.ScanDirectionFlag then 
                                    local scan_direction_flag_bit_6 = getBit(point_data[5], 6)
                                    ScanDirectionFlag = scan_direction_flag_bit_6
                                end
                
                                if LASFile.attributes.EdgeOfFlightLine then 
                                    local edge_of_flight_line_bit_7 = getBit(point_data[5], 7)
                                    EdgeOfFlightLine = edge_of_flight_line_bit_7
                                end

                                if LASFile.attributes.Classification then
                                    local classification_flags_bit_0 = getBit(point_data[6], 0)
                                    local classification_flags_bit_1 = getBit(point_data[6], 1)
                                    local classification_flags_bit_2 = getBit(point_data[6], 2)
                                    local classification_flags_bit_3 = getBit(point_data[6], 3)
                                    local classification_flags_bit_4 = getBit(point_data[6], 4)
                                    Classification = bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_flags_bit_4, 4), leftShift(classification_flags_bit_3, 3)), bitwiseOR(leftShift(classification_flags_bit_2, 2), leftShift(classification_flags_bit_1, 1))), classification_flags_bit_0)
                                end

                                if LASFile.attributes.ClassificationFlagSynthetic then
                                    local classification_flags_bit_5 = getBit(point_data[6], 5)
                                    ClassificationFlagSynthetic = classification_flags_bit_5
                                end
                
                                if LASFile.attributes.ClassificationFlagKeyPoint then
                                    local classification_flags_bit_6 = getBit(point_data[6], 6)
                                    ClassificationFlagKeyPoint = classification_flags_bit_6
                                end
                
                                if LASFile.attributes.ClassificationFlagWithheld then
                                    local classification_flags_bit_7 = getBit(point_data[6], 7)
                                    ClassificationFlagWithheld = classification_flags_bit_7
                                end

                                if LASFile.attributes.ScanAngle then
                                    ScanAngle = tonumber(point_data[7])*0.006
                                end

                                if LASFile.attributes.UserData then 
                                    UserData = point_data[8]
                                end

                                if LASFile.attributes.PointSourceID then
                                    PointSourceID = point_data[9]
                                end

                                -- Attributes below are specific to certain formats
                                
                                if LASFile.attributes.GPSTime and (lasheader.PointDataRecordFormat == 1 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 4 or lasheader.PointDataRecordFormat == 5) then
                                    GPSTime = point_data[10]
                                end

                                if LASFile.attributes.Red and (lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 5) then
                                    Red = point_data[11]
                                end

                                if LASFile.attributes.Green and (lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 5) then
                                    Green = point_data[12]
                                end

                                if LASFile.attributes.Blue and (lasheader.PointDataRecordFormat == 2 or lasheader.PointDataRecordFormat == 3 or lasheader.PointDataRecordFormat == 5) then
                                    Blue = point_data[13]
                                end

                                if LASFile.attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[11]
                                elseif LASFile.attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[14]
                                end

                                if LASFile.attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[12]
                                elseif LASFile.attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[15]
                                end

                                if LASFile.attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[13]
                                elseif LASFile.attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[16]
                                end

                                if LASFile.attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[14]
                                elseif LASFile.attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[17]
                                end

                                if LASFile.attributes.Xt and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[15]
                                elseif LASFile.attributes.Xt and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[18]
                                end

                                if LASFile.attributes.Yt and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[16]
                                elseif LASFile.attributes.Yt and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[19]
                                end

                                if LASFile.attributes.Zt and lasheader.PointDataRecordFormat == 4 then
                                    WavePacketDescriptorIndex = point_data[17]
                                elseif LASFile.attributes.Zt and lasheader.PointDataRecordFormat == 5 then
                                    WavePacketDescriptorIndex = point_data[20]
                                end

                            -- Formats 6-10
                            elseif lasheader.PointDataRecordFormat == 6 or lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 9 or lasheader.PointDataRecordFormat == 10 then
                                if LASFile.attributes.ReturnNumber then
                                    local return_number_bit_0 = getBit(point_data[5], 0)
                                    local return_number_bit_1 = getBit(point_data[5], 1)
                                    local return_number_bit_2 = getBit(point_data[5], 2)
                                    local return_number_bit_3 = getBit(point_data[5], 3)
                                    ReturnNumber = bitwiseOR(bitwiseOR(leftShift(return_number_bit_3, 3), leftShift(return_number_bit_2, 2)), bitwiseOR(leftShift(return_number_bit_1, 1), return_number_bit_0))
                                end
                                
                                if LASFile.attributes.NumberOfReturns then
                                    local number_of_returns_bit_4 = getBit(point_data[5], 4)
                                    local number_of_returns_bit_5 = getBit(point_data[5], 5)
                                    local number_of_returns_bit_6 = getBit(point_data[5], 6)
                                    local number_of_returns_bit_7 = getBit(point_data[5], 7)
                                    NumberOfReturns = bitwiseOR(bitwiseOR(leftShift(number_of_returns_bit_7, 3), leftShift(number_of_returns_bit_6, 2)), bitwiseOR(leftShift(number_of_returns_bit_5, 1), number_of_returns_bit_4))
                                end

                                if LASFile.attributes.ClassificationFlagSynthetic then
                                    local classification_flags_bit_0 = getBit(point_data[6], 0)
                                    ClassificationFlagSynthetic = classification_flags_bit_0
                                end
                
                                if LASFile.attributes.ClassificationFlagKeyPoint then
                                    local classification_flags_bit_1 = getBit(point_data[6], 1)
                                    ClassificationFlagKeyPoint = classification_flags_bit_1
                                end
                
                                if LASFile.attributes.ClassificationFlagWithheld then
                                    local classification_flags_bit_2 = getBit(point_data[6], 2)
                                    ClassificationFlagWithheld = classification_flags_bit_2
                                end
                
                                if LASFile.attributes.ClassificationFlagOverlap then
                                    local classification_flags_bit_3 = getBit(point_data[6], 3)
                                    ClassificationFlagOverlap = classification_flags_bit_3
                                end

                                if LASFile.attributes.ScannerChannel then 
                                    local scanner_channel_bit_4 = getBit(point_data[6], 4)
                                    local scanner_channel_bit_5 = getBit(point_data[6], 5)
                                    ScannerChannel = bitwiseOR(leftShift(scanner_channel_bit_5, 1), scanner_channel_bit_4)
                                end
                
                                if LASFile.attributes.ScanDirectionFlag then 
                                    local scan_direction_flag_bit_6 = getBit(point_data[6], 6)
                                    ScanDirectionFlag = scan_direction_flag_bit_6
                                end
                
                                if LASFile.attributes.EdgeOfFlightLine then 
                                    local edge_of_flight_line_bit_7 = getBit(point_data[6], 7)
                                    EdgeOfFlightLine = edge_of_flight_line_bit_7
                                end

                                if LASFile.attributes.Classification then 
                                    local classification_bit_0 = getBit(point_data[7], 0)
                                    local classification_bit_1 = getBit(point_data[7], 1)
                                    local classification_bit_2 = getBit(point_data[7], 2)
                                    local classification_bit_3 = getBit(point_data[7], 3)
                                    local classification_bit_4 = getBit(point_data[7], 4)
                                    Classification = bitwiseOR(bitwiseOR(bitwiseOR(bitwiseOR(leftShift(classification_bit_4, 4), leftShift(classification_bit_3, 3)), leftShift(classification_bit_2, 2)), leftShift(classification_bit_1, 1)), classification_bit_0)
                                end
                
                                if LASFile.attributes.UserData then 
                                    UserData = point_data[8]
                                end
                
                                if LASFile.attributes.ScanAngle then
                                    ScanAngle = tonumber(point_data[9])*0.006
                                end
                
                                if LASFile.attributes.PointSourceID then
                                    PointSourceID = point_data[10]
                                end
                
                                if LASFile.attributes.GPSTime then
                                    GPSTime = point_data[11]
                                end

                                -- Attributes below are specific to certain formats

                                if LASFile.attributes.Red and (lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    Red = point_data[12]
                                end

                                if LASFile.attributes.Green and (lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    Green = point_data[13]
                                end

                                if LASFile.attributes.Blue and (lasheader.PointDataRecordFormat == 7 or lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    Blue = point_data[14]
                                end

                                if LASFile.attributes.NIR and (lasheader.PointDataRecordFormat == 8 or lasheader.PointDataRecordFormat == 10) then
                                    NIR = point_data[15]
                                end

                                if LASFile.attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[12]
                                elseif LASFile.attributes.WavePacketDescriptorIndex and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[16]
                                end

                                if LASFile.attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[13]
                                elseif LASFile.attributes.ByteOffsettoWaveformData and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[17]
                                end

                                if LASFile.attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[14]
                                elseif LASFile.attributes.WaveformPacketSizeinBytes and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[18]
                                end

                                if LASFile.attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[15]
                                elseif LASFile.attributes.ReturnPointWaveformLocation and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[19]
                                end

                                if LASFile.attributes.Xt and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[16]
                                elseif LASFile.attributes.Xt and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[20]
                                end

                                if LASFile.attributes.Yt and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[17]
                                elseif LASFile.attributes.Yt and lasheader.PointDataRecordFormat == 10 then
                                    WavePacketDescriptorIndex = point_data[21]
                                end

                                if LASFile.attributes.Zt and lasheader.PointDataRecordFormat == 9 then
                                    WavePacketDescriptorIndex = point_data[18]
                                elseif LASFile.attributes.Zt and lasheader.PointDataRecordFormat == 10 then
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
                return points
            else
                local time = os.date("*t")
                print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: LAS file does not intersect with the processing extent.")
                file:close()
                return
            end
        else
            local time = os.date("*t")
            print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: Processing extent was not defined correctly.")
            file:close()
            return
        end
    else
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: Processing extent was not defined correctly or completely.")
        file:close()
        return
    end
end

function LASFile.get_points_by_class(points,classcode)
    local classPoints = {}
    for _, point in ipairs(points) do
        if point.Classification == tonumber(classcode) then
            table.insert(classPoints, point)
        end
    end
    return classPoints
end

function LASFile.createVoxelMap(points,classcode,xmin,ymin,zmin,xmax,ymax,zmax)
    local voxelMap = {}
    
    minetest.chat_send_all("DEBUG createVoxelMap: Points = "..#points)

    -- Filter points by classification
    local classPoints = LASFile.get_points_by_class(points,tonumber(classcode))
    minetest.chat_send_all("DEBUG createVoxelMap: code = "..classcode.." classPoints = "..#classPoints)

    -- Get the dims
    if not xmin and not ymin and not zmin then
        -- Find the bounding extent of the class points
        xmin, ymin, zmin = math.huge, math.huge, math.huge
        xmax, ymax, zmax = -math.huge, -math.huge, -math.huge
        for _, point in ipairs(classPoints) do
            xmin = math.min(xmin, point.X)
            ymin = math.min(ymin, point.Y)
            zmin = math.min(zmin, point.Z)
            xmax = math.max(xmax, point.X)
            ymax = math.max(ymax, point.Y)
            zmax = math.max(zmax, point.Z)
        end
    end
    minetest.chat_send_all("DEBUG createVoxelMap: xmin="..xmin.." ymin="..ymin.." zmin="..zmin.." xmax="..xmax.." ymax="..ymax.." zmax="..zmax)
    local xdim, ydim
    xdim = math.ceil(xmax - xmin) + 1
    ydim = math.ceil(ymax - ymin) + 1

    -- Initialize the voxel map
    for x = 1, xdim do
        voxelMap[x] = {}
        for y = 1, ydim do
            voxelMap[x][y] = -math.huge
        end
    end

    -- Populate the voxel map with maximum z values
    for _, point in ipairs(classPoints) do
        local x = math.floor(point.X - xmin) + 1
        local y = math.floor(point.Y - ymin) + 1
        voxelMap[x][y] = math.max(voxelMap[x][y], math.floor(point.Z - 0.5))
    end

    return voxelMap, xmin, ymin, zmin, xmax, ymax, zmax
end

function LASFile.classify_vegetation_voxelmaps(points, xmin, ymin, xmax, ymax, groundVoxelMap)
    local low_veg = {}
    local med_veg = {}
    local high_veg = {}

    local xdim = math.ceil(xmax - xmin) + 1
    local ydim = math.ceil(ymax - ymin) + 1
    
    -- Initialize the vegetation voxel maps
    for x = 1, xdim do
        low_veg[x] = {}
        med_veg[x] = {}
        high_veg[x] = {}
        for y = 1, ydim do
            low_veg[x][y] = -math.huge
            med_veg[x][y] = -math.huge
            high_veg[x][y] = -math.huge
        end
    end

    for _, point in ipairs(points) do
        local x = math.floor(point.X - xmin) + 1
        local y = math.floor(point.Y - ymin) + 1

        if groundVoxelMap[x] and groundVoxelMap[x][y] then
            local groundZ = groundVoxelMap[x][y]

            if groundZ ~= -math.huge then
                local above_ground = point.Z - groundZ

                if above_ground >= 0 and above_ground <= 2 and point.Classification ~= 6 then
                    low_veg[x][y] = math.max(low_veg[x][y], math.floor(point.Z - 0.5))
                    point.Classification = 3  -- Assuming class 3 for low vegetation
                elseif above_ground > 2 and above_ground <= 5 and point.Classification ~= 6 then
                    med_veg[x][y] = math.max(med_veg[x][y], math.floor(point.Z - 0.5))
                    point.Classification = 4  -- Assuming class 4 for medium vegetation
                elseif above_ground > 5 and point.Classification ~= 6 then
                    high_veg[x][y] = math.max(high_veg[x][y], math.floor(point.Z - 0.5))
                    point.Classification = 5  -- Assuming class 5 for high vegetation
                end
            end
        end
    end

    return low_veg, med_veg, high_veg
end

-- Define Voxel Inverse Distance Weighting (IDW) function
function LASFile.Impute_IDW(x, y, voxelMap)
    local totalWeight = 0
    local weightedSum = 0
    local distances = {}
    local radius = 15
    local k = 5

    -- Calculate distances to all other points within the fixed radius
    for nx = math.max(1, x - radius), math.min(LASFile.sizeX, x + radius) do
        for ny = math.max(1, y - radius), math.min(LASFile.sizeY, y + radius) do
            local z = voxelMap[nx][ny]
            if z ~= -math.huge then
                local dx = x - nx
                local dy = y - ny
                local dist = math.sqrt(dx * dx + dy * dy)
                table.insert(distances, {dist, z})
            end
        end
    end

    -- Sort distances in ascending order
    table.sort(distances, function(a, b) return a[1] < b[1] end)

    -- Get the k-nearest neighbours
    local neighbours = {}
    for i = 1, math.min(k, #distances) do
        table.insert(neighbours, distances[i])
    end

    local weightedSum = 0
    local totalWeight = 0
    for i, neighbour in ipairs(neighbours) do
        local weight = 1 / neighbour[1] ^ 2
        if neighbour[2] then
            weightedSum = weightedSum + neighbour[2] * weight
            totalWeight = totalWeight + weight
        end
    end

    if totalWeight == 0 then
        return -math.huge
    else
        return math.floor((weightedSum / totalWeight) - 0.5)
    end
end

function LASFile.filter_ground_noise(voxelMap, k)
    local kernel_radius = (k - 1) / 2  -- calculate kernel radius based on k

    -- Initialize the temporary voxel map
    local filteredVoxelMap = {}
    for x = 1, LASFile.temp.sizeX do
        filteredVoxelMap[x] = {}
        for y = 1, LASFile.temp.sizeY do
            filteredVoxelMap[x][y] = voxelMap[x][y]  -- copy original values
        end
    end

    -- Apply high-pass filter
    for x = 1, LASFile.temp.sizeX do
        for y = 1, LASFile.temp.sizeY do
            local countZerosAndNegInf = 0
            local totalCells = 0

            if voxelMap[x][y] == 1 then
                -- Get the values within the kernel
                for nx = math.max(1, x - kernel_radius), math.min(LASFile.temp.sizeX, x + kernel_radius) do
                    for ny = math.max(1, y - kernel_radius), math.min(LASFile.temp.sizeY, y + kernel_radius) do
                        totalCells = totalCells + 1
                        if voxelMap[nx][ny] == 0 or voxelMap[nx][ny] == -math.huge then
                            countZerosAndNegInf = countZerosAndNegInf + 1
                        end
                    end
                end
            end

            -- Check if the majority of cells within the kernel are 0 or -math.huge
            if countZerosAndNegInf > totalCells / 2 then
                filteredVoxelMap[x][y] = 0
            end
        end
    end

    return filteredVoxelMap
end

function LASFile.peak_local_max(voxelMap, radius)
    local maximaMap = {}

    -- First iteration to compute the focal maximum
    for x = 1, LASFile.temp.sizeX do
        maximaMap[x] = {}
        for y = 1, LASFile.temp.sizeY do
            local max_value = -math.huge

            -- Find the maximum value in the ciruclar neighborhood
            for nx = math.max(1, x - radius), math.min(LASFile.temp.sizeX, x + radius) do
                for ny = math.max(1, y - radius), math.min(LASFile.temp.sizeY, y + radius) do
                    if (nx - x)^2 + (ny - y)^2 <= radius^2 then
                        max_value = math.max(max_value, voxelMap[nx][ny])
                    end
                end
            end

            maximaMap[x][y] = { value = max_value, label = nil }
        end
    end

    -- Second iteration to set non-max values to -math.huge
    for x = 1, LASFile.temp.sizeX do
        for y = 1, LASFile.temp.sizeY do
            if voxelMap[x][y] ~= maximaMap[x][y] or voxelMap[x][y] == -math.huge then
                maximaMap[x][y] = -math.huge
            end
        end
    end

    return maximaMap
end

function LASFile.label_regions(voxelMap)
    local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}} -- Direction vectors for top, right, bottom, left
    local regions = {}
    local label = 1
    
    for x = 1, LASFile.temp.sizeX do
        for y = 1, LASFile.temp.sizeY do
            if voxelMap[x][y] ~= -math.huge and not voxelMap[x][y].label then
                local stack = {{x = x, y = y}}
                regions[label] = {}
                while #stack > 0 do
                    local current = table.remove(stack)
                    if voxelMap[current.x][current.y].value ~= -math.huge and not voxelMap[current.x][current.y].label then
                        voxelMap[current.x][current.y].label = label
                        table.insert(regions[label], current)
                        for _, direction in ipairs(directions) do
                            local neighbor = {x = current.x + direction[1], z = current.y + direction[2]}
                            if neighbor.x >= 1 and neighbor.x <= LASFile.temp.sizeX and neighbor.y >= 1 and neighbor.y <= LASFile.temp.sizeY then
                                if voxelMap[neighbor.x][neighbor.y].value ~= -math.huge and not voxelMap[neighbor.x][neighbor.y].label then
                                    table.insert(stack, neighbor)
                                end
                            end
                        end
                    end
                end
                label = label + 1
            end
        end
    end
    
    return regions
end

-- Calculate centroid of given positions
function LASFile.calculate_centroid_from_voxelmap(voxelMap)
    local total_x, total_y, num_points = 0, 0, 0
    for x, row in pairs(voxelMap) do
        for y, value in pairs(row) do
            if value ~= -math.huge then
                total_x = total_x + x
                total_y = total_y + y
                num_points = num_points + 1
            end
        end
    end
    if num_points > 0 then
        return {x = math.floor(total_x / num_points), y = math.floor(total_y / num_points)}
    else
        return nil
    end
end

-- Calculate Euclidean distance between two points
function LASFile.calculate_euclidean_distance(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

function LASFile.find_central_positions(voxelMap, labeledVoxelMap)
    
    -- Create a table to store the central positions for each region
    local centralPositions = {}
    
    -- Calculate the centroid for each region and find the central position
    for label, region in pairs(labeledVoxelMap) do
        local centroid = LASFile.calculate_centroid_from_voxelmap(region)
        local min_distance = math.huge
        local central_position = nil
        
        for x, row in pairs(region) do
            for z, value in pairs(row) do
                if value ~= -math.huge then
                    local pos = {x = x, z = z}
                    local distance = LASFile.calculate_euclidean_distance(centroid, pos)
                    if distance < min_distance then
                        min_distance = distance
                        central_position = pos
                    end
                end
            end
        end
        -- Store the central position for this region
        centralPositions[label] = central_position
    end
    
    return centralPositions
end

function LASFile.file_exists(filename)
    local file = io.open(LIB_PATH..filename, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

--- TODO: Retire this chat command and move these function calls to the teacher controller GUI, this is for testing only.

minetest.register_chatcommand("las2ground", {
    params = "<las_file_path> | <las_folder_path> <realm_name>",
    description = "generate the map from las",
    func = function (name,params)
        local filename, realmname = params:match("^(%S*%.las)%s*(%S*)$")
        if not filename then
            minetest.chat_send_player(name,"Expected .las filename, but none was provided or not formatted correctly.") 
            return
        end

        if not LASFile.file_exists(filename) then 
            minetest.chat_send_player(name,"Filename provided does not exist: "..filename)
            return
        end

        LASFile.temp.lasheader = LASFile.header(filename)
        if not realmname then realmname = "las" end

        LASFile.place_low_veg = false
        LASFile.place_medium_veg = false
        LASFile.place_high_veg = false
        LASFile.place_tree_stems = false

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
        }

        local extent = {
            xmin = nil,
            xmax = nil,
            ymin = nil,
            ymax = nil,
        }

        -- Collect the points
        local points = LASFile.read_points(filename, attributes, extent, LASFile.temp.lasheader)
        LASFile.temp.points = points
        local time = os.date("*t")
        minetest.chat_send_all("DEBUG: points returned = "..#points)
        if #LASFile.temp.points > 0 then
            minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Returned "..tostring(#LASFile.temp.points).." points that intersected the processing extent.")
        else
            minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] No points intersected the processing extent.")
            return
        end

        -- Ground
        local GroundVoxelMap, xmin, ymin, zmin, xmax, ymax, zmax = LASFile.createVoxelMap(LASFile.temp.points, 2)
        minetest.chat_send_all("DEBUG: xmin "..xmin)
        minetest.chat_send_all("DEBUG: ymin "..ymin)
        minetest.chat_send_all("DEBUG: zmin "..zmin)
        minetest.chat_send_all("DEBUG: xmax "..xmax)
        minetest.chat_send_all("DEBUG: ymax "..ymax)
        minetest.chat_send_all("DEBUG: zmax "..zmax)

        -- Below ensures that all voxelMaps have the same dims as the ground
        LASFile.temp.sizeX = math.ceil(xmax - xmin) + 1
        LASFile.temp.sizeY = math.ceil(ymax - ymin) + 1
        LASFile.temp.sizeZ = math.max(math.ceil(LASFile.temp.lasheader.MaxZ + 80), 80) -- The height will always be a minimum of 80 nodes or a buffer of 80 nodes above the max Z of the LAS
        LASFile.temp.minX = xmin
        LASFile.temp.minY = ymin
        LASFile.temp.minZ = zmin
        LASFile.temp.maxX = xmax
        LASFile.temp.maxY = ymax
        LASFile.temp.maxZ = zmax

        -- Filter ground noise at/near sea level
        local GroundFilteredVoxelMap = LASFile.filter_ground_noise(GroundVoxelMap, 5)

        -- Fill -inf ground values with Inverse Distance Weighted value
        for x = 1, LASFile.temp.sizeX do
            for y = 1, LASFile.temp.sizeY do
                if GroundFilteredVoxelMap[x][y] == -math.huge then
                    local imputed_value = LASFile.Impute_IDW(x, y, GroundFilteredVoxelMap)
                    if imputed_value ~= -math.huge then
                        GroundFilteredVoxelMap[x][y] = imputed_value
                    end
                end
            end
        end
        LASFile.temp.GroundVoxelMap = GroundFilteredVoxelMap
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Finished Ground (class = 2) Voxel Map")

        -- Vegetation
        local LowVegVoxelMap, MediumVegVoxelMap, HighVegVoxelMap = LASFile.classify_vegetation_voxelmaps(LASFile.temp.points, LASFile.temp.minX, LASFile.temp.minY, LASFile.temp.maxX, LASFile.temp.maxY, LASFile.temp.GroundVoxelMap)
        LASFile.temp.LowVegVoxelMap = LowVegVoxelMap
        LASFile.temp.MediumVegVoxelMap = MediumVegVoxelMap
        LASFile.temp.HighVegVoxelMap = HighVegVoxelMap
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Finished Vegetation (classes = 3, 4, 5) Voxel Maps")

        -- Find tree stems
        -- 1. Initialize a new voxelmap
        local TreeStemVoxelMap = {}
        for x = 1, LASFile.temp.sizeX do
            TreeStemVoxelMap[x] = {}
            for y = 1, LASFile.temp.sizeY do
                TreeStemVoxelMap[x][y] = -math.huge
            end
        end

        -- 2. Calculate focal maxima of the high vegetation voxelmap
        local LocalMaximaVoxelMap = LASFile.peak_local_max(HighVegVoxelMap, 5)

        -- 3. Check for clustered maxima and calculate the centroid position in such cases
        local labeledVoxelMap = LASFile.label_regions(LocalMaximaVoxelMap)
        local centralPositions = LASFile.find_central_positions(LocalMaximaVoxelMap, labeledVoxelMap)

        -- 4. Write out the maximum elevations from the LocalMaximaVoxelMap into our final TreeStemVoxelMap
        for _, pos in ipairs(centralPositions) do
            TreeStemVoxelMap[pos.x][pos.y] = LocalMaximaVoxelMap[pos.x][pos.y].value
        end
        LASFile.temp.TreeStemVoxelMap = TreeStemVoxelMap

        -- Buildings
        local BuildingVoxelMap, _, _, _, _, _, _ = LASFile.createVoxelMap(LASFile.temp.points, 6, LASFile.temp.minX, LASFile.temp.minY, LASFile.temp.minZ, LASFile.temp.maxX, LASFile.temp.maxY, LASFile.temp.maxZ)
        LASFile.temp.BuildingVoxelMap = BuildingVoxelMap
        local time = os.date("*t")
        print(("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Finished Building (class = 6) Voxel Map")

        -- Create the realm, we do not need to capture the output here
        --_ = LASFile.create_realm(realmname, name)
    end
})

minetest.register_chatcommand("d", {
    description = "dump all values of the las header to chat",
    func = function (name,params)
        local filename, _ = params:match("^(%S*%.las)%s*(%S*)$")
        local lasheader = LASFile.header(filename)
        if lasheader then
            minetest.chat_send_player(name,"------------ LAS FILE HEADER -----------")
            for k,v in pairs(lasheader) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                minetest.chat_send_player(name,'[' .. k .. '] = ' .. dump(v))
            end
        else
            local time = os.date("*t")
            minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: Reading header failed.")
        end
    end
})

minetest.register_chatcommand("v", {
    description = "dump value of specific key in las header to chat",
    func = function (name,params)
        local filename, key = params:match("^(%S*%.las)%s*(%S*)$")
        local lasheader = LASFile.header(filename)
        if lasheader then
            for k,v in pairs(lasheader) do
                if key == k then minetest.chat_send_player(name,'[' .. k .. '] = ' .. dump(v)) end
            end
        else
            local time = os.date("*t")
            minetest.chat_send_player(name,("%02d:%02d:%02d"):format(time.hour, time.min, time.sec).." [LASFile] Error: Reading header failed.")
        end
    end
})

function LASFile.create_realm(realmName, pname)
    -- Note here we switch LAS Z and Y for the minetest convention
    local newRealm = Realm:New(realmName, { x = LASFile.temp.sizeX, y = LASFile.temp.sizeZ, z = LASFile.temp.sizeY }, false)
    -- Remove the buffer from the EndPos x,z so that the map fits snuggly in the new realm (add 1 for the barrier)
    newRealm.EndPos.x = newRealm.StartPos.x + LASFile.temp.sizeX + 1
    newRealm.EndPos.y = newRealm.StartPos.y + LASFile.temp.sizeZ + 1 -- LASFile Z is minetest Y
    newRealm.EndPos.z = newRealm.StartPos.z + LASFile.temp.sizeY + 1 -- LASFile Y is minetest Z
    newRealm.MetaStorage.emerge = true
    newRealm:set_data("owner", pname)
    newRealm:CreateBarriersFast()
    newRealm:CallOnCreateCallbacks()
    return newRealm
end

function LASFile.ChunkInRealm(pos1, pos2, pos3, pos4)
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

function LASFile.generate(minp, maxp, loadRealm)
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

        local t0 = os.clock()
        local cid_ground_surface = get_content_id(LASFile.value_itemstring_table["ground_surface"])
        local cid_ground_shallow = get_content_id(LASFile.value_itemstring_table["ground_shallow"])
        local cid_ground_deep = get_content_id(LASFile.value_itemstring_table["ground_deep"])
        local cid_near_sea_level = get_content_id(LASFile.value_itemstring_table["near_sea_level"])
        local cid_sea_level = get_content_id(LASFile.value_itemstring_table["sea_level"])
        local cid_low_vegetation = get_content_id(LASFile.value_itemstring_table["low_vegetation"])
        local cid_medium_vegetation = get_content_id(LASFile.value_itemstring_table["medium_vegetation"])
        local cid_high_vegetation = get_content_id(LASFile.value_itemstring_table["high_vegetation"])
        local cid_tree_stem = get_content_id(LASFile.value_itemstring_table["tree_stem"])
        local cid_building = get_content_id(LASFile.value_itemstring_table["building"])

        local c_dirt = minetest.get_content_id("default:dirt")
        local c_sand = minetest.get_content_id("default:sand")
        local c_surface = minetest.get_content_id("default:dirt_with_grass")
        local c_stone = minetest.get_content_id("default:stone")
        local c_water_source = minetest.get_content_id("default:water_source")
        local c_low_veg = minetest.get_content_id("default:fern_3")
        local c_medium_veg = minetest.get_content_id("default:papyrus")
        local c_high_veg = minetest.get_content_id("default:pine_needles")
        local c_tree_stem = minetest.get_content_id("default:pine_tree")
        local c_building = minetest.get_content_id("default:tinblock")
        local sea_level = 1
        local sand_level = 3
        local filler_depth = 5 

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
                                local zz = math.floor(z - loadRealm.StartPos.z)

                                if LASFile.temp.GroundVoxelMap[xx][zz] then
                                    -- Prepare and index the voxel manipulator
                                    local vi = area:index(x, y, z)

                                    -- Set negative ground values to zero
                                    local ground_elev = LASFile.temp.GroundVoxelMap[xx][zz]
                                    if ground_elev < 0 then ground_elev = 0 end

                                    -- Add the elevation to the realm coordinate space
                                    ground_elev = ground_elev + loadRealm.StartPos.y
            
                                    -- Ground
                                    -- At or below sea_level
                                    if y <= loadRealm.StartPos.y + sea_level then
                                        -- Submerged land (sand)
                                        if y <= ground_elev then
                                            data[vi] = c_sand
                                        -- Just water
                                        else
                                            data[vi] = cid_sea_level -- c_water_source
                                        end
                                    -- Sandy areas near sea_level
                                    elseif y <= loadRealm.StartPos.y + sea_level + sand_level and y <= ground_elev then
                                        data[vi] = cid_near_sea_level -- c_sand
                                    -- Filler below surface
                                    elseif y < ground_elev and y >= ground_elev-filler_depth then
                                        data[vi] = cid_ground_shallow -- c_dirt
                                    -- Bedrock below filler
                                    elseif y < ground_elev-filler_depth then
                                        data[vi] = cid_ground_deep -- c_stone
                                    -- Surface
                                    elseif y == ground_elev then
                                        data[vi] = cid_ground_surface -- c_surface
                                    end
            
                                    -- Low Vegetation
                                    if LASFile.place_low_veg then
                                        local low_veg_elev = LASFile.temp.LowVegVoxelMap[xx][zz]
                                        -- Add the elevation to the realm coordinate space
                                        low_veg_elev = low_veg_elev + loadRealm.StartPos.y
                                        -- We place low veg from the ground to the value of the voxelmap, but not where water currently is
                                        if low_veg_elev ~= -math.huge and y > ground_elev and y <= low_veg_elev and data[vi] ~= cid_sea_level then -- c_water_source
                                            data[vi] = c_low_veg
                                        end
                                    end
            
                                    -- Medium Vegetation
                                    if LASFile.place_medium_veg then
                                        local medium_veg_elev = LASFile.temp.MediumVegVoxelMap[xx][zz]
                                        -- Add the elevation to the realm coordinate space
                                        medium_veg_elev = medium_veg_elev + loadRealm.StartPos.y
                                        -- We place low veg from the ground to the value of the voxelmap, but not where water currently is
                                        if medium_veg_elev ~= -math.huge and y > ground_elev and y <= medium_veg_elev and data[vi] ~= cid_sea_level then -- c_water_source
                                            data[vi] = c_low_veg
                                        end
                                    end
            
                                    -- High Vegetation
                                    if LASFile.place_high_veg then
                                        local high_veg_elev = LASFile.temp.HighVegVoxelMap[xx][zz]
                                        -- Add the elevation to the realm coordinate space
                                        high_veg_elev = high_veg_elev + loadRealm.StartPos.y
                                        -- We place high veg at the value of the voxelmap, but not where water currently is
                                        -- We also dilate this layer +/- 1 node in the y
                                        if high_veg_elev ~= -math.huge and y >= high_veg_elev - 1 and y <= high_veg_elev + 1 and data[vi] ~= cid_sea_level then -- c_water_source
                                            data[vi] = c_high_veg
                                        end
                                    end

                                    -- Tree Stems
                                    if LASFile.place_tree_stems then
                                        local tree_stem_elev = LASFile.temp.TreeStemVoxelMap[xx][zz]
                                        -- Add the elevation to the realm coordinate space
                                        tree_stem_elev = tree_stem_elev + loadRealm.StartPos.y
                                        -- We place tree stem from above the ground to the value of the voxelmap - 1
                                        if tree_stem_elev ~= -math.huge and y > ground_elev and y < tree_stem_elev then
                                            data[vi] = c_tree_stem
                                        end
                                    end
            
                                    -- Building
                                    if LASFile.place_buildings then
                                        local building_elev = LASFile.temp.BuildingVoxelMap[xx][zz]
                                        -- Add the elevation to the realm coordinate space
                                        building_elev = building_elev + loadRealm.StartPos.y
                                        -- We place building from the ground to the value of the voxelmap, but not where water currently is
                                        if building_elev ~= -math.huge and y > ground_elev and y <= building_elev and data[vi] ~= cid_sea_level then -- c_water_source
                                            data[vi] = c_building
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        vm:set_data(data)    
        vm:write_to_map(true)
    end
end

minetest.register_on_generated(function(minp, maxp, seed)
    -- Loop through registered realms and check if the coordinate is contained by one
    for _, loadRealm in pairs(Realm.realmDict) do
        if LASFile.ChunkInRealm(minp, maxp, loadRealm.StartPos, loadRealm.EndPos) then
            -- Our coordinate is in a realm now check if we need to emerge this realm
            if loadRealm.MetaStorage.emerge then
                LASFile.generate(minp, maxp, loadRealm)
            end
            return -- We found it so exit unncessary checks
        end
    end
end)

function LASFile.registerLAS()
    local sep = DIR_DELIM or "/"
    local base_path = minetest.get_modpath("lasfile") .. sep .. "lasdata" .. sep
    local files = minetest.get_dir_list(base_path, false)
    LASFile.las_file_list = {}

    for _, fileName in pairs(files) do
        if fileName:match("%.las$") then
            local filePath = base_path .. fileName
            local path = string.sub(filePath, 1, -5)
            local ext = path:match("^.+(%..+)$")
            local key = string.sub(fileName, 1, -5)

            table.insert(LASFile.las_file_list, key)

            key = string.lower(key)

            -- Sanity checking our LAS registration to ensure we don't enter an invalid state.
            if (key == nil) then
                minetest.log("warning", "tried registering a LAS with nil key:" .. key " for path " .. rootPath .. ".")
                return false
            end

            if (path == nil) then
                minetest.log("warning", "tried registering a LAS with nil path for key: " .. key)
                return false
            end

            LASFile.las_files[key] = path
        end
    end
end

return LASFile