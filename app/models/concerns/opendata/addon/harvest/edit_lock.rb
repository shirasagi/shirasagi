module Opendata::Addon::Harvest::EditLock
  extend SS::Addon
  extend ActiveSupport::Concern

  def harvest_locked?
    harvest_importer
  end

  def allowed?(action, user, opts = {})
    if !%w(edit delete).include?(action.to_s)
      return super
    end

    site = opts[:site] || @cur_site
    foribity_edit = user.cms_role_permit_any?(site, "edit_other_opendata_harvested")

    if harvest_locked? && !foribity_edit
      return false
    else
      return super
    end
  end

  module ClassMethods
    def allow(action, user, opts = {})
      criteria = super

      if !%w(edit delete).include?(action.to_s)
        return criteria
      end

      site = opts[:site] || @cur_site
      foribity_edit = user.cms_role_permit_any?(site, "edit_other_opendata_harvested")

      if foribity_edit
        return criteria
      else
        return criteria.where(:harvest_importer_id.exists => false)
      end
    end
  end
end
