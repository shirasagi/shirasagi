require 'spec_helper'

describe Opendata::Idea, dbscope: :example do
  let!(:node_search_dataset) { create(:opendata_node_search_idea) }
  let(:node) { create(:opendata_node_idea) }
  let!(:node_category) { create(:opendata_node_category) }

  context "check attributes with typical url resource" do
    subject { create(:opendata_idea, node: node) }
    its(:becomes_with_route) { is_expected.not_to be_nil }
    its(:dirname) { is_expected.to eq node.filename }
    its(:basename) { is_expected.to eq subject.filename.split('/').last }
    its(:path) { is_expected.to end_with  "/#{subject.dirname}/#{subject.basename}" }
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
    its(:contact_present?) { is_expected.to be_falsey }
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

  describe ".search" do

    let(:category_params) do
      { site: node_category.site, category_id: node_category.id.to_s }
    end

    let(:ids_matcher) do
      include("_id" => include("$in" => include(11).and(include(31))))
    end

    let(:normal_keyword_matcher) do
      include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
    end

    let(:meta_keyword_matcher) do
      include("$and" => include("$or" => include("name" => /\(\)\[\]\{\}\.\?\+\*\|\\/i).
        and(include("text" => /\(\)\[\]\{\}\.\?\+\*\|\\/i))))
    end

    let(:category_id_matcher) do
      include("category_ids" => include("$in" => include(node_category.id)))
    end

    it { expect(described_class.search({}).selector.to_h).to include("route" => "opendata/idea") }
    it { expect(described_class.search(keyword: "キーワード").selector.to_h).to normal_keyword_matcher }
    it { expect(described_class.search(keyword: "()[]{}.?+*|\\").selector.to_h).to meta_keyword_matcher }
    it { expect(described_class.search(tag: "タグ").selector.to_h).to include("tags" => "タグ") }
    it { expect(described_class.search(area_id: "43").selector.to_h).to include("area_ids" => 43) }
    it { expect(described_class.search(category_params).selector.to_h).to category_id_matcher }

  end
end
