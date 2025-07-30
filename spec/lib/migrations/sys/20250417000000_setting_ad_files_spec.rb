require 'spec_helper'
require Rails.root.join("lib/migrations/sys/20250417000000_setting_ad_files.rb")

RSpec.describe SS::Migration20250417000000, dbscope: :example do
  let(:ss_file1) do
    tmp_ss_file(
      basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
  end
  let(:url) { unique_url }

  before do
    # v1.19 以前ではファイル側に URL を保持していた
    ss_file1.collection.update_one(
      { _id: ss_file1.id },
      { '$set' => { link_url: url } }
    )

    # v1.19 以前では設定側はファイルIDの参照を保持
    setting = Sys::Setting.create!
    setting.collection.update_one(
      { _id: setting.id },
      { '$set' => { file_ids: [ ss_file1.id ] } }
    )

    described_class.new.change
  end

  it do
    Sys::Setting.first.tap do |setting|
      expect(setting.ad_links.count).to eq 1

      setting.ad_links.first.tap do |ad_link|
        expect(ad_link.name).to be_blank
        expect(ad_link.url).to eq url
        expect(ad_link.target).to eq "_blank"
        expect(ad_link.state).to eq "show"

        file = ad_link.file
        expect(file.id).to eq ss_file1.id
        expect(file.owner_item_id.to_s).to eq setting.id.to_s
        expect(file.owner_item_type).to eq setting.class.name
        expect(file.model).to eq setting.class.name.underscore
      end
    end
  end
end
