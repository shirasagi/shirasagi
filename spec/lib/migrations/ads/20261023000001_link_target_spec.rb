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
    # 許可外の値
    part.set(link_target: unique_id)
    part
  end
  let!(:part4) do
    part = create(:ads_part_banner, cur_site: site, cur_node: node)
    part.set(link_target: "_self")
    part
  end
  let!(:part5) do
    part = create(:ads_part_banner, cur_site: site, cur_node: node)
    part.set(link_target: "_blank")
    part
  end
  let!(:page1) do
    page = create(:ads_banner, cur_site: site, cur_node: node)
    page.set(link_target: "_self")
    page
  end
  let!(:page2) do
    page = create(:ads_banner, cur_site: site, cur_node: node)
    page.set(link_target: "_blank")
    page
  end
  let!(:page3) do
    page = create(:ads_banner, cur_site: site, cur_node: node)
    # 許可外の値
    page.set(link_target: unique_id)
    page
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
      expect(after_migration.link_target).to be_blank
    end
    Ads::Part::Banner.find(part4.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_self"
    end
    Ads::Part::Banner.find(part5.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
    Ads::Banner.find(page1.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_self"
    end
    Ads::Banner.find(page2.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
    Ads::Banner.find(page3.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
  end
end
