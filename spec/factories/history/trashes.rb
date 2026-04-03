FactoryBot.define do
  factory :history_trash, class: History::Trash do
    cur_site { cms_site }
  end

  # factory :history_trash_cms_page, class: History::Trash do
  #   cur_site { cms_site }
  #   ref_coll { "cms_pages" }
  #   ref_class { "Cms::Page" }
  #   data do
  #     item = build(:cms_page, cur_site: cur_site)
  #     item.validate!
  #     item.attributes
  #   end
  # end
  #
  # factory :history_trash_cms_node do
  #   cur_site { cms_site }
  #   ref_coll { "cms_nodes" }
  #   ref_class { "Cms::Node" }
  #   data do
  #     item = build(:cms_node, cur_site: cur_site)
  #     item.validate!
  #     item.attributes
  #   end
  # end
end
