module SS::Lgwan
  module_function

  def enabled?
    web? || cms?
  end

  def web?
    SS.config.lgwan.mode == "web"
  end

  def cms?
    SS.config.lgwan.mode == "cms"
  end

  def pull_private_files(page)
    files = page.owned_files.map { |file| [file, file.thumb] }.flatten.compact
    return true if files.blank?

    command = SS.config.lgwan.pull_private_files_command
    stdin_data = files.map(&:path).join("\n") + "\n"
    output, error, status = Open3.capture3(command, stdin_data: stdin_data)
    Rails.logger.error("Lgwan Support pull_private_files : #{error}") if error.present?
    error.blank?
  end

  def map_layers
    @_map_layers ||= SS.config.lgwan.map["layers"].to_a
  end

  def map_effective_layers(site)
    if site.map_api_layer.blank?
      layer = map_layers.first
    else
      h = map_layers.index_by { |h| h["name"] }
      layer = h[site.map_api_layer]
    end
    [layer]
  end
end
