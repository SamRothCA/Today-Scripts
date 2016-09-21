##  Today-Scripts (custom scripts in your notification bar. This fork has a fix for macOS Sierra, tested on **10.12.0**)  

### Clone and compile yourself *(tested to work with Xcode 8 target platform 10.12 or 10.11)*

If you don't want to compile this yourself, nor clone the repo to get the binary in the `build` dir  

or download the binary **.app* or **.zip**. You can **download the binary** from [Today Scripts.app zipped to 168K](https://github.com/lsd/Today-Scripts/raw/master/build/Today%20Scripts.app.zip) or view the [build/ for the uncompressed bin @ 389K](https://github.com/lsd/Today-Scripts/tree/master/build) dir. 

## Still having issues with running this on Sierra?  

:warning: **If you're still having problems running Today-Scripts on Sierra, [please read https://github.com/SamRothCA/Today-Scripts/issues/24#issuecomment-160041420](https://github.com/SamRothCA/Today-Scripts/issues/24#issuecomment-160041420)**


**A widget for running custom scripts in the Today View in OS X Yosemite's and El Capitan's and Sierra's Notification Center.**

Original links and text preserved:  

- [Latest build here from original repo (does not contain **.app** binary and as of now does not work out of the box for Sierra)](https://github.com/SamRothCA/Today-Scripts/releases)
- [See the wiki for a list of example scripts.](https://github.com/SamRothCA/Today-Scripts/wiki)

###Features

* [Colorized Output](http://i.imgur.com/Yvj2ePG.png). Today Scripts supports colorized terminal output from your scripts, as well as bold and underline.
* [Custom Labels](http://i.imgur.com/LL4s6Ao.png). Today Scripts has a form for setting up scripts, which gives you the option of picking a label to display instead of the script itself.
* Custom Interpreters: When setting up a script, you may specify any program to run in place of your shell. This means you can directly run scripts in Python, Perl, AppleScript, etcetera, simply by specifying their associated interpreter.
* Manually Run Scripts: Scripts may be run on command by clicking on their label. You may also specify that scripts not be run automatically when Notification Center is opened.
* Output text selection: You may highlight the output of your scripts, allowing you to copy it to the clipboard or drag it where you please.

##Usage

After building, simply copy "Today Scripts.app" wherever you'd like to store it, then open it. In Notification Center, you will see "1 New" appear on the edit button, and you may use that to add Today Scripts to your Today View in order to begin using it.

To begin editing your list of scripts, click the "Info" symbol in the title of the widget.

To start or stop a given script on demand, click its label in your list.

To edit an existing script, click the "action" button to the right of its label.

##Technical Details

* An interpreter can be speficied using a path to any valid executable (it need not be an "interpreter" at all). The provided script is piped to the interpreter via its standard input.
* Today Scripts emulates a 40-column terminal. When running a script, a pseudo-TTY is opened for it, and the standard output and standard error of it is set to that. The `COLUMNS` environment variable for scripts is set to `40`, and `PAGER` is set to `/bin/cat`.
* Today Scripts supports all ANSI color sequences; both standard and bright, as well as both foreground and background. The `TERM` environment variable for scripts is set to `ansi`.

