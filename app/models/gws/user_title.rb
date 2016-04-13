class Gws::UserTitle
  include SS::Model::UserTitle
  include Gws::SitePermission

  set_permission_name "gws_user_titles", :edit

  attr_accessor :cur_user, :cur_site

  before_validation :set_group_id, if: ->{ cur_site.present? }
  after_save :update_users_title_order

  scope :site, ->(site) { where group_id: site.id }

  private
    def set_group_id
      self.group_id = cur_site.id
    end

    def update_users_title_order
      return if self.order_was.nil?
      Gws::User.update_all_title_orders(self)
    end
end
