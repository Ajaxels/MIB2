IceImarisConnector
==================

IceImarisConnector is a simple commodity class that eases communication between
[Bitplane Imaris](http://www.bitplane.com) and [MATLAB](http://www.mathworks.com)
using the [Imaris XT interface](http://www.bitplane.com/go/products/imarisxt).

Installation
============
[Download](http://www.scs2.net/next/index.php?id=110) or
[clone](https://github.com/aarpon/IceImarisConnector) IceImarisConnector to your
computer.

Simple installation
-------------------

**Please notice**: from Imaris 7.6.3 on, you **must** add the IceImarisConnector root folder to the MATLAB path!

Copy the <b>@IceImarisApplication</b> subfolder to the Imaris XT folder.

In Windows:

<code>
C:\Program Files\Bitlane\Imaris 7.x.y\XT\matlab
</code>

On Mac OS X:

<code>
/Applications/Imaris 7.x.y.app/Contents/SharedSupport/XT/matlab
</code>

where `7.x.y` represents current Imaris version.

This way, Imaris will find **IceImarisConnector** when launching XTensions.

**NOTE**: It is recommended to add the Imaris XT folder to the MATLAB path to
make it easier to write and debug XTensions from MATLAB.

More flexible installation
--------------------------
Using [MATLABStarter](http://www.scs2.net/next/index.php?id=130), you can keep
**IceImarisConnector** anywhere you like on your file system. This is
particularly useful if you want to keep your git repository intact, or if you
want to add **IceImarisConnector** to your existing MATLAB library and make us
of external dependencies in your XTensions.

IMARISPATH environment variable
-------------------------------
**IceImarisConnector** is clever enough to find Imaris if Imaris itself is
installed in the standard locations.

If more than one Imaris installation is found, **IceImarisConnector** will pick
the latest to work with.

In case you want to use an older Imaris version, or you installed Imaris in a
non-standard location, you have to tell **IceImarisConnector** where to find
the desired installation. You can do that by setting the environment variable
IMARISPATH to point to the Imaris root folder (e.g.
`C:\Program Files\Bitlane\Imaris 7.5.2`).

MATLAB path setting
-------------------
Alternatively, you could set MATLAB's path to include the **IceImarisConnector**
directory. To do this, open MATLAB and use the `Set Path...` entry in the `File`
menu. In the dialog, click on `Add Folder...` and add the path to your git clone
(e.g. `C:\Devel\IceImarisConnector`).
