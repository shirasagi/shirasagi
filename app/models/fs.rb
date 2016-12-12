module Fs
  if SS.config.env.storage == "grid_fs"
    include ::Fs::GridFs
  else
    include ::Fs::File
  end
end
