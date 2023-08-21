require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20201204000000_map_api.rb")

RSpec.describe SS::Migration20201204000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:site2) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }
  let!(:site3) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }
  let!(:site4) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }

  before do
    site2.set(map_api: 'googlemaps')
    site3.set(map_api: 'openlayers')
    site4.set(map_api: 'open_street_map')

    # do migration
    described_class.new.change
  end

  it do
    expect(site.map_api).to be_nil
    expect(site.map_api_layer).to be_nil

    site2.reload
    expect(site2.map_api).to eq 'googlemaps'
    expect(site2.map_api_layer).to be_nil

    site3.reload
    expect(site3.map_api).to eq 'openlayers'
    expect(site3.map_api_layer).to be_nil

    site4.reload
    expect(site4.map_api).to eq 'openlayers'
    expect(site4.map_api_layer).to eq 'OpenStreetMap'
  end
end
