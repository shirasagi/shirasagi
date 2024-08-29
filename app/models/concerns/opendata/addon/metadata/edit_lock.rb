module Opendata::Addon::Metadata::EditLock
  extend SS::Addon
  extend ActiveSupport::Concern

  def metadata_locked?
    metadata_importer
  end

  def allowed?(action, user, opts = {})
    if !%w(edit delete).include?(action.to_s)
      return super
    end

    site = opts[:site] || @cur_site
    foribity_edit = user.cms_role_permit_any?(site, "edit_other_opendata_metadata")

    if metadata_locked? && !foribity_edit
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
      foribity_edit = user.cms_role_permit_any?(site, "edit_other_opendata_metadata")

      if foribity_edit
        return criteria
      else
        return criteria.where(:metadata_importer_id.exists => false)
      end
    end
  end
end
