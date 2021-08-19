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
      if !node.kintone_app_enabled?
        raise "update_kintone_record : kintone app disabled"
      end

      record = to_kintone_record
      if record.blank?
        raise "update_kintone_record : update record is blank"
      end

      api = node.kintone_api
      res = api.record.register(node.kintone_app_key, record)

      self.kintone_record_key = res["id"]
      self.kintone_revision = res["revision"]
      self.kintone_update_error_message = nil
      update
    rescue => e
      Rails.logger.error("update_kintone_record : #{e.message}")
      self.kintone_update_error_message = e.message
      update
    end
  end
end
