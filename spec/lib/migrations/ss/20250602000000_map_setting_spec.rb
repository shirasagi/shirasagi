require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20250602000000_map_setting.rb")

RSpec.describe SS::Migration20250602000000, dbscope: :example do
  let!(:site1) { create(:cms_site, host: unique_id, domains: [unique_id]) }
  let!(:site2) { create(:cms_site, host: unique_id, domains: [unique_id]) }
  let!(:site3) { create(:cms_site, host: unique_id, domains: [unique_id]) }
  let!(:old_model) do
    Class.new(Cms::Site) do
      store_in collection: "ss_sites"
      field :show_google_maps_search, type: String, default: "active"
    end
  end

  before do
    old_model.find(site1.id).set(show_google_maps_search: "expired")
    site1.reload

    old_model.find(site2.id).set(show_google_maps_search: "active")
    site2.reload
  end

  it do
    expect(site1.show_google_maps_search_in_marker_enabled?).to be_truthy
    expect(site2.show_google_maps_search_in_marker_enabled?).to be_truthy
    expect(site3.show_google_maps_search_in_marker_enabled?).to be_truthy

    expect(site1[:show_google_maps_search]).to eq "expired"
    expect(site2[:show_google_maps_search]).to eq "active"
    expect(site3[:show_google_maps_search]).to eq nil

    described_class.new.change

    site1.reload
    site2.reload
    site3.reload

    expect(site1.show_google_maps_search_in_marker_enabled?).to be_falsey
    expect(site2.show_google_maps_search_in_marker_enabled?).to be_truthy
    expect(site3.show_google_maps_search_in_marker_enabled?).to be_truthy
  end
end
