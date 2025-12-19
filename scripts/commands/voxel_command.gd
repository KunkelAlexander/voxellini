extends RefCounted
class_name VoxelCommand

# Implement the command pattern for an undo/redo functionality
# See: https://gameprogrammingpatterns.com/command.html
# A command is a self-contained description of an edit that knows how to apply itself and how to undo itself.
# A command does not decide when to edit or performs the edit - it just describes how to do the edit
# In the following, we derive from the VoxelCommand class to implement different commands such as a brush stroke

func execute(_terrain):
	push_error("execute() not implemented")

func undo(_terrain):
	push_error("undo() not implemented")
