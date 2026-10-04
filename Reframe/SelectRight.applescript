-- Experimental Photos selection via scripting. Verify exact album and exact item.
-- Fail safely if Photos refuses programmatic selection.
on run argv
    set albumName to item 1 of argv
    tell application "Photos"
        activate
        set matches to every album whose name is albumName
        if (count of matches) is not 1 then error "Expected exactly one matching working album."
        set photosInAlbum to media items of item 1 of matches
        if (count of photosInAlbum) is not 2 then error "Expected two working photos."
        set rightMatches to {}
        repeat with p in photosInAlbum
            if (filename of p) contains "_RIGHT." then set end of rightMatches to contents of p
        end repeat
        if (count of rightMatches) is not 1 then error "Cannot uniquely identify RIGHT photo."
        set selection to rightMatches
        delay 0.5
        set currentSelection to selection
        if (count of currentSelection) is not 1 then error "Photos did not retain selection."
        if (id of item 1 of currentSelection) is not (id of item 1 of rightMatches) then error "Selected photo mismatch."
    end tell
end run
