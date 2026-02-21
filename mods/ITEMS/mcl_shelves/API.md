## Shelves API

### Functions:
`mcl_shelves.register_shelf(name, def)`: Register a new shelf. The `name` parameter must be a string that will be used as part of the shelf itemstring, registered as
```lua
"mcl_shelves:"..name
```
`def` must be a table containing node definitions, such as description, tiles, groups and others. Some parameters are defined by the API (models, drawtype, paramtypes, some groups) and can be overrided using `def`.
