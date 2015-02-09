module Opendata::Part
  class MypageLogin
    include Cms::Part::Model

    default_scope ->{ where(route: "opendata/mypage_login") }
  end

  class Dataset
    include Cms::Part::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "opendata/dataset") }

    def condition_hash
      {} # TODO:
    end

    def template_variable_get(item, name)
      if name == "point"
        item.point.to_i
      else
        super
      end
    end
  end

  class DatasetGroup
    include Cms::Part::Model
    #include Cms::Addon::NodeList

    default_scope ->{ where(route: "opendata/dataset_group") }

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

    def template_variable_get(item, name)
      if name == "point"
        item.point.to_i
      else
        super
      end
    end
  end

  class Idea
    include Cms::Part::Model
    include Cms::Addon::PageList

    default_scope ->{ where(route: "opendata/idea") }

    def condition_hash
      {} # TODO:
    end

    def template_variable_get(item, name)
      if name == "point"
        item.point.to_i
      else
        super
      end
    end
  end
end
