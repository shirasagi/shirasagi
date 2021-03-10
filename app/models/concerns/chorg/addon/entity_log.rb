module Chorg::Addon::EntityLog
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    after_destroy :delete_entity_log
  end

  def entity_log_path
    "#{SS::File.root}/chorg_tasks/" + id.to_s.split(//).join("/") + "/_/entity_logs.log"
  end

  def entity_logs
    @entity_logs ||= begin
      logs = []
      if ::File.exists?(entity_log_path)
        ::File.foreach(entity_log_path) do |line|
          logs << JSON.parse(line)
        end
      end
      logs
    end
  end

  def create_entity_log_sites_zip(base_url)
    root_path = "#{Rails.root}/soshiki_#{Time.zone.now.to_i}"

    entity_log_sites.each do |entity_site, sites|
      label = sites["label"]
      models = sites["models"]

      models.each do |entity_model, model|
        items = model["items"]

        path = ::File.join(root_path, label)
        Fs.mkdir_p(path)

        csv = items_to_csv(items, base_url, entity_site, entity_model)
        Fs.write(::File.join(path, "#{entity_model}.csv"), csv)
      end
    end
  end

  def items_to_csv(items, base_url, entity_site, entity_model)
    url_helper = Rails.application.routes.url_helpers
    rid = revision.id
    type = (name == "chorg:main_task") ? "main" : "test"

    csv = CSV.generate do |line|
      line << %w(model name url mypage_url)
      items.each do |entity_index, item|
        url = ::File.join(
          base_url,
          url_helper.show_entity_chorg_entity_logs_path(
            site: site.id, rid: rid, type: type,
            entity_site: entity_site,
            entity_model: entity_model,
            entity_index: entity_index
        ))
        mypage_url = (item["mypage_url"].present? ? ::File.join(base_url, item["mypage_url"]) : "")

        row = []
        row << item["model"]
        row << item["name"]
        row << url
        row << mypage_url
        line << row
      end
    end
    csv = "\uFEFF".freeze + csv
    csv
  end

  def entity_log_sites
    @entity_log_sites ||= begin
      sites = {}
      entity_logs.each_with_index do |item, i|
        # sites
        site = item["site"]
        if site
          id    = site["id"]
          model = site["model"]
          name  = site["name"]
        else
          id    = 0
          model = "SS"
          name  = "共通"
        end

        entity_site = "#{id}_#{model.gsub("::", "").underscore}"
        label = "#{id}_#{name}"

        sites[entity_site] ||= {
          "label" => label,
          "count" => 0
        }
        sites[entity_site]["count"] += 1

        # models
        model = item["model"]
        entity_model = model.gsub("::", "").underscore

        sites[entity_site]["models"] ||= {}
        sites[entity_site]["models"][entity_model] ||= {
          "model" => model,
          "count" => 0
        }
        sites[entity_site]["models"][entity_model]["count"] += 1

        # entity
        id = item["id"]
        entity_index = (i + 1).to_s
        title = item["name"] || "#{model}(#{entity_index})"

        label = ""
        if item['creates']
          label += I18n.t('chorg.views.chorg/entity_log.options.operation.creates')
        elsif item['changes']
          label += I18n.t('chorg.views.chorg/entity_log.options.operation.changes')
        elsif item['deletes']
          label += I18n.t('chorg.views.chorg/entity_log.options.operation.deletes')
        end

        sites[entity_site]["models"][entity_model]["items"] ||= {}
        sites[entity_site]["models"][entity_model]["items"][entity_index] = item
        sites[entity_site]["models"][entity_model]["items"][entity_index]["label"] = label
        sites[entity_site]["models"][entity_model]["items"][entity_index]["title"] = title
      end
      dump(sites)
      sites
    end
  end

  def init_entity_logs
    ::FileUtils.rm_f(entity_log_path)
    dirname = ::File.dirname(entity_log_path)
    ::FileUtils.mkdir_p(dirname) if !Dir.exists?(dirname)

    @entity_log_file = ::File.open(entity_log_path, 'w')
    @entity_log_file.sync = true
  end

  def finalize_entity_logs
    @entity_log_file.close if @entity_log_file
  end

  def delete_entity_log
    ::FileUtils.rm_f(entity_log_path)
  end

  def overwrite_fields
    %w(contact_tel contact_fax contact_email contact_link_url contact_link_name)
  end

  def store_entity_changes(entity, site)
    if entity.persisted?
      changes = entity.changes.except('_id', 'created', 'updated')
      overwrite_fields.each do |k|
        changes[k] ||= [entity[k], entity[k]] if entity.respond_to?(k)
      end
      hash = { 'id' => entity.id.to_s, 'model' => entity.class.name, 'changes' => changes }
    else
      creates = entity.attributes.except('_id', 'created', 'updated')
      hash = { 'model' => entity.class.name, 'creates' => creates }
    end

    hash['site'] = { 'id' => site.id, 'model' => site.class.name, 'name' => site.name } if site
    hash["name"] = entity.try(:name)
    hash['mypage_url'] = entity.try(:private_show_path)

    @entity_log_file.puts(hash.to_json)
  end

  def store_entity_deletes(entity, site)
    deletes = entity.attributes.except('_id', 'created', 'updated')
    hash = { 'id' => entity.id.to_s, 'model' => entity.class.name, 'deletes' => deletes }

    hash['site'] = { 'id' => site.id, 'model' => site.class.name, 'name' => site.name } if site
    hash["name"] = entity.try(:name)
    hash['mypage_url'] = entity.try(:private_show_path)

    @entity_log_file.puts(hash.to_json)
  end

  def store_entity_errors(entity, site)
    hash = { 'id' => entity.id.to_s, 'model' => entity.class.name, 'errors' => entity.errors.full_messages }

    hash['site'] = { 'id' => site.id, 'model' => site.class.name, 'name' => site.name } if site
    hash["name"] = entity.try(:name)
    hash['mypage_url'] = entity.try(:private_show_path)

    @entity_log_file.puts(hash.to_json)
  end
end
