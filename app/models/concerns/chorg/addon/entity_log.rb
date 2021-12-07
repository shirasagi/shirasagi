module Chorg::Addon::EntityLog
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    after_destroy :delete_entity_log
  end

  def entity_log_path
    "#{SS::File.root}/chorg_tasks/" + id.to_s.chars.join("/") + "/_/entity_logs.log"
  end

  def entity_sites_path
    "#{SS::File.root}/chorg_tasks/" + id.to_s.chars.join("/") + "/_/entity_sites.log"
  end

  def entity_logs
    @entity_logs ||= begin
      logs = []
      if ::File.exist?(entity_log_path)
        ::File.foreach(entity_log_path) do |line|
          logs << JSON.parse(line)
        end
      end
      logs
    end
  end

  def entity_sites
    @entity_sites ||= begin
      if ::File.exist?(entity_sites_path)
        JSON.parse(Fs.read(entity_sites_path))
      else
        create_entity_sites
      end
    end
  end

  def create_entity_sites
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

    if state == "completed"
      Fs.write(entity_sites_path, sites.to_json)
    end

    sites
  end

  def init_entity_logs
    ::FileUtils.rm_f(entity_log_path)
    ::FileUtils.rm_f(entity_sites_path)

    dirname = ::File.dirname(entity_log_path)
    ::FileUtils.mkdir_p(dirname) if !Dir.exist?(dirname)

    @entity_log_file = ::File.open(entity_log_path, 'w')
    @entity_log_file.sync = true
  end

  def finalize_entity_logs
    @entity_log_file.close if @entity_log_file
  end

  def delete_entity_log
    ::FileUtils.rm_f(entity_log_path)
    ::FileUtils.rm_f(entity_sites_path)
  end

  def embedded_array_fields
    @_embedded_array_fields ||= begin
      SS.config.chorg.embedded_array_fields.presence || []
    end
  end

  def embedded_array_changes(entity)
    hash = {}
    embedded_array_fields.each do |field_name|
      next if !entity.respond_to?(field_name)

      embedded_array = entity.send(field_name).map(&:changes)
      next if !embedded_array.select(&:present?).first

      embedded_array.each_with_index do |embedded, idx|
        embedded.each do |key, changes|
          hash["#{field_name}.#{idx}.#{key}"] = changes
        end
      end
    end
    hash
  end

  def entity_model(entity)
    (entity.try(:base_model) || entity.class).name
  end

  def entity_log_url(entity_site, entity_model, entity_index)
    url_helper = Rails.application.routes.url_helpers
    type = (name =~ /main_task$/) ? "main" : "test"
    url_helper.show_entity_chorg_entity_logs_path(
      site: revision.site_id, rid: revision.id, type: type,
      entity_site: entity_site,
      entity_model: entity_model,
      entity_index: entity_index
    )
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
