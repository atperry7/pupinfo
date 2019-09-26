--Dump the contents of a table
function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end

            if type(k) ~= "number" and (k:contains("_raw") or k:contains("_data")) then
                s = s .. "[" .. k .. "] = " .. 'binaray' .. ",\n"
            else
                s = s .. "[" .. k .. "] = " .. dump(v) .. ",\n"
            end
        end
        return s .. "} "
    else
        return tostring(o)
    end
end
