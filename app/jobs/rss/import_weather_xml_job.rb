require 'rss'

class Rss::ImportWeatherXmlJob < Rss::ImportBase
  def initialize(*args)
    super
    set_model Rss::WeatherXmlPage
  end

  class Status
    NORMAL = "通常".freeze
    TRAINING = "訓練".freeze
    TEST = "試験".freeze
  end

  private
    def before_import(file, *args)
      super

      @cur_file = Rss::TempFile.where(site_id: site.id, id: file).first
      return unless @cur_file

      @items = Rss::Wrappers.parse(@cur_file)
    end

    def after_import
      super

      gc_rss_tempfile
    end

    def gc_rss_tempfile
      return if rand(100) >= 20
      Rss::TempFile.lt(updated: 2.weeks.ago).destroy_all
    end

    def import_rss_item(*args)
      page = super
      return page if page.nil? || page.invalid?

      content = download(page.rss_link)
      return page if content.nil?

      page.xml = content
      page.save!

      if content.include?('<InfoKind>震度速報</InfoKind>')
        process_earthquake(page)
      end

      page
    end

    def download(url)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      req = Net::HTTP::Get.new(uri.path)
      res = http.request(req)
      return nil if res.code != '200'
      res.body.force_encoding('UTF-8')
    rescue
      nil
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

      xmldoc = REXML::Document.new(page.xml)
      status = REXML::XPath.first(xmldoc, '/Report/Control/Status/text()')
      return if status != Status::NORMAL

      info_kind = REXML::XPath.first(xmldoc, '/Report/Head/InfoKind/text()')
      return if info_kind != '震度速報'

      @report_datetime = REXML::XPath.first(xmldoc, '/Report/Head/ReportDateTime/text()')
      if @report_datetime.present?
        @report_datetime = Time.zone.parse(@report_datetime.to_s) rescue nil
      end
      @target_datetime = REXML::XPath.first(xmldoc, '/Report/Head/TargetDateTime/text()')
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

          region = Rss::WeatherXmlRegion.site(site).where(code: area_code).first
          next if region.blank?

          next unless node.target_region_ids.include?(region.id)

          @region_eq_infos << {
            pref_name: pref_name,
            pref_code: pref_code,
            area_name: area_name,
            area_code: area_code,
            area_max_int: area_max_int,
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

      Ezine::Task.deliver ezine_page.id
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
end
