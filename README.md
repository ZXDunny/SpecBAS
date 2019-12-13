# SpecBAS
An enhanced Sinclair  BASIC interpreter for modern PCs

Based on the 1982 Sinclair Spectrum's implementation of Dartmouth BASIC, SpecBAS will run programs for that computer with a reasonably high degree of compatibility. However, where the Spectrum was limited to 256x192 resolution with 8 colours (and two levels of brightness), SpecBAS offers flexible screen resolutions and 256 colours (32bit is a feature in development). 

Due to this, certain functions of the original language will not work as they did back in the 80s. The ATTR function is not implemented, as each pixel can be any colour from the palette rather than the "two colours per character" mode of the original. BORDER is similarly absent as it's no longer needed. 

SpecBAS offers other enhancements - much more powerful drawing commands, sprites, full sound sample and .mod support along with many others. 

It's generally considered a "Toy" language and although vastly faster than the original, it's not fast enough for serious work. There are demos of the language available to view at:

https://www.youtube.com/user/ZXSpin/videos


Installing SpecBAS:

SpecBAS needs two folders - one for the interpreter to live, one for your data files to live. 

By default, in Windows 7 and up, it's in c:\users\<username>\specbas. You can go ahead and create that folder if you desire, but SpecBAS will create it for you on first run.

You can create a folder for SpecBAS's interpreter anywhere you like, say, c:\program files\SpecBAS - and copy the following files in there:

SpecBAS.exe
SpecBAS_x64.exe
Bass.dll
Bass64.dll
What's New.txt

To launch SpecBAS, just double click either of the exe files. SpecBAS.exe is 32bit, SpecBAS_x64.exe is 64bit. The 64bit build is faster, and contains 64bit optimisations. 

You may notice that the font is small on current monitors. Worry not - unpack the specbas_sysfiles.zip file into your c:\users\<username>\specbas folder. It contains more folders, and the important one is "s" where the file "startup-sequence" lives. This is a BASIC program that is executed when SpecBAS starts up, or a NEW command is issued. If you inspect this file in notepad, you will see the DATA statement at line 60 contains the words "edfontscalex" and "edfontscaley" - the numbers after those are the scaling factor for the font. If you like a small font, use 1 for each. If you want double size, set them both to 2.

And you'll probably want demos.

Unpack the Demos.zip file into your c:\users\<username>\specbas folder - this will create a folder in there called "demos". When SpecBAS starts, use LOAD "" to bring up a file requester and navigate in there to load one of the hundreds of demos in there. 

Note that SpecBAS can only "see" your c:\users\<username>\specbas folder. It cannot make use of any other location on your hard drive - this is intentional and not subject to change. 
