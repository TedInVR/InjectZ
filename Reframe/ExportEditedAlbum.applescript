-- Export rendered/edited versions, never originals. Each eye has its own directory.
-- The unique album is created by InjectZ for this run. Fail if its contents differ.
on run argv
    set albumName to item 1 of argv
    set outputRoot to item 2 of argv
    set leftDir to outputRoot & "/LEFT"
    set rightDir to outputRoot & "/RIGHT"
    do shell script "/bin/mkdir -p " & quoted form of leftDir & " " & quoted form of rightDir
    tell application "Photos"
        set matchingAlbums to (every album whose name is albumName)
        if (count of matchingAlbums) is not 1 then error "Expected exactly one InjectZ album."
        set photosToExport to media items of item 1 of matchingAlbums
        if (count of photosToExport) is not 2 then error "Expected exactly two imported photographs."
        set leftItems to {}
        set rightItems to {}
        repeat with anItem in photosToExport
            set fileName to filename of anItem
            if fileName contains "_LEFT." then
                set end of leftItems to contents of anItem
            else if fileName contains "_RIGHT." then
                set end of rightItems to contents of anItem
            else
                error "Album contains an unexpected photo: " & fileName
            end if
        end repeat
        if (count of leftItems) is not 1 or (count of rightItems) is not 1 then error "Could not identify exactly one image for each eye."
        export leftItems to (POSIX file leftDir) without using originals
        export rightItems to (POSIX file rightDir) without using originals
    end tell
    return "EXPORTED " & leftDir & " " & rightDir
end run
