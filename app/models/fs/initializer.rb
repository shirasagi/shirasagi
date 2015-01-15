module Fs
  class Initializer
    type = SS::Config.env.storage

    if type == "grid_fs"
      Fs.include Fs::GridFs
    else
      Fs.include Fs::File
    end
  end
end
