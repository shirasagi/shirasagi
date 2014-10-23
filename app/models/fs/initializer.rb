module Fs
  class Initializer
    require "yaml"
    file = File.expand_path('../../config/environment.yml', __FILE__)
    env  = File::exist?(file) ? YAML.load_file(file) : {}
    type = env["storage"] || "file"

    if type == "grid_fs"
      Fs.include Fs::GridFs
    else
      Fs.include Fs::File
    end
  end
end
