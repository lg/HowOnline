# HowOnline <img src='https://raw.githubusercontent.com/lg/HowOnline/master/HowOnline/Assets.xcassets/AppIcon.appiconset/icon64.png' width=32 />
A quick app to display your current ping to google.com or detailed error info (such as not being able to ping 8.8.8.8, being on a self-assigned ip, broken dns, etc)

<sub><sup>**The icon in the middle:**</sup></sub><br/>
<img src='https://raw.githubusercontent.com/lg/HowOnline/master/screenie1.png' width=210 />
<img src='https://raw.githubusercontent.com/lg/HowOnline/master/screenie2.png' width=210 />

### Features
- Monitors WiFi connection for detailed connection information and displays it in your OSX menu bar
- When online, live ping of google.com to ensure connectivity
- Status refreshes automatically on WiFi adapter state change or every 3 seconds
- Optimized for performance and minimal power usage (doesn't unnecessarily check everything every time)
- Support for both Dark and Light menu bars
- Free and opensource (please contribute! also, please verify my Swift design patterns, I'm still learning!)

### Statuses the app will give you
- `wifi if`: Couldn't detect a WiFi interface on your Mac
- `wifi off`: Your WiFi is turned off
- `no ssid`: Either your WiFi is connecting to a network or you're not associated to any network
- `no ip`: You're connected to a network, but you don't have an IP assigned (likely waiting for DHCP)
- `self ip`: You're on a self-assigned IP, DHCP likely not working
- `no gw`: You have a valid IP but no internet gateway was assigned (so you won't have internet access)
- `ping gw`: Failed to ping your internet gateway (usually your router)
- `ping 8.`: Failed to ping 8.8.8.8, one of Google's DNS servers (no DNS lookup is done though)
- `dns`: Failed to do a DNS lookup for google.com
- `ping G`: Unable to ping google.com
- *a number in miliseconds*: Your live ping to google.com

### Still to do
- Tests
- Have an About dialog
- List on the Mac App Store for free

### License
BSD

### Contact
Larry Gadea, trivex@gmail.com

Oh and check out the other thing I work on, [Envoy](https://envoy.co)!
