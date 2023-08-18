module Job::MicheckerResultFilter
  extend ActiveSupport::Concern

  def result
    set_item

    case params[:type]
    when "accessibility_report"
      michecker_result_accessibility_report
    when "lowvision_report"
      michecker_result_lowvision_report
    when "lowvision_source"
      michecker_result_lowvision_source
    when "lowvision_result"
      michecker_result_lowvision_result
    else
      raise "404"
    end
  end

  private

  def michecker_result_accessibility_report
    file = @item.html_checker_report_filepath
    raise "404" if file.blank? || !::File.exist?(file)

    accessibility_result = Cms::Michecker::Accessibility.load(file)
    raise "404" if accessibility_result.blank?

    filename = "accessibility_report_#{Time.zone.now.to_i}.csv"

    response.status = 200
    enum = accessibility_result.enum_csv(encoding: "UTF-8")
    send_enum enum, type: enum.content_type, filename: filename
  end

  def michecker_result_lowvision_report
    file = @item.low_vision_report_filepath
    raise "404" if file.blank? || !::File.exist?(file)

    lowvision_result = Cms::Michecker::LowVision.load(file)
    raise "404" if lowvision_result.blank?

    filename = "low_vision_report_#{Time.zone.now.to_i}.csv"
    response.status = 200
    enum = lowvision_result.enum_csv(encoding: "UTF-8")
    send_enum enum, type: enum.content_type, filename: filename
  end

  def michecker_result_lowvision_source
    file = @item.low_vision_source_filepath
    raise "404" if file.blank? || !::File.exist?(file)

    ss_send_file file
  end

  def michecker_result_lowvision_result
    file = @item.low_vision_result_filepath
    raise "404" if file.blank? || !::File.exist?(file)

    ss_send_file file
  end
end
