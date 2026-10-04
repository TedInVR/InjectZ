-- Export only edited RIGHT perspective; leave LEFT as the original source file.
on run argv
    set albumName to item 1 of argv
    set outputRoot to item 2 of argv
    set rightDir to outputRoot & "/RIGHT"
    do shell script "/bin/mkdir -p " & quoted form of rightDir
    tell application "Photos"
        set matchingAlbums to (every album whose name is albumName)
        if (count of matchingAlbums) is not 1 then error "Expected exactly one InjectZ album."
        set itemsToExport to media items of item 1 of matchingAlbums
        if (count of itemsToExport) is not 2 then error "Expected exactly two working photos."
        set rightItems to {}
        set leftCount to 0
        repeat with anItem in itemsToExport
            set fileName to filename of anItem
            if fileName contains "_RIGHT." then
                set end of rightItems to contents of anItem
            else if fileName contains "_LEFT." then
                set leftCount to leftCount + 1
            else
                error "Unexpected working photo: " & fileName
            end if
        end repeat
        if (count of rightItems) is not 1 or leftCount is not 1 then error "Working album LEFT/RIGHT validation failed."
        export rightItems to (POSIX file rightDir) without using originals
    end tell
end run
