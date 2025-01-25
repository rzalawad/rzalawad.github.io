---
title: "Adventures in HBA"
permalink: "/adventures-in-hba"
layout: page
---

I ordered an LSI 9206-16e HBA to power my 8x8tb and 8x12tb drives. That is a lot of storage. No, I don't
have a disease 🙃.

My primary goal was to connect the HBA to the PC via a PCIe Gen 3 x4 lane (x16 slot), then connect the
drives to the HBA using SFF-8644 to sata cables.

I bought an [Dell LSI 9206-16e 1V1W2 HBA](https://www.ebay.com/itm/196816910083?mkcid=16&mkevt=1&mkrid=711-127632-2357-0&ssspo=JZcP7KayTEK&sssrc=2047675&ssuid=ofudi9oytdk&widget_ver=artemis&media=COPY) from eBay.

All programs that were used such as `sas2flash`, the firmware files, etc. can be found [here](https://www.broadcom.com/support/download-search?pg=Storage+Adapters,+Controllers,+and+ICs&pf=Storage+Adapters,+Controllers,+and+ICs&pn=SAS+9206-16e+Host+Bus+Adapter&pa=&po=&dk=&pl=&l=true).
Most of these files are zip files and you can find a x86_64 ubuntu version for each program.
You can also get [lsiutil source code](https://ftp.icm.edu.pl/packages/LSI/sw/lsiutil-1.72.tar.gz) and compile it yourself (use the `Makefile_Linux` and run `make -f Makefile_Linux`)

Now that we have our utility programs in order, lets go into issues I encountered.

> The commands I ran solved issues specific to my use case. They might end up bricking your card
> (though that is difficult to do). Run these commands at your own risk!
{: .prompt-warning}


When I plugged in my drives, **no drives showed up**.
But the HBA was showing up using `sas2flash -c 0 list`.

I had watch [this video](https://www.youtube.com/watch?v=nLEVpU8u_Ls) by Art of Server on some specific issues with LSI 9206-16e.
My HBA had the same issue (i.e. the links showed as "off"). But, after resetting to the default settings as shown in the video, the
links were still "off". For some reason, the firmware's default setting was to have the links off
which seemed incorrect.

This made me think that the HBA had the incorrect firmware.
This HBA has 2 controllers. Each controller had version `Firmware Version: 20.00.11.00` retrieved using `sas2flash -c 0 -list`.
However, max supported version on BroadComs's site was `20.00.07.00`

So, I flashed each drive using 
```bash
sas2flash -c 0 -f 9206-16e.bin -b mptsas2.rom
sas2flash -c 1 -f 9206-16e.bin -b mptsas2.rom
```
After this, all the links were set to down!
```bash
root@pop-os:/home/bat# /home/bat/Installer_P20_for_Linux/sas2flash_linux_i686_x86-64_rel/sas2flash -c 1 -o -testlsall
LSI Corporation SAS2 Flash Utility
Version 20.00.00.00 (2014.09.18) 
Copyright (c) 2008-2014 LSI Corporation. All rights reserved 

    Advanced Mode Set

    Adapter Selected is a LSI SAS: SAS2308_2(D1) 

    Executing Operation: Test Link State ALL

    Phy 0: Link Down
    Phy 1: Link Down
    Phy 2: Link Down
    Phy 3: Link Down
    Phy 4: Link Down
    Phy 5: Link Down
    Phy 6: Link Down
    Phy 7: Link Down

    Test Link State All PASSED!

    Finished Processing Commands Successfully.
    Exiting SAS2Flash.
```

But, even after plugging in my drives, they did not show up!

After much searching, I found that my NVDATA version was different for persistsent and
default settings.
```bash
root@pop-os:/home/bat# sas2flash -c 1 -list
LSI Corporation SAS2 Flash Utility
Version 20.00.00.00 (2014.09.18)
Copyright (c) 2008-2014 LSI Corporation. All rights reserved

    Adapter Selected is a LSI SAS: SAS2308_2(D1)

    Controller Number              : 1
    Controller                     : SAS2308_2(D1)
    PCI Address                    : 00:07:00:00
    SAS Address                    : 5000d31-0-0074-4833
    NVDATA Version (Default)       : 14.01.00.06
    NVDATA Version (Persistent)    : 14.01.00.08
    Firmware Product ID            : 0x2214 (IT)
    Firmware Version               : 20.00.07.00
    NVDATA Vendor                  : LSI
    NVDATA Product ID              : SAS9206-16e
    BIOS Version                   : 07.39.02.00
    UEFI BSD Version               : N/A
    FCODE Version                  : N/A
    Board Name                     : SAS9206-16E
    Board Assembly                 : H3-25553-00E
    Board Tracer Number            : SV40206697

    Finished Processing Commands Successfully.
    Exiting SAS2Flash.
```

So I decided to erase the flash using `sas2flash -c 0 -o -e 6` and then reflash the firmware.

> From the docs of `sas2flash -o -h` <br>
> -e x:    Erase selected controller's flash region <br>
> ... <br>
> 6 . . . Clean Flash (erase all except Manufacturing Parameter Block)<br>
> 7 . . . Erase Complete Flash<br>
> -e 7 can remove more information such as manufacturing revision, etc. So best step is to start
> with -e 6 and then perhaps try -e 7
{:.prompt-info}


After erasing the flash, my sas2flash output was like the following
```bash
root@pop-os:/home/bat# sas2flash -c 1 -list
LSI Corporation SAS2 Flash Utility
Version 20.00.00.00 (2014.09.18) 
Copyright (c) 2008-2014 LSI Corporation. All rights reserved 

	Adapter Selected is a LSI SAS: SAS2308_2(D1) 

	Controller Number              : 1
	Controller                     : SAS2308_2(D1) 
	PCI Address                    : 00:07:00:00
	SAS Address                    : 5000d31-0-0074-4833
	NVDATA Version (Default)       : 14.01.00.06
	NVDATA Version (Persistent)    : 14.01.00.06
	Firmware Product ID            : 0x2214 (IT)
	Firmware Version               : 20.00.07.00
	NVDATA Vendor                  : LSI
	NVDATA Product ID              : SAS9206-16e
	BIOS Version                   : 07.39.02.00
	UEFI BSD Version               : N/A
	FCODE Version                  : N/A
	Board Name                     : SAS9206-16E
	Board Assembly                 : H3-25553-00E
	Board Tracer Number            : SV40206697

	Finished Processing Commands Successfully.
	Exiting SAS2Flash.
```

However, my drives STILL weren't showing up!!

So there could be one of two issues:
1. SAS lanes were bad (unlikely since all 16 sas lanes were not working)
2. The cable I was using to connect to the drives were not working

I thought option 2 was also unlikely since I had tried with 4 different SFF-8644 to SATA cables.

[These](https://www.amazon.com/Mini-SFF-8644-Target-SATA-Host/dp/B01BKV4MSS) are the cables I bought.
I had made a glaring mistake and mistakenly climbed Mt. Stupid!!

I needed SFF-8644 Host (plugs into host i.e. HBA/controller) to 4xSATA Target
(plugs into drives). Instead, I had bought SFF-8644 Target (plugs into drives/backplane) to 4xSATA
Host (Controller side) cables.

After I got the correct cables, all the HDDs showed up!

Since I ended up changing the firmware, I'm not sure if the HBA would've worked with the old
firmware. I ended up taking the longest road to get to my destination and, in the process, learned
a lot! I finally have 160TB of storage for my data "needs".
