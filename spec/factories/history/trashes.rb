FactoryBot.define do
  trait :history_trash do
    cur_site { cms_site }
    cur_user { cms_user }
    ref_coll { "cms_pages" }
    ref_class { "Cms::Page" }
    data { build(:cms_page).attributes }
    state { 'closed' }
  end

  factory :history_trash, class: History::Trash, traits: [:history_trash] do
    factory :history_trash_cms_node do
      ref_coll { "cms_nodes" }
      ref_class { "Cms::Node" }
      data { build(:cms_node).attributes }
    end
  end
end
