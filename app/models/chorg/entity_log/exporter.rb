class Chorg::EntityLog::Exporter
  attr_reader :path, :filename

  def initialize(task, site, base_url)
    @task = task
    @revision = task.revision
    @site = site
    @base_url = base_url
  end

  def create_zip(user)
    output_zip = SS::DownloadJobFile.new(user, "entity_logs-#{Time.zone.now.to_i}.zip")
    output_dir = output_zip.path.sub(::File.extname(output_zip.path), "")

    root_path = ::File.join(output_dir, @revision.name)
    Fs.mkdir_p(root_path)

    @task.entity_sites.each do |entity_site, sites|
      label = sites["label"]
      models = sites["models"]

      models.each do |entity_model, model|
        items = model["items"]
        csv = items_to_csv(entity_site, entity_model, items)

        path = ::File.join(root_path, label)
        Fs.mkdir_p(path)
        Fs.write(::File.join(path, "#{entity_model}.csv"), csv)
      end
    end

    Zip::File.open(output_zip.path, Zip::File::CREATE) do |zip|
      Dir.glob("#{root_path}/**/*").each do |file|
        name = file.gsub("#{root_path}/", "")
        zip.add(name.encode('cp932', invalid: :replace, undef: :replace, replace: "_"), file)
      end
    end

    @path = output_zip.path
    @filename = ::File.basename(output_zip.path)
  end

  private

  def items_to_csv(entity_site, entity_model, items)
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |line|
        line << I18n.t("chorg.entity_log.headers")
        items.each do |entity_index, item|
          url = ::File.join(@base_url, @task.entity_log_url(entity_site, entity_model, entity_index))
          mypage_url = (item["mypage_url"].present? ? ::File.join(@base_url, item["mypage_url"]) : "")

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
    end
    csv = "\uFEFF".freeze + csv
    csv
  end
end
