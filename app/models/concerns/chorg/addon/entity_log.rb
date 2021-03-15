module Chorg::Addon::EntityLog
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    after_destroy :delete_entity_log
    has_one :cached_entity_logs, class_name: "Chorg::EntityLogCache", dependent: :destroy, inverse_of: :task
  end

  def entity_log_path
    "#{SS::File.root}/chorg_tasks/" + id.to_s.split(//).join("/") + "/_/entity_logs.log"
  end

  def cache_entity_log
    return if cached_entity_logs.present?

    Chorg::EntityLogCache.destroy_all
    item = Chorg::EntityLogCache.new

    file_logs = []
    if ::File.exists?(entity_log_path)
      ::File.foreach(entity_log_path) do |line|
        file_logs << JSON.parse(line)
      end
    end

    sites = {}
    file_logs.each_with_index do |item, i|
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
      label = "#{I18n.t("mongoid.models.#{model.underscore}", default: "-")}(#{item["model"]})"

      sites[entity_site]["models"] ||= {}
      sites[entity_site]["models"][entity_model] ||= {
        "label" => label,
        "count" => 0
      }
      sites[entity_site]["models"][entity_model]["count"] += 1

      # entity
      id = item["id"]
      entity_index = (i + 1).to_s
      title = item["name"] || "#{model}(#{entity_index})"
      model_label = "#{I18n.t("mongoid.models.#{model.underscore}", default: "-")}(#{item["model"]})"
      class_label = "#{I18n.t("mongoid.models.#{item["class"].underscore}", default: "-")}(#{item["class"]})"

      sites[entity_site]["models"][entity_model]["items"] ||= {}
      sites[entity_site]["models"][entity_model]["items"][entity_index] = item
      sites[entity_site]["models"][entity_model]["items"][entity_index]["title"] = title
      sites[entity_site]["models"][entity_model]["items"][entity_index]["model_label"] = model_label
      sites[entity_site]["models"][entity_model]["items"][entity_index]["class_label"] = class_label
    end

    item.task = self
    item.logs = file_logs
    item.sites = sites
    item.save!
  end

  def entity_logs
    cache_entity_log
    cached_entity_logs.logs
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
    cache_entity_log
    cached_entity_logs.sites
  end

  def create_entity_log_sites_zip(site, user, base_url)
    output_zip = SS::DownloadJobFile.new(user, "entity_logs-#{Time.zone.now.to_i}.zip")
    output_dir = output_zip.path.sub(::File.extname(output_zip.path), "")

    root_path = ::File.join(output_dir, revision.name)
    Fs.mkdir_p(root_path)

    entity_log_sites.each do |entity_site, sites|
      label = sites["label"]
      models = sites["models"]

      models.each do |entity_model, model|
        items = model["items"]

        path = ::File.join(root_path, label)
        Fs.mkdir_p(path)

        csv = items_to_csv(site, items, base_url, entity_site, entity_model)
        Fs.write(::File.join(path, "#{entity_model}.csv"), csv)
      end
    end

    Zip::File.open(output_zip.path, Zip::File::CREATE) do |zip|
      Dir.glob("#{root_path}/**/*").each do |file|
        name = file.gsub("#{root_path}/", "")
        zip.add(name.encode('cp932', invalid: :replace, undef: :replace, replace: "_"), file)
      end
    end
    output_zip.path
  end

  def items_to_csv(site, items, base_url, entity_site, entity_model)
    url_helper = Rails.application.routes.url_helpers
    rid = revision.id
    type = (name == "chorg:main_task") ? "main" : "test"

    csv = CSV.generate do |line|
      line << %w(区分1 区分2 タイトル ID 操作 確認URL 管理URL)
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

        change_label = ""
        if item['creates']
          change_label = I18n.t('chorg.views.chorg/entity_log.options.operation.creates')
        elsif item['changes']
          change_label = I18n.t('chorg.views.chorg/entity_log.options.operation.changes')
        elsif item['deletes']
          change_label = I18n.t('chorg.views.chorg/entity_log.options.operation.deletes')
        end

        row = []
        row << item["model_label"]
        row << item["class_label"]
        row << item["name"]
        row << item["id"]
        row << change_label
        row << url
        row << mypage_url
        line << row
      end
    end
    csv = "\uFEFF".freeze + csv
    csv
  end

  def init_entity_logs
    ::FileUtils.rm_f(entity_log_path)
    dirname = ::File.dirname(entity_log_path)
    ::FileUtils.mkdir_p(dirname) if !Dir.exists?(dirname)

    @entity_log_file = ::File.open(entity_log_path, 'w')
    @entity_log_file.sync = true

    cached_entity_logs.destroy if cached_entity_logs
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

  def embedded_array_fields
    @_embedded_array_fields ||= begin
      SS.config.chorg.embedded_array_fields.presence || []
    end
  end

  def embedded_array_changes(entity)
    return {} if !entity.respond_to?(:column_values)

    hash = {}
    embedded_array_fields.each do |field_name|
      next if !entity.respond_to?(field_name)

      changes = entity.send(field_name).map(&:changes)
      next if !changes.select(&:present?).first

      hash[field_name] = changes
    end
    hash
  end

  def entity_model(entity)
    (entity.try(:base_model) || entity.class).name
  end

  def store_entity_changes(entity, site)
    if entity.persisted?
      changes = entity.changes.except('_id', 'created', 'updated')
      changes = changes.merge(embedded_array_changes(entity))

      hash = { 'id' => entity.id.to_s, 'model' => entity_model(entity), 'class' => entity.class.name, 'changes' => changes }
    else
      creates = entity.attributes.except('_id', 'created', 'updated')
      hash = { 'model' => entity_model(entity), 'class' => entity.class.name, 'creates' => creates }
    end

    hash['site'] = { 'id' => site.id, 'model' => entity_model(site), 'class' => site.class.name, 'name' => site.name } if site
    hash["name"] = entity.try(:name)
    hash['mypage_url'] = entity.try(:private_show_path)

    @entity_log_file.puts(hash.to_json)
  end

  def store_entity_deletes(entity, site)
    deletes = entity.attributes.except('_id', 'created', 'updated')
    hash = { 'id' => entity.id.to_s, 'model' => entity_model(entity), 'class' => entity.class.name, 'deletes' => deletes }

    hash['site'] = { 'id' => site.id, 'model' => entity_model(site), 'class' => site.class.name, 'name' => site.name } if site
    hash["name"] = entity.try(:name)
    hash['mypage_url'] = entity.try(:private_show_path)

    @entity_log_file.puts(hash.to_json)
  end

  def store_entity_errors(entity, site)
    hash = { 'id' => entity.id.to_s, 'model' => entity_model(entity), 'class' => entity.class.name, 'errors' => entity.errors.full_messages }

    hash['site'] = { 'id' => site.id, 'model' => entity_model(site), 'class' => site.class.name, 'name' => site.name } if site
    hash["name"] = entity.try(:name)
    hash['mypage_url'] = entity.try(:private_show_path)

    @entity_log_file.puts(hash.to_json)
  end
end
