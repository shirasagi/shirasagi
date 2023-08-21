class Gws::CacheRebuildJob < Gws::ApplicationJob
  include Job::SS::ComponentSupport

  def perform
    generate_component Gws::Apis::GroupDropdownTreeComponent.new(cur_site: site)
    generate_component Gws::Apis::GroupsComponent.new(cur_site: site, multi: true)
    generate_component Gws::Presence::TreeGroupComponent.new(cur_site: site)
  end
end
