class Zoo::Node::TodayEvent
  include Cms::Model::Node
  include Cms::Addon::NodeSetting
  include Cms::Addon::Meta
  # include Event::Addon::PageList
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  default_scope ->{ where(route: "zoo/today_event") }
end
