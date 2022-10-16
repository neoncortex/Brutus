.so macros.s

.TL
Brutus text editor user guide:
.
.NH
Why?
.LP
Inspired by
.B Sam ,
and
.B Acme ,
from
.B "Plan 9"
operating system, my intent is to have an interface that allows system commands, and line the editor
.B ed ,
to edit text.
Insted of hard code in the text editor operations such as text substitution, searching, and so on, these operations are delegated to system commands.
This give the user a huge flexibility in it's editing operations, and avoid code duplication.
.
.NH
Why the name?
.LP
Because it's barebones.
There is no syntax, no bells, and it does not do much besides presenting, and organizing text, text files and windows.
It's brute.
.
.NH
The Brutus interface:
.LP
.PSPIC -C img/brutus.ps 5i 5i
.
.LP
The main interface consists of two text areas, and some buttons.
The text area on top is the
.I "command area" .
This is where commands are inserted.
The buttons on the top control, and execute actions based on the content, or text selection, in the command area.
.
.NH 2
The Menu:
.LP
.PSPIC -C img/menu.ps 3i 3i
.
.LP
The Menu allows the user to do the most basic operations, like open files, navigate between the windows, save, etc.
.
.NH 2
The Cmd button:
.LP
This button execute a shell command from the command area.
.
.NH 2
The Ed button:
.LP
This button execute an
.B ed
command from the command area.
.
.NH 2
The Stop button:
.LP
The Stop button stop the execution of a running command.
.
.NH 2
The Clear button:
.LP
The Clear button wipes the text from the command area.
.
.NH 2
The Result button:
.LP
The Result button place the last result of a command in the command area.
.
.NH 2
The Last button:
.LP
The Last button place the last executed command on the command area.
.
.NH 2
The Match button:
.LP
The Match button match a selection from the command area on the text.
.
.NH 2
The Open Button:
.LP
The Open Button open files from the selected filenames in the command area.
.
.NH 2
The Show Button:
.LP
The Show Button redirects the result of the commands to the command area, instead of applying in the text.
.
.NH 2
The Keep Button:
.LP
The Keep Button prevents the contents of the command area to be erased between commands.
.
.NH
The command area:
.LP
.PSPIC -C img/commandarea.ps 5i 5i
.
.LP
This is where commands are inserted, and executed.
Commands can be of two types:
.IP \[bu]
System commands
.IP \[bu]
Ed commands
.LP
.
The
.I Cmd
button execute system commands, and the
.I Ed
button executes \F[C]ed\F[] commands.
Examples will be given in the next sections.
.
.NH
View results of commands:
.
.LP
For example, given that you have a file opened, let's say
.I /etc/lynx/lynx.cfg .
Write in the command area \F[C]ls\F[], check the
.I Show
button, and click run.
You should see this:
.PSPIC -C img/ls-result.ps 5i 5i
.
.NH
Substitute text using commands:
.
.LP
Let's say, in the same file, you want to replace
.I default
with
.I Default .
You can use an Ed command like this:
.CODE
,s/default/Default
.CODEE
.
.LP
To do that:
.IP \[bu]
clear the command area pressing the Clear button, if there's text there
.IP \[bu]
uncheck the Show button, if it's on
.IP \[bu]
type \F[C],s/default/Default\F[] in the command area
.IP \[bu]
click the Ed button
.
.LP
You should see this:
.PSPIC -C img/substitution.ps 5i 5i
.
.LP
Notice the word default, on line 3, that's now capitalized.
This is a trivial example, but you can do more, for example, lets say we want to insert
.I Reminder
before each line that containd the word Default.
We can use another Ed command:
.CODE
/g/Default/\\\\
i\\\\
Reminder
.CODEE
You should see this:
.PSPIC -C img/g.ps 5i 5i
.
.NH
Opening files from results of commands:
.
.LP
You can highlight filenames in the command area, and click the Open button.
This will open the files for editing.
.
.NH
Match line numbers or strings from results of commands:
.LP
Let's say you are editing an
.I Objective-C
.m file, and you want to navigate quickly around.
You can use
.B grep ,
like this:
.CODE
grep -n '^[+-]'
.CODEE
.
.LP
Type this in the command area, enable Show, and click Cmd.
You should see this:
.PSPIC -C img/navigation.ps 5i 5i
.
.LP
From there, you can highlight a line number (the number before \F[C]:\F[]), or the line contents (the string after \F[C]:\F[]), and click match.
You should see this:
.PSPIC -C img/navigation2.ps 5i 5i
.
.LP
Where I selected \F[C]68\F[] in the commabd area, and clicked the Match button.
.
.NH
The client:
.LP
In the directory
.I BrutusClient ,
there is an application that allows you to open files from command line, scripts, etc.
After installed, it can be used like the following:
.CODE
openapp BrutusClient /path/to/file/name
.CODEE
.
.LP
To open the file in a specific line number, let's say, 10, use:
.CODE
openapp BrutusClient /path/to/file/name:10
.CODEE
.
.LP
To open the file and search for a string, use:
.CODE
openapp BrutusClient /path/to/file/name:string
.CODEE
