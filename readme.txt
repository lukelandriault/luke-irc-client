Welcome!
Thank you for using my IRC Client. This readme will explain how to utilize all of the features found in LIC.
Please remember I only wrote the program to satisfy my needs for a windows IRC client,
so this may not be for everyone ;P

Checkout this page for new versions, source code, & anything else LIC related:
http://code.google.com/p/luke-irc-client/

 ___ Mouse functions ___

Right Click - Rearrange tabs / Copy the message under the mouse to the clipboard
Shift + RClick - Save the current clipboard and add a message to it (used to copy more than 1 message)
Left Click - Any text that's 'Link Colour' to either launch the hyper link or join the channel
Middle Button - Activate mouse scroller
Mouse Wheel - Scroll up/down
Left drag - Select text (no visual cue) on the chat window to then be copied (hold shift to append)

Linux note: copy paste requires 'xclip' to be installed on your system

 ___ Keyboard functions ___

Esc - Leave the current room (Used to close private conversations as well)
F1 - Display's a short help reference in the chat window
F2 - Toggle notifications (Taskbar Flashing)
F3 - Toggle time stamps on/off
F4 - Clear the outbound message Queue (if you pasted something big by mistake)
F5 - Toggle join/leave on/off
F6 - Toggle hostname display on user join
F7 - Reload LIC Options & Settings
F8 - Clear the current room's window of all chat messages
CTRL + V - Paste text
CTRL + Tab - Switch to the next room
SHIFT + Tab - Switch to the previous room
CTRL + Left/Right - Switch to active rooms
PgUp/Down - Scroll up/down 1 page
CTRL + PgUp/Down - Scroll to the top/bottom of the backlog

 ___ Chat Input Controls (Basic) ___

   _ Usage _              _ Description [ alias ] _
/time <user>            Send a CTCP Time request to user [/t]
/ping <user>            Send a CTCP Ping request to user [/p]
/version <user>         Send a CTCP Version request to user [/v /ver]
/me <msg>               Send a CTCP ACTION message to the channel [/em /action /emote]
/msg <user> <msg>       Send a Private Message to <user> [/m /pm /w /message /privmsg /whisper /query]
/quit <msg>             Quit IRC with an optional message [/q]
/ignore                 Display your ignore list [/squelch]
/ignore <user>          Add someone to the ignore list [/squelch]
/unignore <user>        Remove someone from the ignore list [/unsquelch]
/?                      Display more advanced commands that use /

 ___ IRC Options Help ___

This is a description of all the variables, the default value is stored inside [ ]
Multiple option choices will be inside ( )
Any on/off options will take [1, yes, y] for ON  |  [0, n, no] for OFF
Variables marked with ^ are required to use LIC.
Variables marked with % require a restart to change.
Variables marked with @ are advanced, and should not be changed unless you are sure.
note: All spaces are removed and case is ignored for variable name checking ( ie: LogToFile = LOG TO FILE )



- Global Vars (effect all servers) -

Alias
   Set custom aliases for commands. ie:
   Alias p part
   Alias a = alias
   Now /a will call /alias & /p will call /part

Always On Top % [0]
   Window will start with 'Always On Top' enabled
   
Auto Ghost [0]
   Auto "/message nickserv GHOST <nick> <pass>"
   if your nick is in use 
   
Auto Reconnect [1]
   Reconnect if the connection is lost 
   
Auto Rejoin On Ban [0]
   Interval in seconds to keep trying JOIN #channel
   after you're banned (0 disabled)
   
Auto Rejoin On Kick [3]
   Wait this long in seconds to rejoin after you've
   been kicked (0 disabled, -1 for instantly)
   
Bit Depth % [16]
   Bits per pixel, while 8 will give the best speed &
   lowest memory usage, 32 looks the best (8,16,32)
   
Browser Path [firefox]
   (linux only) When you click on hyperlinks they will
   be launched using this command
   
ChatBox Font [System]
   Font to use for the main chat window
   May need to use the full path to the .ttf file
   
ChatBox Font Size [8]
   Size for ChatBoxFont

[Config = #]
   Use [CONFIG = #] to seperate server sections and their
   options (only needed if you connect to multiple servers)

CTCP Ignore Multi [0]
   Ignore CTCP commands not directly sent to you
   Ex: PRIVMSG #channel :\x01PING\x01
   
CTCP Version [LIC version & webpage]
   The reply to CTCP protocol 'VERSION'
   
DCC port [13000]
   Starting port to listen on for incoming dcc connections

DCC Passive [0]
   Use reverse dcc connections, use this if you cannot open
   a port

Disable Emac Controls [0]
   Disables emacs shortcuts for editing the text input
   keys like ctrl-w ctrl-a ctrl-e
   
Disable Quick Copy [0]
   With quick copy enabled, selected text on the chat
   window will automatically be copied to the clipboard
   Set this to 1 to disable this action
   
Font Render [Win32: WinAPI | Linux: FreeType]
   Method to render fonts ( FBGFX, FreeType, WinAPI ) 
   WinAPI is only available on Windows. FreeType requires
   both freetype & zlib libs to be installed on your system

Hide Taskbar % [0]
   Used with 'MinimizeToTray'
   Do not display on the taskbar while restored
   
Ident Enable [0]
   Enable an ident server 'spoof' when connecting
   
Ident Port @ [113]
   Port for ident to listen on, almost all irc
   servers will probe port 113
   
Ident System @ [Unix]
   Ident system response
   
Ident User [LICUser]
   Ident user reponse

[Linux]
   Global Linux options, useful for sharing a config file
   between windows and linux   

Log To File % [0]
   Log your chat sessions to hard drive
   Log files are saved in the 'log' directory by default
   
Log Buffer Size [0]
   Maximum amount of memory (in kB) to use as a buffer
   (0 = disabled)

Log TimeOut [300]
   How many seconds since the last log buffer write to
   initiate a new one, no matter how much is in the buffer
   
Log Merge PM [0]
   Merge all private conversation on each server into
   1 logfile, instead of 1 file per user
   
Log Join Leave [1]
   Have join/part/quit messages written to log files
   
Log Lobby [1]
   Write the Lobby Room to file
   Server messages, Welcome, MOTD etc

Log Raw [1]
   If 'ShowRaw' is enabled, log it also to file 'raw log.log'
   
Log Load History [0]
   Number of lines to display in each channel from the last
   session logs
   
Log Max File Size [0]
   Maximum filesize in KB for each log file, 0 for no limit
   
Log Max File Action [copy]
   Action to take when max size is reached ( copy, prune )
   Copy will rename the current file & start a new logfile
   Prune will resize the log to 75% of LogMaxFileSize
   discarding the oldest chat

Max BackLog [2000]
   Max amount of lines to keep displayed per room
   
Minimize To Tray % [0]
   Minimize puts the window on the taskbar's system tray
   Win32 only at the moment
   
Min Per Line [0.5]
   Minimum number of seconds inbetween each line print
   Prevent a high number of prints during netsplits etc
   
Notify On Chat [1]
   Flashes the taskbar whenever a chat message is displayed
   in any channel
   
Notify Sound []
   Specify a sound to notify you with
   win32 only, must be .wav
   
Quit Message [LIC Client Version]
   Message added to your QUIT command upon leaving a server
   
ScreenResX [800]
   Width in pixels of the window
   
ScreenResY [600]
   Height in pixels of the window
   
Show CTCP [0]
   Show CTCP messages sent to your client from others
   ie: PING, VERSION, TIME

Show Date Change [1]
   Display a message in every room upon a new day
   ie: ** Day changed to: Mon Jul 23 2012
   
Show Hostnames [0]
   Display other's hostname in the join message when they
   join a channel
   
Show Inactive [0]
   Update the window when not focused
   
Show Join Leave [1]
   Display a message whenever a user joins/leaves a channel
   
Show MOTD [0]
   Display the Message of the day in the lobby upon
   connecting to the server

Show Privs [0]
   Prepend nicks with their privs on the chat display
   ie [ @nick ]: hi, i have ops 
   
Show Server Users [0]
   Display a server's users count messages
   
Show Server Welcome [0]
   Option to display the welcome messages upon connecting
   
Show Time Stamp [1]
   Prepend messages with the current system time
   
Show Topic Updates [1]
   Display all channels topic whenever changed

Show Raw [0]
   Create 1 room per server that shows raw irc in/out

Smooth Scroll [0]
   Adds a smooth scrolling effect to the chat box
   
Sort By Privs [1]
   Users with more priviledges will be sorted above
   those without any or of lesser value

Sort Tab By Activity [1]
   Tab completion will be sorted by user activity
   instead of the userlist order

Switch On Join [1]
   Automatically change the current room to the channel you JOINed
   
System Tray Colour % [blue]
   Colour of the system tray blink when you're hi-lited
   (blue, green or red)

TimeStampFormat [(hh:mm:ss) ]
   Customize the timestamp to fit your liking
   to see the codes look under Date-Time formats:
   http://www.freebasic.net/wiki/wikka.php?wakka=KeyPgFormat

TimeStampUseCRT [0]
   use the C Runtime lib's strftime instead
   explaination of the format codes here:
   http://man7.org/linux/man-pages/man3/strftime.3.html   

User List Font [System]
   Font to use for the User List display
   May need to use the full path to the .ttf file
   
User List Font Size [8]
   Size for the UserListFont
   
User List Width % [90]
   Width in pixels of the user list display box

[Windows]
   Global Windows options, useful for sharing a config file
   between windows and linux


- Server Vars (can be set different for each server) -


Auto Exec []
   These will be performed each time following a successful
   connection to the irc server (can have multiple entries)
   
   Example:
   AutoExec = auth username password

Auto Join []
   Auto join these channels once your logged in
   Seperated by space, ex: #Ubuntu #FreeNode
   
Auto Pass []
   This is for servers that use the nickserv service
   Auto "/message nickserv identify <pass>" with this
   
Channel %
   Set channel specific options, only the options shown in
   the example are currently available
   
   Example:
   Channel = #ubuntu
      ShowJoinLeave = no
      NotifyOnChat = no
      Key = Secret
   End Channel
   Channel = #ubuntu #freenode
      LogToFile = yes
      ShowHostnames = yes
   End Channel
   
   Notes:
   Key is for channels protected with a passkey ( +k )
   You must end each group of settings with a "End Channel"
   like shown above

DCC Auto Accept [0]
   Automatically accept dcc requests from everyone,
   or a mask list (off, on, list)
   
DCC Auto List []
   Mask list used for DCC Auto Accept
   Use format nick!ident@hostname, wildcards * accepted
   
Hostname [*]
   Hostname to report to the server, most servers will look
   it up
   
ID Service @ [NickServ]
   Which service bot to whisper when identifying your nick
   
Ignore List []
   Users to ignore all messages from use format
   nick!ident@hostname, wildcards * accepted
   
Log Folder
   Directory to save log files
   Defaults to the Server variable
   
Nick Name [Guest]
   Your Nickname to use while chatting
   
Password [*]
   Used with password protected IRC networks/bouncers
   This is not your nickserv password
   
Port @ [6667]
   Port of the IRC Server
   
Real Name [*]
   Can be anything, will be visible via /whois to others

Script File []
   Parse a seperate file for scripts
   Scripts available:
   
   filter: filter messages from being displayed in the gui
      filter <host> <command> [ param1 ... ]
      ie: prevent join messages from bob
         filter bob!*@*bobs.isp join
      ie: prevent +v messages in #mychan
         filter * mode #mychan +v
      ie: prevent any messages from someone
         filter *!*@*their.isp *
      
      available commands:
         join quit part privmsg notice nick mode kick
         * denotes all commands
         
   wordfilter: filter matching privmsgs (case insensitive)
      wordfilter <host> <match string>
      ie: do not display messages from bob with 'apple'
         wordfilter bob!*@*bobs.isp apple
      ie: do not display messages with 'blue berry'
         wordfilter * blue berry
   
   wordmatch: perform action(s) if a word match is found
      wordmatch <host> <action1|action2> <match string>
      ie: notify when anyone says bob
         wordmatch * notify bob
      ie: notify and hilite when fred says hi bob
         wordmatch fred!*@* notify|hilite hi bob

Server ^ []
   The IRC Server hostname or IP to connect to
   
User Name [Guest]
   Used with password protected IRC networks
   will be shown in your WHOIS   



- Custom Colours -
    The colours are values 0-255 in the order of Red, Green, Blue ( RRR, GGG, BBB )
        Ex: TextColour = 205, 205, 205
    All colour variables are global and used on all servers

Text Colour - Main colour for most chat messages [200, 200, 200]
Your Chat Colour - The Colour of your name and some messages [218, 218, 218]
Join Colour - User joining the room messages will use this colour [16, 255, 16]
Leave Colour - User leaving '' [160, 32, 32]
Server Message Colour - Any server messages will use this colour [0, 128, 234]
ScrollBar Background Colour - Colour of the Scrollbar background [32, 16, 48]
Link Colour - Colour for any clickable links to launch websites or join channels [64, 96, 200]
Tab Colour - Colour used by the inactive tabs at the top [128, 128 , 128]
Tab Active Colour - Colour used by the tab for the current room [192, 192, 192]
Tab Text Colour - Colour for the text on the tabs [0, 0, 200]
Tab Text Notify Colour - Colour for the text on the tabs when there has been new messages [200, 0, 0]
Tab Flash Colour - Colour for the tab while flashing [255, 255, 255]
HiLite Colour - Colour to hilite your name if said [64, 255, 64]
Chat History Colour - For displaying logs from previous sessions [128, 128, 128]
Raw Input Colour - If 'ShowRaw' is on, messages from the server will be this colour [48, 212, 48]
Raw Output Colour - If 'ShowRaw' is on, messages to the server will be this colour [212, 48, 48]

 __ Technical Details __

Coded with FreeBASIC and compiled with the FreeBASIC Compiler.
http://www.freebasic.net

Libs used: chiSock to handle all of the network I/O, FBGFX for display, FreeType for font rendering.
chiSock is a great socket library for FreeBASIC that was written by cha0s.
More info & updates on chiSock can be found at this forum post: http://www.freebasic.net/forum/viewtopic.php?t=8454
Info about the FreeType library can be found at http://freetype.sourceforge.net/

To compile the program from source open a shell in the src directory then..

Win32:
fbc -mt -s gui -d __LIC__=-1 -m lic lic*.bas lic.rc -i chisock -p chisock/lib/win32 -x ../bin/lic.exe

Linux32:
fbc -mt -d __LIC__=-1 -m lic lic*.bas lic.xpm -i chisock -p chisock/lib/linux -x ../bin/lic

 __ Trouble shooting __

"I'm unable to start LIC on Linux, it's saying cannot find libtinfo5.so?"
   If you're on linux and you're unable to get libtinfo5.so, this library is just a split of ncurses and
   I've seen a simple `cd /lib32; ln -s libncurses.so.5 libtinfo.so.5` enable LIC to start.

 __ Thank You __

I'd like to thank Mysoft for font renderer, RGB8, his ASM functions & all his help with WinAPI.
Also a big thanks to nkk for the .ico graphics along with all his testing & feature requests >:)
Many thanks to cha0s for chiSock, without it I probably wouldn't have started coding LIC.
And thanks to everyone involved with FreeBASIC =] keep up the good work.

 __ Contact __

If you'd like to report a bug, request a feature, or anything else.
You can contact me at lukelandriault@gmail.com
This email isn't checked everyday, but I will get back to you in good time :P
