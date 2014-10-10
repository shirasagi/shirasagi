module Uploader::Node
  class Base
    include Cms::Node::Model

    default_scope ->{ where(route: /^uploader\//) }
  end

  class File
    include Cms::Node::Model

    default_scope ->{ where(route: "uploader/file") }
  end
end
