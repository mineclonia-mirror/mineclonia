# `mcl_difficulty`

## `mcl_difficulty.difficulties`

List of availlable difficulties.

Currently `{"peaceful", "easy", "normal", "hard"}`

## `mcl_difficulty.get_difficulty()`

Get the difficulty.

Returns "peaceful", "easy", "normal" or "hard".

## `mcl_difficulty.set_difficulty(difficulty)`

Set the difficulty.

difficulty: "peaceful", "easy", "normal" or "hard"

## `mcl_difficulty.register_on_difficulty_change(function(old_difficulty, new_difficulty))`

Register a function that will be called when `mcl_difficulty.set_difficulty` is called.

## `mcl_difficulty.registered_on_difficulty_change`

Map of registered on_difficulty_change.
