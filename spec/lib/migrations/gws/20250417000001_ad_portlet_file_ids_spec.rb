require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20250417000001_ad_portlet_file_ids.rb")

RSpec.describe SS::Migration20250417000001, dbscope: :example do
  let!(:ss_file1) do
    tmp_ss_file(basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
  end
  let!(:ss_file2) do
    tmp_ss_file(basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
  end
  let(:url1) { unique_url }
  let(:pause1) { rand(1..5) }
  let(:url2) { unique_url }
  let!(:user) { gws_user }
  let!(:setting) { create(:gws_portal_user_setting, cur_user: user) }
  let!(:portlet1) { create(:gws_portal_user_portlet, cur_user: user, setting: setting, portlet_model: "ad") }
  let!(:portlet2) { create(:gws_portal_user_portlet, cur_user: user, setting: setting, portlet_model: "ad") }

  before do
    # v1.19 以前ではファイル側に URL を保持していた
    ss_file1.collection.update_one(
      { _id: ss_file1.id },
      { '$set' => { link_url: url1 } }
    )
    ss_file2.collection.update_one(
      { _id: ss_file2.id },
      { '$set' => { link_url: url2 } }
    )

    # v1.19 以前では設定側はファイルIDの参照を file_ids に保持していた時代と ad_file_ids に保持していた時代とがある
    portlet1.collection.update_one(
      { _id: portlet1.id },
      { '$set' => { file_ids: [ ss_file1.id ], time: pause1 } }
    )
    portlet2.collection.update_one(
      { _id: portlet2.id },
      { '$set' => { ad_file_ids: [ ss_file2.id ] } }
    )

    described_class.new.change
  end

  it do
    Gws::Portal::UserPortlet.find(portlet1.id).tap do |portlet|
      expect(portlet.ad_pause).to eq pause1 * 1_000
      expect(portlet.ad_links.count).to eq 1
      portlet.ad_links.first.tap do |ad_link|
        expect(ad_link.name).to be_blank
        expect(ad_link.url).to eq url1
        expect(ad_link.target).to eq "_blank"
        expect(ad_link.state).to eq "show"

        file = ad_link.file
        expect(file.id).to eq ss_file1.id
        expect(file.owner_item_id.to_s).to eq portlet.id.to_s
        expect(file.owner_item_type).to eq portlet.class.name
        expect(file.model).to eq portlet.class.name.underscore
      end
    end

    Gws::Portal::UserPortlet.find(portlet2.id).tap do |portlet|
      expect(portlet.ad_links.count).to eq 1
      portlet.ad_links.first.tap do |ad_link|
        expect(ad_link.name).to be_blank
        expect(ad_link.url).to eq url2
        expect(ad_link.target).to eq "_blank"
        expect(ad_link.state).to eq "show"

        file = ad_link.file
        expect(file.id).to eq ss_file2.id
        expect(file.owner_item_id.to_s).to eq portlet.id.to_s
        expect(file.owner_item_type).to eq portlet.class.name
        expect(file.model).to eq portlet.class.name.underscore
      end
    end
  end
end
