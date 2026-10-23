require 'spec_helper'
require Rails.root.join("lib/migrations/ads/20261023000001_link_target.rb")

RSpec.describe SS::Migration20261023000001, dbscope: :example do
  let!(:site)  { cms_site }
  let!(:node)  { create :ads_node_banner, cur_site: site }
  let!(:part1) do
    part = create(:ads_part_banner, cur_site: site, cur_node: node)
    part.set(link_target: "self")
    part
  end
  let!(:part2) do
    part = create(:ads_part_banner, cur_site: site, cur_node: node)
    part.set(link_target: "blank")
    part
  end
  let!(:part3) do
    part = create(:ads_part_banner, cur_site: site, cur_node: node)
    part.set(link_target: unique_id)
    part
  end

  before do
    described_class.new.change
  end

  it do
    Ads::Part::Banner.find(part1.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_self"
    end
    Ads::Part::Banner.find(part2.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
    Ads::Part::Banner.find(part3.id).tap do |after_migration|
      expect(after_migration.link_target).to eq part3.link_target
    end
  end
end
