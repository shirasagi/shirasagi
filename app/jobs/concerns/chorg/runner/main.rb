module Chorg::Runner::Main
  extend ActiveSupport::Concern

  private

  def save_or_collect_errors(entity)
    if entity.valid?
      task.store_entity_changes(entity)
      entity.save
      true
    else
      entity.errors.full_messages.each do |message|
        put_error(message.to_s)
      end
      task.store_entity_errors(entity)
      false
    end
  rescue ScriptError, StandardError => e
    Rails.logger.fatal("got error while saving #{entity.class}(id = #{entity.id})")
    raise
  end

  def delete_entity(entity)
    task.store_entity_deletes(entity)
    if @item.disable_if_possible? && (user_like?(entity) || group_like?(entity))
      entity.disable
    else
      entity.delete
    end
  end

  def move_users_group(from_id, to_id)
    substituter = self.class.id_substituter_class.new(from_id, to_id)
    with_entities([self.class.user_class]) do |user|
      old_ids = user.group_ids
      old_names = user.groups.pluck(:name).join(",")
      new_ids = substituter.call(:group_ids, user.group_ids, to_id)
      if old_ids != new_ids
        user.group_ids = new_ids
        save_or_collect_errors(user)
        new_names = user.groups.pluck(:name).join(",")
        put_log("moved user's group name=#{user.name}, from=#{old_names}, to=#{new_names}")
      end
    end
  end

  def user_like?(entity)
    entity.class.ancestors.include?(SS::Model::User)
  end

  def group_like?(entity)
    entity.class.ancestors.include?(SS::Model::Group)
  end

  def import_user_csv
    if self.class.ss_mode == :gws
      import_user_csv_gws
    else
      import_user_csv_cms
      import_content_csv_cms
    end
  end

  def import_user_csv_cms
    return if @item.user_csv_file.blank?

    put_log("#{@item.user_csv_file.humanized_name}: import users from csv")

    user = Cms::User.new(cur_site: site, cur_user: user, in_file: @item.user_csv_file.uploaded_file)
    result = user.import

    task.log("==ユーザーインポート==")
    if result
      task.log("  #{@item.user_csv_file.humanized_name}: #{user.imported} ユーザーをインポートしました。")
    else
      task.log("  #{@item.user_csv_file.humanized_name}: 次のエラーが発生しました。\n#{user.errors.full_messages.join("\n")}")
    end
  end

  def import_content_csv_cms
    return if @item.content_csv_file.blank?

    put_log("#{@item.content_csv_file.humanized_name}: import contents from csv")

    # user = Cms::User.new(cur_site: site, cur_user: user, in_file: @item.user_csv_file.uploaded_file)
    # result = user.import

    task.log("==コンテンツインポート==")
    Cms::AllContentsImportJob.bind(site_id: site).perform_now(@item.content_csv_file_id)
  end

  def import_user_csv_gws
    return if @item.user_csv_file.blank?

    put_log("#{@item.user_csv_file.humanized_name}: import users from csv")

    importer = Gws::UserCsv::Importer.new(cur_site: site, cur_user: user, in_file: @item.user_csv_file.uploaded_file)
    result = importer.valid?
    if result
      result = importer.import
    end

    task.log("==ユーザーインポート==")
    if result
      task.log("  #{@item.user_csv_file.humanized_name}: #{importer.imported} ユーザーをインポートしました。")
    else
      task.log("  #{@item.user_csv_file.humanized_name}: 次のエラーが発生しました。\n#{importer.errors.full_messages.join("\n")}")
    end
  end
end
