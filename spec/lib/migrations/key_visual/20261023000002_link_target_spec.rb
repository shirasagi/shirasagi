require 'spec_helper'
require Rails.root.join("lib/migrations/key_visual/20261023000002_link_target.rb")

RSpec.describe SS::Migration20261023000002, dbscope: :example do
  let!(:site)  { cms_site }
  let!(:node)  { create :key_visual_node_image, cur_site: site }
  let!(:part1) do
    part = create(:key_visual_part_slide, cur_site: site, cur_node: node)
    part.set(link_target: "self")
    part
  end
  let!(:part2) do
    part = create(:key_visual_part_slide, cur_site: site, cur_node: node)
    part.set(link_target: "blank")
    part
  end
  let!(:part3) do
    part = create(:key_visual_part_slide, cur_site: site, cur_node: node)
    # 許可外の値
    part.set(link_target: unique_id)
    part
  end
  let!(:part4) do
    part = create(:key_visual_part_slide, cur_site: site, cur_node: node)
    part.set(link_target: "_self")
    part
  end
  let!(:part5) do
    part = create(:key_visual_part_slide, cur_site: site, cur_node: node)
    part.set(link_target: "_blank")
    part
  end

  before do
    described_class.new.change
  end

  it do
    KeyVisual::Part::Slide.find(part1.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
    KeyVisual::Part::Slide.find(part2.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
    KeyVisual::Part::Slide.find(part3.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
    KeyVisual::Part::Slide.find(part4.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
    KeyVisual::Part::Slide.find(part5.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
  end
end
