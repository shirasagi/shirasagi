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

    self.use_liquid = false

    default_scope ->{ where(route: "opendata/dataset") }

    def condition_hash(options = {})
      # サイト内の全ページが対象
      default_site = options[:site] || @cur_site || self.site
      { site_id: default_site.id } # TODO:
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
    include Cms::Addon::NodeList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/dataset_group") }

    def condition_hash(options = {})
      # サイト内の全ページが対象
      default_site = options[:site] || @cur_site || self.site
      { site_id: default_site.id } # TODO:
    end

    def sort_options
      Opendata::DatasetGroup.sort_options.push([I18n.t('opendata.sort_options.count_desc'), 'count -1'])
    end

    def sort_hash
      return { name: 1 } if sort.blank?
      { sort.sub(/ .*/, "").to_s => (sort.end_with?('-1') ? -1 : 1) }
    end
  end

  class App
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    self.use_liquid = false

    default_scope ->{ where(route: "opendata/app") }

    def condition_hash(options = {})
      # サイト内の全ページが対象
      default_site = options[:site] || @cur_site || self.site
      { site_id: default_site.id } # TODO:
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

    self.use_liquid = false

    default_scope ->{ where(route: "opendata/idea") }

    def condition_hash(options = {})
      # サイト内の全ページが対象
      default_site = options[:site] || @cur_site || self.site
      { site_id: default_site.id } # TODO:
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

  class DatasetCounter
    include Cms::Model::Part
    include Opendata::Addon::CounterHtml
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "opendata/dataset_counter") }
  end
end
