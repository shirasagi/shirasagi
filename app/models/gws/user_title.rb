class Gws::UserTitle
  include SS::Model::UserTitle
  include Gws::SitePermission

  set_permission_name "gws_user_titles", :edit

  attr_accessor :cur_user, :cur_site

  before_validation :set_group, if: ->{ cur_site.present? }

  scope :site, ->(site) { where group_id: site.id }

  private
    def set_group
      self.group_id = cur_site.id
    end
end
