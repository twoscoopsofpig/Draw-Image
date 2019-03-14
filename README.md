# Draw-Image
Original concepts by /u/NotNotWrongUsually, /u/punisher1005, /u/Nation_State_Tractor, and benoitpatra.com  
Cruelly abused and twisted by /u/twoscoopsofpig  

Use:  
    Draw-Image "http://url.to.image/image.ext" -pxsize 8 -max  
    Draw-Image .\some\path\imagename.ext -pxsize 8 -max  
    ($image = Draw-Image.\some\path\imagename.ext -pxsize 8 -max -return)  

March 2019

Based on the flurry of WE CAN DRAW IMAGES IN THE CONSOLE? over the past few days on r/powershell, I've combined some bits from others to put this together.

This will handle local or Web-based images gracefully, and will resize them to fit the console automatically, keeping a square aspect ratio. The console will even maximize itself if you want. It will also handle non-images relatively gracefully.

As is tradition, error-handling is barely a thing, but the code is at least signed, so RemoteSigned is fine for exec policy.

Credit to:  
    u/NotNotWrongUsually for the original Draw-Color function that kicked this off, and some speed optimizations  
    u/punisher1005 for the bitmap transforms that made drawing an image possible  
    benoitpatra.com for the resizing portion  
    /u/Nation_State_Tractor for automatic in-console font resizing
