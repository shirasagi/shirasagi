#> Use RbConfig instead of obsolete and deprecated Config.
#Object.send :remove_const, :Config if defined? Object::Config
#Config = RbConfig
