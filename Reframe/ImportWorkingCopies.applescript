-- Import two uniquely named working copies into the Photos library that is CURRENTLY OPEN.
-- This script cannot identify the active library reliably: InjectZ requires explicit confirmation.
on run argv
    set leftPath to item 1 of argv
    set rightPath to item 2 of argv
    set albumName to item 3 of argv
    tell application "Photos"
        activate
        set workAlbum to make new album named albumName
        import {POSIX file leftPath, POSIX file rightPath} into workAlbum skip check duplicates yes
    end tell
    return albumName
end run
