module Inquiry::Addon
  module KintoneApp::Answer
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kintone_record_key, type: String
      field :kintone_revision, type: String
      field :kintone_update_error_message, type: String
    end

    def to_kintone_record
      record = {}
      data.each do |d|
        column = d.column
        next if column.nil?
        next if column.kintone_field_code.blank?

        if column.input_type =~ /^(text_field|text_area|email_field|radio_button|select)$/
          record[column.kintone_field_code] = { "value" => d.value }
        elsif column.input_type == "check_box"
          record[column.kintone_field_code] = { "value" => d.values }
        end
      end
      record
    end

    def update_kintone_record
      record = to_kintone_record
      if record.blank?
        update_error_msg("update_kintone_record : update record is blank")
        return
      end

      begin
        Retriable.retriable(on_retry: method(:on_each_retry)) do
          @res = node.kintone_api.record.register(node.kintone_app_key, record)
        end
      rescue => e
        Rails.logger.error("update_kintone_record : #{e.message}")
        update_error_msg("update_kintone_record : #{e.message}")
        return
      end

      update_kintone_res
    end

    def update_error_msg(msg)
      self.kintone_update_error_message = msg
      update
    end

    def on_each_retry(err, try, elapsed, interval)
      Rails.logger.warn(
        "#{err.class}: '#{err.message}' - #{try} tries in #{elapsed} seconds and #{interval} seconds until the next try."
      )
    end

    def update_kintone_res
      self.kintone_record_key = @res["id"]
      self.kintone_revision = @res["revision"]
      update
    end
  end
end
