#> Use RbConfig instead of obsolete and deprecated Config.
Object.send :remove_const, :Config
Config = RbConfig
