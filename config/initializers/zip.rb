require 'zip'

SS.config.env.zip.tap do |setting|
  Zip.unicode_names = setting ? setting.fetch("unicode_names", true) : true
  Zip.write_zip64_support = setting ? setting.fetch("zip64", true) : true
end
