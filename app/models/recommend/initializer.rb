module Recommend
  class Initializer
    Cms::Part.plugin "recommend/history"
    Cms::Part.plugin "recommend/similarity"
  end
end
