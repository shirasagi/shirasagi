# coding: utf-8
module Opendata::Part
  class Mypage
    include Cms::Part::Model

    default_scope ->{ where(route: "opendata/mypage") }
  end

  class Dataset
    include Cms::Part::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "opendata/dataset") }

    def condition_hash
      {} # TODO:
    end
  end

  class App
    include Cms::Part::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "opendata/app") }

    def condition_hash
      {} # TODO:
    end
  end

  class Idea
    include Cms::Part::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "opendata/idea") }

    def condition_hash
      {} # TODO:
    end
  end
end
