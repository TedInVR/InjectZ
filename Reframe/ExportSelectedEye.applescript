-- Export the verified, edited thumbnail regardless of its original LEFT/RIGHT filename.
on run argv
    set albumName to item 1 of argv
    set outputRoot to item 2 of argv
    set selectedFilename to item 3 of argv
    set rightDir to outputRoot & "/RIGHT"
    do shell script "/bin/mkdir -p " & quoted form of rightDir
    tell application "Photos"
        set matchingAlbums to every album whose name is albumName
        if (count of matchingAlbums) is not 1 then error "Working album ambiguous."
        set albumItems to media items of item 1 of matchingAlbums
        if (count of albumItems) is not 2 then error "Expected exactly two working photos."
        set selectedItems to {}
        repeat with anItem in albumItems
            if (filename of anItem) is selectedFilename then set end of selectedItems to contents of anItem
        end repeat
        if (count of selectedItems) is not 1 then error "Edited item filename not uniquely found."
        export selectedItems to (POSIX file rightDir) without using originals
    end tell
end run
