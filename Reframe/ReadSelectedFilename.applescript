-- Read-only selection verification after Accessibility has opened one working photo.
on run argv
    set albumName to item 1 of argv
    tell application "Photos"
        set matchingAlbums to every album whose name is albumName
        if (count of matchingAlbums) is not 1 then error "Working album missing or ambiguous."
        set allowedItems to media items of item 1 of matchingAlbums
        if (count of allowedItems) is not 2 then error "Working album does not contain exactly two photos."
        set chosen to selection
        if (count of chosen) is not 1 then error "Photos does not expose one selected photo."
        set chosenID to id of item 1 of chosen
        repeat with candidate in allowedItems
            if (id of candidate) is chosenID then return filename of candidate
        end repeat
        error "Selected photo is not in working album."
    end tell
end run
