# frozen_string_literal: true

class SS::Migration20250417000000
  include SS::Migration::Base

  depends_on "20250310000000"

  def change
    # put your migration code here
    setting = Sys::Setting.first
    return if setting.blank?

    # すでに広告が作成されている
    return if setting.ad_links.present?

    file_ids = setting.attributes["file_ids"]
    return if file_ids.blank?

    files = SS::File.unscoped.in(id: file_ids).to_a
    files.each do |file|
      url = file.attributes["link_url"]
      setting.ad_links.build(url: url, file_id: file.id, target: "_blank", state: "show")
    end

    result = setting.without_record_timestamps { setting.save }
    unless result
      warn "failed to migrate ad files to ad links\n#{setting.errors.full_messages.join("\n")}"
    end
  ensure
    if setting
      setting.unset(:file_ids)
    end
  end
end
