module Fs
  class Initializer
    require "yaml"
    file = "#{Rails.root}/config/environment.yml"
    env  = ::File::exist?(file) ? YAML.load_file(file) : {}
    type = env["storage"] || "file"

    if type == "grid_fs"
      Fs.include Fs::GridFs
    else
      Fs.include Fs::File
    end
  end
end
