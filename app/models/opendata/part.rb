module Opendata::Part
  class MypageLogin
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/mypage_login") }
  end

  class Dataset
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/dataset") }

    def condition_hash
      {} # TODO:
    end

    def sort_options
      Array(Opendata::Dataset.sort_options).concat(super)
    end

    def sort_hash
      Opendata::Dataset.sort_hash(sort)
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
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/dataset_group") }

    def condition_hash
      {} # TODO:
    end
  end

  class App
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/app") }

    def condition_hash
      {} # TODO:
    end

    def sort_options
      Array(Opendata::App.sort_options).concat(super)
    end

    def sort_hash
      Opendata::App.sort_hash(sort)
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
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/idea") }

    def condition_hash
      {} # TODO:
    end

    def sort_options
      Array(Opendata::Idea.sort_options).concat(super)
    end

    def sort_hash
      Opendata::Idea.sort_hash(sort)
    end

    def sort_criteria
      Opendata::Idea.sort_criteria(sort)
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
