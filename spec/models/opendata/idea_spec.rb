require 'spec_helper'

describe Opendata::Idea, dbscope: :example do
  let!(:node_search_dataset) { create(:opendata_node_search_idea) }
  let(:node) { create(:opendata_node_idea) }
  let!(:node_category) { create(:opendata_node_category) }

  describe "#attributes" do
    let(:item) { create :opendata_idea, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.opendata_idea_path(site: item.site, cid: node, id: item.id) }

    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end

  context "check attributes with typical url resource" do
    subject { create(:opendata_idea, cur_node: node) }
    its(:dirname) { is_expected.to eq node.filename }
    its(:basename) { is_expected.to eq subject.filename.split('/').last }
    its(:path) { is_expected.to end_with "/#{subject.dirname}/#{subject.basename}" }
    its(:url) { is_expected.to eq "/#{subject.dirname}/#{subject.basename}" }
    its(:full_url) { is_expected.to eq "http://#{cms_site.domain}/#{subject.dirname}/#{subject.basename}" }
    its(:parent) { expect(subject.parent.id).to eq node.id }
    its(:point_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/point.html" }
    its(:point_members_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/point/members.html" }
    its(:related_app_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/app/show.html" }
    its(:related_dataset_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/dataset/show.html" }
    its(:comment_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/comment/show.html" }
    its(:comment_add_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/comment/add.html" }
    its(:comment_delete_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/comment/delete.html" }
    its(:show_contact?) { is_expected.to be_falsey }
  end

  describe ".sort_options" do
    it { expect(described_class.sort_options).to include %w(新着順 released) }
  end

  describe ".sort_hash" do
    it { expect(described_class.sort_hash("released")).to include(released: -1).and include(_id: -1) }
    it { expect(described_class.sort_hash("popular")).to include(point: -1).and include(_id: -1) }
    it { expect(described_class.sort_hash("attention")).to include(commented: -1).and include(_id: -1) }
    it { expect(described_class.sort_hash("")).to include(released: -1) }
    it { expect(described_class.sort_hash("foobar")).to include("foobar" => 1) }
  end

  describe ".aggregate_array" do
    it { expect(described_class.aggregate_array(:tags, limit: 10)).to be_empty }
  end
end
