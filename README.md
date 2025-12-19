# LinkDiscoveryTShark
This is a Powershell script that was put together for the purpose of detecting the network device using Npcap and TShark then presenting the information in a browser.

## Prerequisites
* [Wireshark](https://www.wireshark.org/)
  * [Npcap](https://npcap.com/#download)
  * TShark
 
## LinkDiscoveryTShark

### What it does
The `.ps1` and `.bat` were both uploaded for simple download and go. Download both to the same location, run `Link-Discovery-TShark.bat` as an admin and it'll start `Link-Discovery-TShark.ps1`.

Powershell should pop-up and ask you which network adapter you'd like to use. It'll listen for 60 seconds due to some devices only broadcasting in that interval. The data captured will be put into a variable and organized to fit an HTML format.

This creates a file on your desktop and opens automatically once completed. This file can be copied or shared to those that need the information.

### Run directly from PowerShell
To run the script without saving the files use:

```ruby
irm "https://raw.githubusercontent.com/enchap/LinkDiscoveryTShark/refs/heads/main/Link-Discovery-TShark.ps1" | iex
```
