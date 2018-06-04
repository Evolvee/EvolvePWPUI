Readme.txt for MoveAnything!

MoveAnything! is a mod that lets you move, scale, and hide...well...anything
at all!

To use it, open up your main game menu (by hitting escape until it shows up)
and pushing the MoveAnything! button there, or by using the "/move" command on
the chat entry line.

*** (See Readme) ***
Items with this demarkation in the movable frames list can cause both unintended conditions (such as hiding of dependant children) as well as frame, arithmetic, and scale errors due to themselves or their parent frames not having expected frame attributes.  They are included ONLY for ADVANCED users.  

ALSO NOTE that after actions are taken with MA, a console reload (/console reloadui) may be necessary to see the effects.

***Notes on V2.6 (Release)**
	- changed versioning -
	Added combat awareness
	Disabled SpellBook in combat (haven't found a safe way to call it yet that doesn't involve a taint)
	Fixed Druid/Rogue aura issue
	Added in some more pre-defined frames
	About 30 tweaks and tucks
	

***QUICK REFERENCE***

To show the MA Options window: /move or use the main game menu

Option menu buttons:
Move: Start moving the window.
Hide: click the "Hide" button in the option menu
Reset: Move back to default position

While moving:
Left-Drag in the grey movable area:
	Move the window
Left-Drag in the smaller buttons on the edges:
	Resize the window
Right-Click on the movable area:
	Stop moving
Shift-Right-Click on the movable area or resizing buttons:
	Hide the "Moving XXX window" text and background, while still
	leaving the window available for moving/scaling

Slash Commands:
/move : open the MoveAnything options window
/move framename : move the frame named "framename"
/movelist : list all the valid character specific settings
/movecopy servername playername : copy layout from another character
/movedelete servername playername : delete settings for that character

***MORE DETAILED REFERENCE***

You will then see the MoveAnything! options window, with a list of
things that are predefined as movable.  I've put a good chuck of the default
interface in here, to allow you to move things like the tooltip, the casting
bar, the minimap, your bags, and your action buttons.

To move a window, click on the "Move" checkbox next to the name of the window
you want to move.  A grey area will appear over the top of whatever you're
trying to move, showing you where it is currently, and what it's current size
is.  Note that the window itself doesn't actually have to be visible to be
able to move it, but some windows have some odd positioning (the Player window
is a prime example), so it's easier if the window is visible.  But even if you
only have 2 party members, you can still move all the party member
windows.  To actually move it, just click and drag anywhere in the grey area.

The newly visible grey area has 4 small boxes located in the center of each
edge.  These are the resizing boxes.  Dragging one of those will move that
edge.  I placed the boxes in the center of the edge rather than the corner
because the way scaling works in WoW means that you can only scale
proportionally, so when you drag one direction, the other will scale the
proper amount as well.

Right-clicking the movable area (or unchecking the "Move" box in the
options menu) will complete the movement, locking the window to the location
and scale you left it at.

If you hold shift while right-clicking, the text ("Moving XXX Window") and the
movable background will disappear, giving you a clear view of the thing you're
actually trying to move.  The resizing buttons stay there, and movable area is
still there, so you can drag and right-click to stop moving just as if it were
still there, it's just invisible.

If you want to undo your moving and scaling, just hit the "Reset" button next
to the name on the list.

***INFO PANELS***

The info panels are the two panels that
show up on the left and center of your screen, such as the character info
screen, the tradeskill window, the bank window, and your spellbook.

Most (if not all) of these frames are already defined as movable, and will
show up in your list.  When you move any of these panels, they detach from the
normal panel spaces, meaning that you can have any or all of them on the
screen at one time, but also meaning that you may end up with overlapping
windows.

In addition to the ability to move each info panel independently, you
have the ability to move the panel areas themselves around.  There are two
special items in the list of movable windows called "Info Panel 1" and "Info
Panel 2".  You can move and scale these at will, and the next panel that shows
up in that spot will take the position and size specified.  However, moving
these doesn't affect panels that are currently on the screen, so you're going
to have to close and reopen the panel to see the results.

***VERTICAL BARS***

All of the built-in button bars (action, pet action, bags, micro buttons,
etc) are movable and scalable.  But in the window list, there are two
individual entries that will move each of these bars differently.  Each of
them has a normal setting and a vertical setting.  So, if you want your pet
buttons to be arranged vertically, click the "Move" checkbox next to "Pet
Action Buttons (Vertical)", and your pet buttons will line up one on top of
the other.  At that point, scaling and moving works just like it would
normally.

***BANK BAGS***

Due to some oddities about how the bank works (The game doesn't even know how
many slots each of your bank bags have until you open them), it is
unfortunately necessary to open the bag first, click "Move", clear it, and
click "Move" again to get the proper size locked in.  If you're not at the
bank, or don't want to do this, you can move your bank bag windows
around, but the actual positioning is probably not going to be exactly what
you expect.  Your normal inventory bags don't have these issues, since the
game doesn't try to hide anything about your inventory from you.

***MOVING THINGS NOT IN THE PREDEFINED LIST***

"You said you could move *anything*, but all I see is a predefined list of
things!  Wtf?"

If you want to move anything that's not in the predefined list, you need to
figure out what the name of the frame you want to move is.  Generally you do
this by looking in the .xml file for the addon in question, and trying to
figure out which of the frames defined in there is the one you really want to
use.  For example, if AllInOneInventory wasn't already in the list, you would
go look at AllInOneInventory.xml.  The line you're looking for is going to
look something like this:

	<Button name="AllInOneInventoryFrame" frameStrata="LOW" ...(etc)

except that "Button" is commonly "Frame" as well.

Once you know the name of the frame you want to move, use the /move command on
the chat entry line as follows:

/move AllInOneInventoryFrame

where you, of course, replace "AllInOneInventoryFrame" with the name of the
frame you're trying to move.

From that point on, this new frame will appear in your list, and its position
will be remembered.  If you want to remove the frame from the list, just Reset
it.  (Predefined movables will stay in the list even if you reset them,
though)

***LIVING HAPPILY WITH MOVEANYTHING ON THE MAIN MENU***

There is a function in MoveAnything.lua called GameMenu_AddButton().

You can duplicate this function in your mod (make an exact copy of it.  It's set
up such that it will work correctly no matter how many times, and in how many
different addon files it is duplicated in), call it, and buttons will be added
between the "Macros" and "Logout" button correctly, no matter how many different
mods are trying to do it.  Sorry, this does require other people to change their
mods, but I could not think of any other way to make them all live happily with
MoveAnything.

***KNOWN PROBLEMS***

Due to the somewhat bizzare way WoW handles scaling of UI elements, sometimes
your scaling will get overwritten.  In particular, if you scale a window, and
then later you scale a parent of that window, the child's scale will be
overwritten.  An example of this is the Player and Pet windows.  The pet
window is a child of the player's, so if you scale the pet and then scale the
player, the pet's scale will be overwritten temporarily.

This becomes a fairly large problem when you consider that UIParent is a
parent to EVERYTHING, and that sometimes its scale gets changed.  Most notably
when you tab out or resize your window in windowed mode.

I've added a key binding that you can map to a key (such as Ctrl-Shift-M
maybe) to push when you have issues with scales messing up.  Hopefully it
won't happen too often, but that's the quickest way to fix it.  Reloading your
UI would do the trick as well, but that's sort of a pain in the butt if you
end up having to do it every time you tab out. :)

I'm sure there are other problems that I don't know about.  Feel free to email
bug reports to me at travis_nixon@yahoo.com.
