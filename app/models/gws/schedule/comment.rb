class Gws::Schedule::Comment
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Schedule
  include SS::Addon::Markdown
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_schedule_plans'
end
