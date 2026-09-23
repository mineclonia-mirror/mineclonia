# Common Mineclonia library functions

## Compatibility functions

### `mcl_util.log_deprecated_call(level, moreinfo)`
  Writes a luanti-style deprecation message to the log.
  When called from a function, it writes to the log the name of the function,
  stating it as a deprecated function, followed by the filename and the line
  number of the function calling the deprecated function.
  If a second argument is given, it is written to next line in the log after
  the deprecation message. This can be used to point to specifics of any
  updated APIs.

#### Arguments:
  level: log level, defaults to "warning".
  moreinfo: optional extra informative message.


### mcl_util.luanti_minimum_version(version)
  Tests if the version of luanti the server is running is equal to or newer
  than specified version string.
  Note that specifying a version below 5.11.0 or a version that is not an
  index in the `core.protocal_versions` table (eg 5.15.2) returns `false`.
  Returns a boolean.

#### Arguments:
  version: luanti version string.
