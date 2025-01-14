# powershell
**Note about these scripts:**
Bunch of nice uncategorized Powershell scripts and snipets

Through the years I've created lots of powershell scripts for
different purposes. This is my first attempt to share
those scripts with people all arround the world.

## Scripts inside this Repository:
- **Delete-LocalProfile** - This script show a GUI with all local profiles and
let you decide what local user profile you like to delete.

- **HR-PassWGenerator** - This script will generate random password(s) of a given length 
and uses a Dutch open Wordlist to generate those passwords so that they are Safe and human readable.
The wordlist is from OpenTaal. For English you could add your own wordlist E.g. [dwyl](https://github.com/dwyl/english-words)

- **MSI-Wrapper** - This script could be used to install an .MSI file from for instance MS SCCM. It
uses a Command file with some variables and runs a Powershell script to install the MSI.

- **Netstat-Connections** - This script run's default Netstat on a Windows Device and converts it to an 
powershellobject. It also adds the process per netstat connection to this object. Then it adds all
connection objects to an array and export it to a Gridview.



## Execution

Enable execution of PowerShell scripts:

    PS> Set-ExecutionPolicy Unrestricted -Scope CurrentUser

Unblock PowerShell scripts and modules within this directory:

    PS> ls -Recurse *.ps*1 | Unblock-File

## Liability

**All scripts are provided as-is and you use them at your own risk.**

## Contribute

I would be happy to extend the collection of scripts. Just open an issue or
send me a pull request.

And If you like you can always [buy me a coffee](https://buymeacoffee.com/ronaldnl76) :) 

### Thanks To
- [OpenTaal](https://github.com/OpenTaal/opentaal-wordlist)

## License

    "THE BEER-WARE LICENSE" (Revision 42):

    As long as you retain this notice you can do whatever you want with this
    stuff. If we meet someday, and you think this stuff is worth it, you can
    buy us a beer in return.

    This project is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.
