# v0.1 baseline

`package.sha256` is the SHA-256 of every file a v0.1 install has, exactly as the release shipped it (made by
`release/make_release_true165.py`). Later versions are patches built against it: the patcher checks a player's
files against it, or against the newest released version of a file, before it changes anything. A file that
matches neither was changed on that PC, and the patch stops instead of overwriting it.

Never edit this file. Each later release gets its own folder.
