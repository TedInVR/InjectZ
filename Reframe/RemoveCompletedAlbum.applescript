-- Remove only the exact generated album after the verified output is on disk.
-- Photos retains the imported media in its library; this does not delete assets.
on run argv
    set albumName to item 1 of argv
    if albumName does not start with "InjectZ-" or (count of characters of albumName) is not 44 then error "Invalid working album name."
    set runID to text 9 thru -1 of albumName
    tell application "Photos"
        set matches to every album whose name is albumName
        if (count of matches) is not 1 then error "Expected exactly one matching album."
        set workAlbum to item 1 of matches
        set itemsInAlbum to media items of workAlbum
        if (count of itemsInAlbum) is not 2 then error "Expected exactly two photos in working album."
        set leftCount to 0
        set rightCount to 0
        repeat with anItem in itemsInAlbum
            set itemName to filename of anItem
            if itemName starts with ("InjectZ_" & runID & "_LEFT.") then
                set leftCount to leftCount + 1
            else if itemName starts with ("InjectZ_" & runID & "_RIGHT.") then
                set rightCount to rightCount + 1
            else
                error "Unexpected photo in working album."
            end if
        end repeat
        if leftCount is not 1 or rightCount is not 1 then error "Unexpected working photo filenames."
        delete workAlbum
    end tell
    return "Working album removed; media retained in Photos library."
end run
