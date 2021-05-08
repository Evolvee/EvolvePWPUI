FocusFrame -- Created by Tageshi


---------------------------------------------------------------
1. WHAT IS "FocusFrame"?
---------------------------------------------------------------

FocusFrame is very simple addon to show your focus.

The frame looks almost exactly same as Blizzard's TargetFrame;
It provide following features.
- Click to target your focus or your focus's target.
- Shows your focus's health and mana.
- Shows your focus's target.
- Shows cast bar of your focus.
- Supports Click-Casting such as Clique addon by utilizing ClickCastFrames.
- Movable by dragging the title tab.
- Supports MobHealth.


---------------------------------------------------------------
2.  WHAT IS "focus"?
---------------------------------------------------------------


The "focus" is a new feature of WoW API 2.0.
Basically you can use "focus" as a second target.
It works in similar way as your real Target 
and allows you to use DOUBLE targets at the same time. (essentially)

From API 2.0 Changes:
> * There is a new unit "focus" which behaves like target, 
> the "PLAYER_FOCUS_CHANGED" event is fired when it is changed, 
> and you receive unit events for this unit. 

> * Spell casting and targetting (including focus) are only allowed 
> using secure templates or special slash commands (not /script). 



---------------------------------------------------------------
3.  HOW TO USE "focus"?
---------------------------------------------------------------


You can set "focus" by using new standard Keybinding "Focus Target" or 
by using new macro command "/focus" with target name or target id.
Another new standard keybindings "Target Focus" will change your target 
to your focus. For example, you don't need to remember which mob is 
your "sheep" to poly again.

Also you can use a keyword "focus" as a target id like "player", 
"target", "party2", etc.

Example1: You can assist your focus by this macro.

    /assist focus

You may want to focus your main tank/main assist if you will do DPS.
Or focus raid boss and 'assist' it if you are healing.


Example2: You can cast your Earth Shock on your focus by this macro.

    /cast [target=focus] Earth Shock

You can watch spell casting bar on FocusFrame.


---------------------------------------------------------------
4.  COMMANDS
---------------------------------------------------------------

FocusFrame has a few slash commands;

/focusframe scale <num>        (Changes size of FocusFrame window.)
/focusframe reset              (Reset window position.)
/focusframe lock               (Prevent dragging the frame by accident.)
/focusframe unlock             (Allows to move again.)

If your screen space is limited, try smaller window size:
/focusframe scale 0.7

When you accidently lost FocusFrame from your sight, reset it's 
position and FocusFrame will appear again at the center of screen.


---------------------------------------------------------------
5.  CHANGES
---------------------------------------------------------------

Version 2.3.6
TOC updated for WoW 2.4 .

Version 2.3.5
Fixed slash command "/focusframe hidewhendead" so that it respects Saved Variables.
Restored dependency on the standard Interface option "Show Enemy Cast Bar".
(which I removed hastily on version 2.3.4 .)
 
Version 2.3.4
Added slash command "/focusframe hidewhendead" to toggle the new function introduced on 2.3.3 .
Suports WoW patch 2.4 PTR.

Version 2.3.3
Added additional condition so that FocusFrame will be hidden only when focused target is dead AND is enemey.

Version 2.3.2
FocusFrame will be hide when focused target is dead.(Finally!)
Added warning message for when too big scale argument is passed for /focusframe scale command.
Added warning message for when user tried to change frame scale in combat.

Version 2.3.1
Fixed broken MobHealth support.

Version 2.3.0   (<- Skipped 2.2.0 to avoid confusion)
Updated for WoW client version 2.3 .

Version 2.2.1   (<- oops, this is typo.  This version is actuallly 2.1.1)
Fixed a potential nil error.

Version 2.1.0
Updated for WoW client version 2.2.0 .
Added slash commands /focusframe lock and /focusframe unlock.

Version 2.0.2
Fixed a bug; tooltip of buff/debuff icons were not correctly updated. (Thanks to Alestane)

Version 2.0.1
Fixed a nil concatenate error at line 852. (Thanks to JMHammer)

Version 2.0
Mimics new Target frame of WoW client 2.1 ;
  Displays maximum 32 buff icons.
  Displays buff/debuff timer.
Mobhealth support added.

Version 1.3
Added slash command /focusframe reset -- which reset window position to center of screen.
Supported silver dragon decoration for rare-elite mobs.

Version 1.2
Added slash command /focusframe scale <num> -- which changes size of FocusFrame.

Version 1.1
Fixed broken initialization. FocusFrame window is now really displayed.

Version 1.0
First release. But initialization was broken.
