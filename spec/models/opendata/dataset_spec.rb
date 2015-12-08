require 'spec_helper'

describe Opendata::Dataset, dbscope: :example do
  let!(:node_category) { create(:opendata_node_category) }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }

  context "check attributes with typical url resource" do
    subject { create(:opendata_dataset, node: node) }
    its(:becomes_with_route) { is_expected.not_to be_nil }
    its(:dirname) { is_expected.to eq node.filename }
    its(:basename) { is_expected.to eq subject.filename.split('/').last }
    its(:path) { is_expected.to end_with  "/#{subject.dirname}/#{subject.basename}" }
    its(:url) { is_expected.to eq "/#{subject.dirname}/#{subject.basename}" }
    its(:full_url) { is_expected.to eq "http://#{cms_site.domain}/#{subject.dirname}/#{subject.basename}" }
    its(:parent) { expect(subject.parent.id).to eq node.id }
    its(:point_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/point.html" }
    its(:point_members_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/point/members.html" }
    its(:dataset_apps_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/apps/show.html" }
    its(:dataset_ideas_url) { is_expected.to eq "#{subject.url.sub(/\.html$/, "")}/ideas/show.html" }
    its(:contact_present?) { is_expected.to be_falsey }
  end

  describe ".sort_options" do
    it { expect(described_class.sort_options).to include %w(新着順 released) }
  end

  describe ".sort_hash" do
    it { expect(described_class.sort_hash("released")).to include(released: -1).and include(_id: -1) }
    it { expect(described_class.sort_hash("popular")).to include(point: -1).and include(_id: -1) }
    it { expect(described_class.sort_hash("attention")).to include(downloaded: -1).and include(_id: -1) }
    it { expect(described_class.sort_hash("")).to include(released: -1) }
    it { expect(described_class.sort_hash("foobar")).to include("foobar" => 1) }
  end

  describe ".aggregate_field" do
    it { expect(described_class.aggregate_field(:license, limit: 10)).to be_empty }
  end

  describe ".aggregate_array" do
    it { expect(described_class.aggregate_array(:tags, limit: 10)).to be_empty }
  end

  describe ".aggregate_resources" do
    it { expect(described_class.aggregate_resources(:format, limit: 10)).to be_empty }
  end

  describe ".get_tag_list" do
    it { expect(described_class.get_tag_list(nil)).to be_empty }
  end

  describe ".get_tag" do
    it { expect(described_class.get_tag("タグ")).to be_empty }
  end

  describe ".search" do
    let(:category_id_params) do
      { site: node_category.site, category_id: node_category.id.to_s }
    end
    let(:ids_matcher) do
      include("_id" => include("$in" => include(11).and(include(31))))
    end
    let(:normal_name_keyword_matcher) do
      include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
    end
    let(:normal_name_modal_matcher) do
      include("name" => include("$all" => include(/名前/i)))
    end
    let(:meta_name_keyword_matcher) do
      include("$and" => include("$or" => include("name" => /\(\)\[\]\{\}\.\?\+\*\|\\/i).
        and(include("text" => /\(\)\[\]\{\}\.\?\+\*\|\\/i))))
    end
    let(:meta_name_modal_matcher) do
      include("name" => include("$all" => include(/\(\)\[\]\{\}\.\?\+\*\|\\/i)))
    end
    let(:category_id_matcher) do
      include("category_ids" => include("$in" => include(node_category.id)))
    end
    let(:dataset_group_matcher) do
      include("dataset_group_ids" => include("$in" => include(-1)))
    end
    let(:format_matcher) do
      include("$and" => include("$or" => include("resources.format" => "CSV").and(include("url_resources.format" => "CSV"))))
    end
    let(:license_id_matcher) do
      include("$and" => include("$or" => include("resources.license_id" => 28).and(include("url_resources.license_id" => 28))))
    end
    it { expect(described_class.search({}).selector.to_h).to include("route" => "opendata/dataset") }
    it { expect(described_class.search(keyword: "キーワード").selector.to_h).to include("$and") }
    it { expect(described_class.search(ids: "11,31").selector.to_h).to ids_matcher }
    it { expect(described_class.search(name: "名前", keyword: "キーワード").selector.to_h).to normal_name_keyword_matcher }
    it { expect(described_class.search(name: "名前", modal: true).selector.to_h).to normal_name_modal_matcher }
    it { expect(described_class.search(name: "名前", keyword: "()[]{}.?+*|\\").selector.to_h).to meta_name_keyword_matcher }
    it { expect(described_class.search(name: "()[]{}.?+*|\\", modal: true).selector.to_h).to meta_name_modal_matcher }
    it { expect(described_class.search(tag: "タグ").selector.to_h).to include("tags" => "タグ") }
    it { expect(described_class.search(area_id: "43").selector.to_h).to include("area_ids" => 43) }
    it { expect(described_class.search(category_id_params).selector.to_h).to category_id_matcher }
    it { expect(described_class.search(dataset_group: "データセット", site: cms_site).selector.to_h).to dataset_group_matcher }
    it { expect(described_class.search(format: "csv").selector.to_h).to format_matcher }
    it { expect(described_class.search(license_id: "28").selector.to_h).to license_id_matcher }
  end
end
