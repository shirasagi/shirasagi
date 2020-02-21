module Recommend
  class Initializer
    Cms::Node.plugin "recommend/receiver"
    Cms::Part.plugin "recommend/history"
    Cms::Part.plugin "recommend/similarity"
  end
end
