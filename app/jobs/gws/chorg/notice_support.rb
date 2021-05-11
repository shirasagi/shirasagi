module Gws::Chorg::NoticeSupport
  extend ActiveSupport::Concern

  def execute_before_gws_notice(changesets)
    return if Gws::Notice::Folder.site(@cur_site).blank?

    task.log("== execute before (gws_notice) ==")

    @foldersets = []
    changesets.each do |changeset|
      case changeset.type
      when "add"
        destination = changeset.destinations.first
        @foldersets << {
          "action" => "create",
          "id" => 0,
          "destination" => destination["name"],
          "groups" => changeset.destinations.map { |destination| destination["name"] }
        }

      when "move"
        source = changeset.sources.first
        entity = find_folder_by_name(source["name"])
        next unless entity

        destination = changeset.destinations.first
        @foldersets << {
          "action" => "move",
          "id" => entity.id,
          "destination" => destination["name"],
          "groups" => changeset.destinations.map { |destination| destination["name"] }
        }

      when "unify"
        source = changeset.sources.first
        entity = find_folder_by_name(source["name"])
        next unless entity

        groups = [source["name"]]
        groups += changeset.destinations.map { |destination| destination["name"] }

        changeset.destinations.each do |destination|
          @foldersets << {
            "action" => "unify",
            "id" => entity.id,
            "destination" => destination["name"],
            "groups" => groups
          }
        end

      when "division"
        source = changeset.sources.first
        entity = find_folder_by_name(source["name"])
        next unless entity

        groups = [source["name"]]
        groups += changeset.destinations.map { |destination| destination["name"] }

        changeset.destinations.each_with_index do |destination, i|
          @foldersets << {
            "action" => ((i == 0) ? "move" : "create"),
            "id" => ((i == 0) ? entity.id : 0),
            "destination" => destination["name"],
            "groups" => groups
          }
        end

      when "delete"
        source = changeset.sources.first
        entity = find_folder_by_name(source["name"])
        next unless entity

        @foldersets << {
          "action" => "delete",
          "id" => entity.id
        }
      end
    end
  end

  def execute_after_gws_notice(changesets)
    return if @foldersets.blank?

    task.log("== execute after (gws_notice) ==")

    @foldersets.each do |item|
      id = item["id"]
      action = item["action"]
      destination = item["destination"]
      group_ids = Gws::Group.in(name: item["groups"]).map(&:id)

      if id.to_i != 0
        entity = find_folder_by_id(id)
        next unless entity
      end
      destination_entity = find_folder_by_name(destination)

      case action
      when "create"
        if destination_entity
          # 移動先フォルダーが既にあるので作成しない
        else
          entity = initialize_folder({
            "name" => destination,
            "member_group_ids" => group_ids,
            "group_ids" => group_ids
          })
          save_or_collect_errors(entity)
        end

      when "move"
        if destination_entity
          if entity.id == destination_entity.id
            # 移動先フォルダーが存在するが、グループ変更前と同じフォルダーなので移動しない
          else
            backup_folder(destination_entity)
            update_folder(entity, {
              "name" => destination,
              "member_group_ids" => group_ids,
              "group_ids" => group_ids
            })
          end
        else
          update_folder(entity, {
            "name" => destination,
            "member_group_ids" => group_ids,
            "group_ids" => group_ids
          })
        end

      when "unify"
        if destination_entity
          # 統合先フォルダーのグループを更新
          group_ids = destination_entity.group_ids + group_ids

          update_folder(destination_entity, {
            "name" => destination,
            "member_group_ids" => group_ids,
            "group_ids" => group_ids
          })

          # 統合先にお知らせを移動
          move_notices(entity, destination_entity)
          entity.folders.each do |folder|
            move_notices(folder, destination_entity)
          end

          # 統合元を削除（バックアップ）
          backup_folder(entity)
        else
          # 統合先フォルダーが存在しないので、作成
          destination_entity = initialize_folder({
            "name" => destination,
            "member_group_ids" => group_ids,
            "group_ids" => group_ids
          })

          if save_or_collect_errors(destination_entity)
            # 統合先にお知らせを移動
            move_notices(entity, destination_entity)
            entity.folders.each do |folder|
              move_notices(folder, destination_entity)
            end

            # 統合元を削除（バックアップ）
            backup_folder(entity)
          end
        end

      when "delete"
        backup_folder(entity)

      end
    end
  end

  def find_folder_by_name(name)
    entity = Gws::Notice::Folder.site(@cur_site).where(name: name).first
    return nil unless entity

    entity.cur_site = @cur_site
    entity.cur_user = (entity.user || @cur_user)
    entity
  end

  def find_folder_by_id(id)
    entity = Gws::Notice::Folder.site(@cur_site).where(id: id).first
    return nil unless entity

    entity.cur_site = @cur_site
    entity.cur_user = (entity.user || @cur_user)
    entity
  end

  def initialize_folder(attributes = {})
    entity = Gws::Notice::Folder.new
    entity.cur_site = @cur_site
    entity.cur_user = @cur_user
    entity.readable_setting_range = "public"

    entity.notice_individual_body_size_limit = SS.config.gws.notice['default_notice_individual_body_size_limit']
    entity.notice_total_body_size_limit = SS.config.gws.notice['default_notice_total_body_size_limit']

    entity.notice_individual_file_size_limit = SS.config.gws.notice['default_notice_total_file_size_limit']
    entity.notice_total_file_size_limit = SS.config.gws.notice['default_notice_total_file_size_limit']

    entity.attributes = attributes
    entity
  end

  def backup_folder(entity)
    @backup_root ||= begin
      backup_root = Gws::Notice::Folder.site(@cur_site).where(name: "backup").first
      backup_root ||= initialize_folder({
        "name" => "backup",
        "readable_setting_range" => "private",
        "member_ids" => [@cur_user.id],
        "user_ids" => [@cur_user.id]
      })
      save_or_collect_errors(backup_root)
    end
    entity.name = "backup/#{entity.name.split("/").last}_#{Time.zone.now.to_i}"
    entity.readable_setting_range = "private"
    entity.member_ids = [@cur_user.id]
    entity.user_ids = [@cur_user.id]
    save_or_collect_errors(entity)
  end

  def update_folder(entity, attributes)
    update(entity, attributes)
    save_or_collect_errors(entity)
  end

  def move_notices(entity, destination_entity)
    entity.notices.each do |notice|
      notice.cur_site = @cur_site
      notice.cur_user = (notice.user || @cur_user)
      notice.folder = destination_entity
      save_or_collect_errors(notice)
    end
  end
end
