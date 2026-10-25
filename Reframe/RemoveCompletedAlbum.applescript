-- Remove only the exact generated album after the verified output is on disk.
-- Verify exact generated media IDs before deleting the temporary library copies.
-- Recently Deleted is left alone; never empty unrelated trash.
on run argv
    set albumName to item 1 of argv
    set guardPath to item 2 of argv
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
        set expectedIDs to {}
        repeat with anItem in itemsInAlbum
            set end of expectedIDs to id of anItem
        end repeat
        -- reveal is supported by Photos; do not rely on writable selection.
        reveal itemsInAlbum
    end tell
    delay 0.5
    tell application "Photos"
        set selectedItems to selection
        if (count of selectedItems) is not 2 then error "Could not select exactly two temporary photos; nothing deleted."
        repeat with anItem in selectedItems
            if expectedIDs does not contain (id of anItem) then error "Selected photo mismatch; nothing deleted."
        end repeat
    end tell
    -- Recheck the working library immediately before the deletion action.
    do shell script quoted form of guardPath
    tell application "Photos" to activate
    tell application "System Events"
        tell process "Photos"
            if frontmost is false then error "Photos is not frontmost; nothing deleted."
            if (count of sheets of front window) is not 0 then error "Unexpected Photos dialog; nothing deleted."
            -- Command-Delete deletes library copies, rather than only album membership.
            key code 51 using {command down}
        end tell
    end tell
    set removed to false
    repeat 30 times
        delay 0.2
        tell application "Photos"
            set remaining to 0
            repeat with mediaID in expectedIDs
                set remaining to remaining + (count of (every media item whose id is (contents of mediaID)))
            end repeat
        end tell
        if remaining is 0 then
            set removed to true
            exit repeat
        end if
    end repeat
    if removed is false then error "Temporary photo deletion was not confirmed; Photos left open."
    tell application "Photos"
        set matches to every album whose name is albumName
        if (count of matches) is not 1 then error "Working album changed; Photos left open."
        set workAlbum to item 1 of matches
        if (count of media items of workAlbum) is not 0 then error "Working album is not empty; Photos left open."
        delete workAlbum
        quit
    end tell
    return "Temporary photos deleted, empty album removed, and Photos quit."
end run
