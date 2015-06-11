module Uploader::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^uploader\//) }
  end

  class File
    include Cms::Model::Node

    default_scope ->{ where(route: "uploader/file") }
  end
end
