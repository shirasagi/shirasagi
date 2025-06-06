module Gws::Affair2::SubGroupPermission
  extend ActiveSupport::Concern
  include SS::Permission

  #def allowed?(action, cur_user, site:, cur_group:)
  #  allowed_group_ids = self.class.allowed_groups(action, cur_user, site: site, cur_group: cur_group).pluck(:id)
  #  allowed_group_ids.include?(group.id)
  #end

  module ClassMethods
    def allowed_private?(action, cur_user, site:, cur_group:)
      permits = []
      permits << "#{action}_private_#{permission_name}"
      permits << "#{action}_sub_#{permission_name}"
      permits << "#{action}_all_#{permission_name}"
      cur_user.gws_role_permit_any?(site, *permits)
    end

    def allowed_sub?(action, cur_user, site:, cur_group:)
      permits = []
      permits << "#{action}_sub_#{permission_name}"
      permits << "#{action}_all_#{permission_name}"
      cur_user.gws_role_permit_any?(site, *permits)
    end

    def allowed_all?(action, cur_user, site:, cur_group:)
      permits = []
      permits << "#{action}_all_#{permission_name}"
      cur_user.gws_role_permit_any?(site, *permits)
    end

    # active
    def allowed_groups(action, cur_user, site:, cur_group:)
      conds = []
      if allowed_all?(action, cur_user, site: site, cur_group: cur_group)
        conds << { name: /^#{::Regexp.escape(site.name)}(\/|$)/ }
      elsif allowed_sub?(action, cur_user, site: site, cur_group: cur_group)
        cur_user.groups.each do |item|
          conds << { name: /^#{::Regexp.escape(item.name)}(\/|$)/ }
        end
      elsif allowed_private?(action, cur_user, site: site, cur_group: cur_group)
        conds << { id: cur_group.id }
      else
        conds << { id: -1 }
      end
      Gws::Group.and({ "$or" => conds })
    end
  end
end
