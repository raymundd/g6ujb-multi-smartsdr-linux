# g6ujb-wine-flex-tools

This is a collection of tools that I use to manage instances of SmartSDR on Linux running under Wine.

Some scripts that allow you to run multiple copies of FlexRadio's SmartSDR.

The current limitation with SmartSDR is that it only has a single configuration file called SSDR.settings and although you can
launch multiple copies of SmartSDR it only has the single instance of the file available to retain settings, so each
instance reads and writes to this file.

These scripts tried to overcome this problem by moving copies of the SSDR.settings file into place before launching the instance
of SmartSDR.

## Starting multiple instances of SmartSDR with a pre-determined unique STATION name

### Background

When SmartSDR launches it gets parameters from the file %APPDATA%\FlexRadio Systems\SSDR.settings, this defines many things which includes the last known STATION name and radio serial number. By making use of multiple copies of this file it is possible to force the STATION name each time that SmartSDR launches to a pre-determined name for each instance.

> **Please be aware that this is not a perfect solution, it works for my situation.**

### Getting things setup

1. Start an instance of SmartSDR and connect to your first FlexRadio.

        ./start_smartsdr_v2.sh

2. Set the STATION name by double clicking the textbox near the **"STATION:"** label located at lower middle of the main window, press "Enter" when name is complete. e.g. **RADIO_1**
3. Under the SmartSDR settings menu, disable the options "Autostart CAT with SmartSDR" and "Autostart DAX with SmartSDR". (Only do this if you are going to use nCAT and nDAX).
4. Exit the running SmartSDR - this is necessary to ensure settings are written back to persistent storage.
5. Make a copy of the SSDR.settings file.

        cp /home/${SDR_USER}/radiotools/drive_c/users/${SDR_USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings ~/Flexradio/RADIO1.settings        

6. Start SmartSDR again and connect to your other FlexRadio, set the STATION: name to a different name to the first, again make any changes you need to this instance as required, see step 3.

         ./start_smartsdr_v3.sh         

7. Make another copy of the SSDR.settings file.

        cp /home/${SDR_USER}/radiotools/drive_c/users/${SDR_USER}/AppData/Roaming/FlexRadio Systems/SSDR.settings ~/Flexradio/RADIO2.settings

8. Exit this instance of SmartSDR.

## Switching the SmartSDR STATION name

Now changing the STATION name to alternative pre-determined named can be achieved by just copying the settings file with the STATION name you want back as %APPDATA%\FlexRadio Systems\SSDR.settings.

These scripts automatically do the copying of the SSDR.setting files you created above into place and launch SmartSDR.exe using wine.

### PLEASE BE AWARE

> ANY CHANGES TO THE SSDR.SETTINGS FILE THAT ARE NOT APPLIED BY THE SMARTSDR PROGRAM MAY RESULT INCORRECT/UNDESIRED OPERATION OF THE SMARTSDR SOFTWARE PACKAGE OR THE RADIO, IF YOU ARE COMFORTABLE MAKING THESE CHANGES AND UNDERSTAND THE RISKS THEN PLEASE ENJOY THIS INFORMATION, OTHERWISE IT MAY BE SAFER FOR YOU TO WAIT FOR FLEXRADIO SYSTEMS TO REALISE THAT THIS WOULD BE A REALLY USEFUL ADDITION TO THEIR PROVIDED SOFTWARE PACKAGES, ALL CHANGES MADE ARE AT YOUR OWN RISK.
> This method is not perfect because any changes you make to SmartSDR will be overwritten the next time you run this script so, you must remember to re-save the SSDR.settings file to your uniquely named file if you need to retain the changes for a particular instance.
