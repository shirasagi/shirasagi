require 'rss'

class Rss::ImportWeatherXmlJob < Rss::ImportBase
  def initialize(*args)
    super
    set_model Rss::WeatherXmlPage
  end

  class << self
    def pull_all
      SS.config.rss.weather_xml["urls"].each do |url|
        puts "pull from #{url}"
        pull_one(url)
      end
    end

    def pull_one(url)
      http_client = Faraday.new(url: url) do |builder|
        builder.request  :url_encoded
        builder.response :logger, Rails.logger
        builder.adapter Faraday.default_adapter
      end
      http_client.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
      http_client.headers[:accept_encoding] = "gzip"

      resp = http_client.get
      return false if resp.status != 200

      content_encoding = resp.headers["Content-Encoding"]
      if content_encoding.nil?
        body = resp.body
      elsif content_encoding.casecmp("gzip") == 0
        body = Zlib::GzipReader.wrap(StringIO.new(resp.body)) { |gz| gz.read }
      end
      return false if body.blank?

      each_node do |node|
        site = node.site
        next if site.blank?

        puts "-- import into #{node.name}(#{node.filename}) on #{site.name}(#{site.host})"

        file = Rss::TempFile.create_from_post(site, body, resp.headers['Content-Type'].presence || "application/xml")
        job = Rss::ImportWeatherXmlJob.bind(site_id: site, node_id: node)
        job.perform_now(file.id)
      end

      true
    end

    private

    def each_node
      all_ids = Rss::Node::WeatherXml.all.and_public.pluck(:id)
      all_ids.each_slice(20) do |ids|
        Rss::Node::WeatherXml.all.and_public.in(id: ids).to_a.each do |node|
          yield node
        end
      end
    end
  end

  private

  def before_import(file, *args)
    @weather_xml_page = nil
    super

    @cur_file = Rss::TempFile.with_repl_master.where(site_id: site.id, id: file).first
    return unless @cur_file

    @items = Rss::Wrappers.parse(@cur_file)
    @imported_pages = []
  end

  def after_import
    execute_weather_xml_filters

    super

    gc_rss_tempfile
  end

  def gc_rss_tempfile
    return if rand(100) >= 20

    expires_in = SS.config.rss.weather_xml["expires_in"].try { |threshold| SS::Duration.parse(threshold) rescue nil }
    expires_in ||= 3.days
    threshold = Time.zone.now - expires_in
    Rss::TempFile.with_repl_master.lt(updated: threshold).destroy_all
    remove_old_cache(threshold)
  end

  def remove_old_cache(threshold)
    data_dir = SS.config.rss.weather_xml["data_cache_dir"]
    return if data_dir.blank?

    data_dir = ::File.expand_path(data_dir, Rails.root)
    ::Dir.glob(%w(*.xml *.xml.gz), base: data_dir).each do |file_path|
      file_path = ::File.expand_path(file_path, data_dir)
      ::FileUtils.rm_f(file_path) if ::File.mtime(file_path) < threshold
    end
  end

  def import_rss_item(*args)
    page = super
    return page if page.nil? || page.invalid?

    content = download(page.rss_link)
    return page if content.nil?

    page.event_id = extract_event_id(content) rescue nil
    page.save!
    page.save_weather_xml(content)

    if content.include?('<InfoKind>震度速報</InfoKind>')
      process_earthquake(page)
    end

    @imported_pages << page
    page
  end

  # override Rss::ImportBase#remove_unimported_pages to reduce destroy call
  def remove_unimported_pages
  end

  def download(url)
    cache(url) do
      retriable do
        http_client = Faraday.new(url: url) do |builder|
          builder.request  :url_encoded
          builder.response :logger, Rails.logger
          builder.adapter Faraday.default_adapter
        end
        http_client.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
        http_client.headers[:accept_encoding] = "gzip"

        resp = http_client.get
        raise "#{resp.status}: http error" if resp.status != 200

        content_encoding = resp.headers["Content-Encoding"]
        if content_encoding.nil?
          body = resp.body
        elsif content_encoding.casecmp("gzip") == 0
          body = Zlib::GzipReader.wrap(StringIO.new(resp.body)) { |gz| gz.read }
        else
          raise "#{content_encoding}: unsupported content encoding"
        end

        raise "empty body" if body.blank?

        body.force_encoding('UTF-8')
      end
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def cache(url)
    data_dir = SS.config.rss.weather_xml["data_cache_dir"]
    return yield if data_dir.blank?

    data_dir = ::File.expand_path(data_dir, Rails.root)
    ::FileUtils.mkdir_p(data_dir) unless ::Dir.exists?(data_dir)

    hash = Digest::MD5.hexdigest(url)
    file_paths = %w(xml.gz xml).map { |ext| ::File.join(data_dir, "#{hash}.#{ext}") }
    file_path = file_paths.find { |path| ::File.exists?(path) }
    if file_path
      if file_path.ends_with?(".gz")
        return ::Zlib::GzipReader.open(file_path) { |gz| gz.read }
      else
        return ::File.read(file_path)
      end
    end

    data = yield
    ::Zlib::GzipWriter.open(file_paths.first) { |gz| gz.write data.to_s }

    data
  end

  def retriable(tries = 3, timeout_sec = 10)
    tries.times do |index|
      try = index + 1

      begin
        return ::Timeout.timeout(timeout_sec) { yield }
      rescue => e
        raise if try >= tries

        next_interval = 5 * try
        Rails.logger.info("#{e.class}: '#{e.message}' - #{try} tries and #{next_interval} seconds until the next try.")
        sleep(next_interval)
      end
    end
  end

  def extract_event_id(xml)
    xmldoc = REXML::Document.new(xml)
    REXML::XPath.first(xmldoc, '/Report/Head/EventID/text()').to_s.strip
  end

  def process_earthquake(page)
    parse_xml(page)
    if @region_eq_infos.blank?
      Rails.logger.info('no earthquake found inside target region')
      return
    end

    max_int = @region_eq_infos.max_by { |item| item[:area_max_int] }
    max_int = max_int[:area_max_int] if max_int.present?
    if compare_intensity(max_int, node.earthquake_intensity) < 0
      Rails.logger.info("actual intensity #{max_int} is lower than #{node.earthquake_intensity}")
      return
    end

    # send anpi mail
    send_earthquake_info_mail(page)
  end

  def parse_xml(page)
    @region_eq_infos = []
    return if node.my_anpi_post.blank?
    return if node.anpi_mail.blank?

    xmldoc = REXML::Document.new(page.weather_xml)
    status = REXML::XPath.first(xmldoc, '/Report/Control/Status/text()').to_s.strip
    return if status != Jmaxml::Status::NORMAL

    info_kind = REXML::XPath.first(xmldoc, '/Report/Head/InfoKind/text()').to_s.strip
    return if info_kind != '震度速報'

    @report_datetime = REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()').to_s.strip
    if @report_datetime.present?
      @report_datetime = Time.zone.parse(@report_datetime.to_s) rescue nil
    end
    @target_datetime = REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()').to_s.strip
    if @target_datetime.present?
      @target_datetime = Time.zone.parse(@target_datetime.to_s) rescue nil
    end

    diff = Time.zone.now - @report_datetime
    return if diff.abs > 1.hour

    REXML::XPath.match(xmldoc, '/Report/Body/Intensity/Observation/Pref').each do |pref|
      pref_name = pref.elements['Name'].text
      pref_code = pref.elements['Code'].text
      REXML::XPath.match(pref, 'Area').each do |area|
        area_name = area.elements['Name'].text
        area_code = area.elements['Code'].text
        area_max_int = area.elements['MaxInt'].text

        region = Jmaxml::QuakeRegion.site(site).where(code: area_code).first
        next if region.blank?

        next unless node.target_region_ids.include?(region.id)

        @region_eq_infos << {
          pref_name: pref_name,
          pref_code: pref_code,
          area_name: area_name,
          area_code: area_code,
          area_max_int: area_max_int
        }
      end
    end
  end

  # send anpi mail
  def send_earthquake_info_mail(page)
    renderer = Rss::Renderer::AnpiMail.new(
      cur_site: site,
      cur_node: node,
      cur_page: page,
      cur_infos: { infos: @region_eq_infos, target_time: @target_datetime })

    name = renderer.render_template(node.title_mail_text)
    text = renderer.render

    ezine_page = Ezine::Page.new(
      cur_site: site,
      cur_node: node.anpi_mail,
      cur_user: user,
      name: name,
      text: text
    )

    unless ezine_page.save
      Rails.logger.warn("failed to save ezine/page:\n#{ezine_page.errors.full_messages.join("\n")}")
      return
    end

    Ezine::DeliverJob.bind(site_id: site, node_id: node, page_id: ezine_page).perform_now
  end

  def compare_intensity(lhs, rhs)
    normalize_intensity(lhs) <=> normalize_intensity(rhs)
  end

  def normalize_intensity(int)
    ret = int.to_s[0].to_i * 10
    ret += 1 if int[1] == '-'
    ret += 9 if int[1] == '+'
    ret
  end

  def execute_weather_xml_filters
    return if @imported_pages.blank?
    Rss::ExecuteWeatherXmlFiltersJob.bind(site_id: site.id, node_id: node.id).perform_now(@imported_pages.map(&:id))
  end
end
