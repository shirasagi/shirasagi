module Sys::SiteCopy::CmsRoles
  extend ActiveSupport::Concern

  def copy_cms_roles
    role_dic = {}
    cms_roles = Cms::Role.where(site_id: @src_site.id).order_by(updated: 1)
    cms_roles.each do |cms_role|
      begin
        Rails.logger.debug("#{cms_role.name}(#{cms_role.id}): 権限/ロールのコピーを開始します。")
        new_cms_role = Cms::Role.new cms_role.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_role.site_id = @dest_site.id
        new_cms_role.cur_site = @dest_site
        new_cms_role.save!
        role_dic[cms_role.id] = new_cms_role.id
        @task.log("#{cms_role.name}(#{cms_role.id}): 権限/ロールをコピーしました。")
      rescue => e
        @task.log("#{cms_role.name}(#{cms_role.id}): 権限/ロールのコピーに失敗しました。")
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end

    #ユーザへ新規権限付与：OK
    Cms::User.all.each do |cms_user|
      begin
        Rails.logger.debug("#{cms_user.name}(#{cms_user.id}): ユーザーの権限をコピーします。")

        add_role_ids = cms_user.cms_role_ids.map { |role_id| role_dic[role_id] }
        add_role_ids.compact!
        cms_user.cms_role_ids = cms_user.cms_role_ids + add_role_ids
        cms_user.save!
        @task.log("#{cms_user.name}(#{cms_user.id}): ユーザーの権限をコピーしました。")
      rescue => e
        @task.log("#{cms_user.name}(#{cms_user.id}): ユーザーの権限のコピーに失敗しました。")
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end
end
