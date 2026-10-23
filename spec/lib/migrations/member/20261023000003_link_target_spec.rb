require 'spec_helper'
require Rails.root.join("lib/migrations/member/20261023000003_link_target.rb")

RSpec.describe SS::Migration20261023000003, dbscope: :example do
  let!(:site)  { cms_site }
  let!(:node)  { create :member_node_photo, cur_site: site }
  let!(:part1) do
    part = create(:member_part_photo_slide, cur_site: site, cur_node: node)
    part.set(link_target: "self")
    part
  end
  let!(:part2) do
    part = create(:member_part_photo_slide, cur_site: site, cur_node: node)
    part.set(link_target: "blank")
    part
  end
  let!(:part3) do
    part = create(:member_part_photo_slide, cur_site: site, cur_node: node)
    # 許可外の値
    part.set(link_target: unique_id)
    part
  end
  let!(:part4) do
    part = create(:member_part_photo_slide, cur_site: site, cur_node: node)
    part.set(link_target: "_self")
    part
  end
  let!(:part5) do
    part = create(:member_part_photo_slide, cur_site: site, cur_node: node)
    part.set(link_target: "_blank")
    part
  end

  before do
    described_class.new.change
  end

  it do
    Member::Part::PhotoSlide.find(part1.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
    Member::Part::PhotoSlide.find(part2.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
    Member::Part::PhotoSlide.find(part3.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
    Member::Part::PhotoSlide.find(part4.id).tap do |after_migration|
      expect(after_migration.link_target).to be_blank
    end
    Member::Part::PhotoSlide.find(part5.id).tap do |after_migration|
      expect(after_migration.link_target).to eq "_blank"
    end
  end
end
