local obj = {}
obj.__index = obj
obj.__name = "seal_pasteboard"
obj.timer = nil
obj.lastItem = nil
obj.itemBuffer = {}

--- Spoon.seal.pasteboard.historySize
--- Variable
---
--- The number of history items to keep. Defaults to 50
obj.historySize = 50

--- Spoon.seal.pasteboard.saveHistory
--- Variable
---
--- A boolean, true if Seal should automatically load/save clipboard history. Defaults to true
obj.saveHistory = true

function obj:commands()
    return {pb = {
        cmd = "pb",
        fn = obj.choicesPasteboardCommand,
        name = "Pasteboard",
        description = "Pasteboard history",
        plugin = obj.__name
        }
    }
end

function obj:bare()
    return nil
end

function obj.choicesPasteboardCommand(query)
    local choices = {}

    for i = #obj.itemBuffer, 1, -1 do
        local pasteboardItem = obj.itemBuffer[i]
        local choice = {}
        choice["name"] = pasteboardItem["text"]
        choice["text"] = pasteboardItem["text"]
        choice["kind"] = kind
        choice["plugin"] = obj.__name
        choice["type"] = "copy"
        if pasteboardItem["uti"] then
            choice["subText"] = pasteboardItem["uti"]
            choice["image"] = hs.image.imageFromAppBundle(pasteboardItem["uti"])
        end
        table.insert(choices, choice)
    end
    return choices
end

function obj.completionCallback(rowInfo)
    if rowInfo["type"] == "copy" then
        hs.pasteboard.setContents(rowInfo["name"])
    end
end

function obj.checkPasteboard()
    local pasteboard = hs.pasteboard.getContents()
    local shouldSave = false
    -- FIXME: Filter out things with UTIs documented at http://nspasteboard.org/
    if pasteboard ~= obj.itemBuffer[#obj.itemBuffer]["text"] then
        local currentTypes = hs.pasteboard.allContentTypes()[1]
        for _,aType in pairs(currentTypes) do
            for _,uti in pairs({"de.petermaurer.TransientPasteboardType",
                          "com.typeit4me.clipping",
                          "Pasteboard generator type",
                          "com.agilebits.onepassword",
                          "org.nspasteboard.TransientType",
                          "org.nspasteboard.ConcealedType",
                          "org.nspasteboard.AutoGeneratedType"}) do
                if uti == aType then
                    return
                end
            end
        end
        item = {}
        item["text"] = pasteboard
        item["uti"] = currentTypes[1]
        table.insert(obj.itemBuffer, item)
        shouldSave = true
    end
    if #obj.itemBuffer > obj.history_size then
        table.remove(obj.itemBuffer, 1)
        shouldSave = true
    end

    if shouldSave then
        obj.save()
    end
end

function obj.save()
    local json = hs.json.encode(obj.itemBuffer)
    local file = io.open(os.getenv("HOME").."/.hammerspoon/pasteboard_history.json", "w")
    if file then
        file:write(json)
        file:close()
    end
end

function obj.load()
    local file = io.open(os.getenv("HOME").."/.hammerspoon/pasteboard_history.json", "r")
    if file then
        local json = hs.json.decode(file:read())
        if json then
            obj.itemBuffer = json
        end
        file:close()
    end
end

obj.load()
if obj.timer == nil then
    obj.timer = hs.timer.doEvery(1, function() obj.checkPasteboard(obj) end)
    obj.timer:start()
end

return obj
