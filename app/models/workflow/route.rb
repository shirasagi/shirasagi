class Workflow::Route
  include Workflow::Route::Model
  include Cms::Permission

  set_permission_name "cms_users", :edit

  scope :site, ->(site) { self.in(group_ids: Cms::Group.site(site).pluck(:id)) }

  validate :validate_groups

  class << self
    public
      def route_options(user)
        ret = [ [ t("my_group"), "my_group" ] ]
        group_ids = user.group_ids.to_a
        Workflow::Route.where(:group_ids.in => group_ids).each do |route|
          ret << [ route.name, route.id ]
        end
        ret
      end
  end

  private
    def validate_groups
      self.errors.add :group_ids, :blank if groups.blank?
    end
end
