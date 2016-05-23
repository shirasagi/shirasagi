module Sys::SiteCopy::Roles
  extend ActiveSupport::Concern

  private
    def copy_roles
      #権限複製：OK
      cms_roles = Cms::Role.where(site_id: @site_old.id).order('updated ASC')
      new_cms_roles_id = {}
      cms_roles.each do |cms_role|
        new_cms_role = Cms::Role.new cms_role.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_role.site_id = @site.id
        begin
          new_cms_role.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
        new_cms_roles_id.store(cms_role.id, new_cms_role.id)
      end

      #ユーザへ新規権限付与：OK
      new_cms_roles_id.each do |old_role_id, new_role_id|
        cms_users = Cms::User.where(cms_role_ids: old_role_id)
        cms_users.each do |cms_user|
          cms_user.cms_role_ids = cms_user.cms_role_ids.push(new_role_id)
          begin
            cms_user.save!
          rescue => exception
            Rails.logger.error(exception.message)
            throw exception
          end
        end
      end
    end
end
