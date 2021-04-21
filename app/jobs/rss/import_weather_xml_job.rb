require 'rss'

class Rss::ImportWeatherXmlJob < Rss::ImportBase
  include Job::SS::TaskFilter
  include Rss::Downloadable

  self.task_class = Cms::Task
  self.task_name = "rss:import_weather_xml"

  def initialize(*args)
    super
    set_model Rss::WeatherXmlPage
  end

  private

  def before_import(*args)
    @options = args.extract_options!.with_indifferent_access
    @weather_xml_page = nil
    super

    updates = @options[:seed_cache] != "use"

    urls = SS.config.rss.weather_xml["urls"]
    urls.map!(&:strip)
    urls.select!(&:present?)

    @items = Enumerator.new do |y|
      urls.each do |url|
        xml_text = download_with_cache(url, updates: updates)
        next if xml_text.blank?

        rss = ::Rss::Wrappers.parse_from_rss_source(xml_text)
        next if rss.blank?

        @task.log "found #{rss.count} entries to import"

        rss.each do |item|
          y << item
        end
      end
    end

    @imported_pages = []
  end

  def after_import
    save_imported_urls
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

  def import_rss_item(rss_item)
    if rss_imported?(rss_item.link, rss_item.released)
      @task.log "already imported #{rss_item.link}, so ignores to import"
      return
    end

    page = nil
    elapsed = Benchmark.realtime do
      page = super
      return page if page.nil? || page.invalid?

      content = download_with_cache(page.rss_link)
      return page if content.nil?

      page.event_id = extract_event_id(content) rescue nil
      page.save!
      page.save_weather_xml(content)

      if content.include?('<InfoKind>震度速報</InfoKind>')
        process_earthquake(page)
      end

      @imported_pages << page
    end

    @task.log "imported #{page.try(:rss_link)} in #{elapsed} seconds"

    page
  end

  # override Rss::ImportBase#remove_unimported_pages to reduce destroy call
  def remove_unimported_pages
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

  def rss_imported?(url, date)
    @imported_logs ||= begin
      logs = []
      log_dir = ::File.join(self.class.data_cache_dir, node.id.to_s)
      ::Dir.glob(%w(imported_*.log.gz), base: log_dir).each do |file_path|
        file_path = ::File.expand_path(file_path, log_dir)
        json = ::Zlib::GzipReader.open(file_path) { |gz| gz.read }

        logs += JSON.parse(json)
      end

      logs.map! { |imported_url, imported_date| [ imported_url, Time.zone.parse(imported_date) ] }
      logs
    end

    @imported_logs.find { |imported_url, imported_date| imported_url == url && imported_date.to_i == date.to_i }
  end

  def save_imported_urls
    return if @imported_pages.blank?

    urls_with_date = @imported_pages.map { |page| [ page.rss_link, page.released ] }

    # いわゆる「ログ」に相当する情報なので、DB ではなくファイルに保存したい。
    # 古い情報には意味がない。気象庁からは 24 時間以上前の情報は配信されていないみたい。
    # data_cache_dir に保存するのが良さそうな気がする。

    now = Time.zone.now
    log_dir = ::File.join(self.class.data_cache_dir, node.id.to_s)
    log_file = ::File.join(log_dir, "imported_#{now.to_f.to_s.sub(".", "_")}.log.gz")
    tmp_log_file = ::File.join(log_dir, ".imported_#{now.to_f.to_s.sub(".", "_")}.log.gz")
    ::FileUtils.mkdir_p(log_dir) unless ::Dir.exists?(log_dir)

    # DISK FULL などにより不完全なファイルが作成されることを防止するために、作業ファイルに保存後、作業ファイルを移動するようにする。
    ::Zlib::GzipWriter.open(tmp_log_file) { |gz| gz.write(urls_with_date.to_json) }
    ::FileUtils.move(tmp_log_file, log_file, force: true)
  end
end
