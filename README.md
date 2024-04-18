# bookmarks-persistence.yazi

A [Yazi](https://github.com/sxyazi/yazi) plugin that Supports persistent bookmark management.No bookmarks are lost after you close yazi.

inspired by [bookmarks](https://github.com/dedukun/bookmarks.yazi)

> [!NOTE]
> The latest main branch of Yazi is required at the moment.


https://github.com/DreamMaoMao/bookmarks-persistence.yazi/assets/30348075/473ff20c-1d31-4816-84dd-c19912d1d8c9


## Installation

```sh
# Linux/macOS
git clone https://github.com/DreamMaoMao/bookmarks-persistence.yazi.git ~/.config/yazi/plugins/bookmarks-persistence.yazi

# Windows
git clone https://github.com/DreamMaoMao/bookmarks-persistence.yazi.git $env:APPDATA\yazi\config\plugins\bookmarks-persistence.yazi
```

## Usage

Add this to your `keymap.toml`:

```toml
[[manager.prepend_keymap]]
on = [ "u", "a" ]
exec = "plugin bookmarks-persistence --args=save"
desc = "Save current position as a bookmark"

[[manager.prepend_keymap]]
on = [ "u", "g" ]
exec = "plugin bookmarks-persistence --args=jump"
desc = "Jump to a bookmark"

[[manager.prepend_keymap]]
on = [ "u", "d" ]
exec = "plugin bookmarks-persistence --args=delete"
desc = "Delete a bookmark"

[[manager.prepend_keymap]]
on = [ "u", "D" ]
exec = "plugin bookmarks-persistence --args=delete_all"
desc = "Delete all bookmarks"
```
