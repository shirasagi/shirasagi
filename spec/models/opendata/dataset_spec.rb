require 'spec_helper'

describe Opendata::Dataset, dbscope: :example do
  let!(:node_category) { create(:opendata_node_category) }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }

  context "check attributes with typical url resource" do
    subject { create(:opendata_dataset, cur_node: node) }
    its(:becomes_with_route) { is_expected.not_to be_nil }
    its(:dirname) { is_expected.to eq node.filename }
    its(:basename) { is_expected.to eq subject.filename.split('/').last }
    its(:path) { is_expected.to end_with "/#{subject.dirname}/#{subject.basename}" }
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
    context 'with no option' do
      let(:category_id_params) do
        { site: node_category.site, category_id: node_category.id.to_s }
      end
      let(:ids_matcher) do
        include("_id" => include("$in" => include(11).and(include(31))))
      end
      let(:normal_keyword_matcher) do
        include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
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
        include("$and" => include("category_ids" => include("$in" => include(node_category.id))))
      end
      let(:dataset_group_matcher) do
        include("$and" => include("dataset_group_ids" => include("$in" => include(-1))))
      end
      let(:format_matcher) do
        include("$and" => include("$or" => include("resources.format" => "CSV").and(include("url_resources.format" => "CSV"))))
      end
      let(:license_id_matcher) do
        include("$and" => include("$or" => include("resources.license_id" => 28).and(include("url_resources.license_id" => 28))))
      end
      let(:poster_admin_matcher) do
        include("$and" => include("workflow_member_id" => nil))
      end
      let(:poster_member_matcher) do
        include("$and" => include("workflow_member_id" => include("$exists" => true)))
      end
      it { expect(described_class.search({}).selector.to_h).to include("route" => "opendata/dataset") }
      it { expect(described_class.search(keyword: "キーワード").selector.to_h).to normal_keyword_matcher }
      it { expect(described_class.search(ids: "11,31").selector.to_h).to ids_matcher }
      it { expect(described_class.search(name: "名前", keyword: "キーワード").selector.to_h).to normal_name_keyword_matcher }
      it { expect(described_class.search(name: "名前", modal: true).selector.to_h).to normal_name_modal_matcher }
      it { expect(described_class.search(name: "名前", keyword: "()[]{}.?+*|\\").selector.to_h).to meta_name_keyword_matcher }
      it { expect(described_class.search(name: "()[]{}.?+*|\\", modal: true).selector.to_h).to meta_name_modal_matcher }
      it { expect(described_class.search(tag: "タグ").selector.to_h).to include("$and" => include("tags" => "タグ")) }
      it { expect(described_class.search(area_id: "43").selector.to_h).to include("$and" => include("area_ids" => 43)) }
      it { expect(described_class.search(category_id_params).selector.to_h).to category_id_matcher }
      it { expect(described_class.search(dataset_group: "データセット", site: cms_site).selector.to_h).to dataset_group_matcher }
      it { expect(described_class.search(format: "csv").selector.to_h).to format_matcher }
      it { expect(described_class.search(license_id: "28").selector.to_h).to license_id_matcher }
      it { expect(described_class.search(poster: "admin").selector.to_h).to poster_admin_matcher }
      it { expect(described_class.search(poster: "member").selector.to_h).to poster_member_matcher }
    end

    context 'with all_keywords option' do
      let(:category_id_params) do
        { site: node_category.site, category_id: node_category.id.to_s, option: 'all_keywords' }
      end
      let(:ids_matcher) do
        include("_id" => include("$in" => include(11).and(include(31))))
      end
      let(:normal_keyword_matcher) do
        include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
      end
      # let(:normal_name_keyword_matcher) do
      #   include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
      # end
      # let(:normal_name_modal_matcher) do
      #   include("name" => include("$all" => include(/名前/i)))
      # end
      # let(:meta_name_keyword_matcher) do
      #   include("$and" => include("$or" => include("name" => /\(\)\[\]\{\}\.\?\+\*\|\\/i).
      #     and(include("text" => /\(\)\[\]\{\}\.\?\+\*\|\\/i))))
      # end
      # let(:meta_name_modal_matcher) do
      #   include("name" => include("$all" => include(/\(\)\[\]\{\}\.\?\+\*\|\\/i)))
      # end
      let(:category_id_matcher) do
        include("$and" => include("category_ids" => include("$in" => include(node_category.id))))
      end
      let(:tag_params) { { tag: "タグ", option: 'all_keywords' } }
      let(:tag_matcher) { include("$and" => include("tags" => "タグ")) }
      let(:area_id_params) { { area_id: "43", option: 'all_keywords' } }
      let(:area_id_matcher) { include("$and" => include("area_ids" => 43)) }
      let(:dataset_group_params) { { dataset_group: "データセット", site: cms_site, option: 'all_keywords' } }
      let(:dataset_group_matcher) do
        include("$and" => include("dataset_group_ids" => include("$in" => include(-1))))
      end
      let(:format_matcher) do
        include("$and" => include("$or" => include("resources.format" => "CSV").and(include("url_resources.format" => "CSV"))))
      end
      let(:license_id_matcher) do
        include("$and" => include("$or" => include("resources.license_id" => 28).and(include("url_resources.license_id" => 28))))
      end
      let(:poster_admin_matcher) do
        include("$and" => include("workflow_member_id" => nil))
      end
      let(:poster_member_matcher) do
        include("$and" => include("workflow_member_id" => include("$exists" => true)))
      end
      it { expect(described_class.search({}).selector.to_h).to include("route" => "opendata/dataset") }
      it { expect(described_class.search(keyword: "キーワード", option: 'all_keywords').selector.to_h).to normal_keyword_matcher }
      it { expect(described_class.search(ids: "11,31", option: 'all_keywords').selector.to_h).to ids_matcher }
      # it { expect(described_class.search(name: "名前", keyword: "キーワード").selector.to_h).to normal_name_keyword_matcher }
      # it { expect(described_class.search(name: "名前", modal: true).selector.to_h).to normal_name_modal_matcher }
      # it { expect(described_class.search(name: "名前", keyword: "()[]{}.?+*|\\").selector.to_h).to meta_name_keyword_matcher }
      # it { expect(described_class.search(name: "()[]{}.?+*|\\", modal: true).selector.to_h).to meta_name_modal_matcher }
      it { expect(described_class.search(tag_params).selector.to_h).to tag_matcher }
      it { expect(described_class.search(area_id_params).selector.to_h).to area_id_matcher }
      it { expect(described_class.search(category_id_params).selector.to_h).to category_id_matcher }
      it { expect(described_class.search(dataset_group_params).selector.to_h).to dataset_group_matcher }
      it { expect(described_class.search(format: "csv", option: 'all_keywords').selector.to_h).to format_matcher }
      it { expect(described_class.search(license_id: "28", option: 'all_keywords').selector.to_h).to license_id_matcher }
      it { expect(described_class.search(poster: "admin", option: 'all_keywords').selector.to_h).to poster_admin_matcher }
      it { expect(described_class.search(poster: "member", option: 'all_keywords').selector.to_h).to poster_member_matcher }
    end

    context 'with any_keywords option' do
      let(:category_id_params) do
        { site: node_category.site, category_id: node_category.id.to_s, option: 'any_keywords' }
      end
      let(:ids_matcher) do
        include("_id" => include("$in" => include(11).and(include(31))))
      end
      let(:normal_keyword_matcher) do
        include("$or" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
      end
      # let(:normal_name_keyword_matcher) do
      #   include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
      # end
      # let(:normal_name_modal_matcher) do
      #   include("name" => include("$all" => include(/名前/i)))
      # end
      # let(:meta_name_keyword_matcher) do
      #   include("$and" => include("$or" => include("name" => /\(\)\[\]\{\}\.\?\+\*\|\\/i).
      #     and(include("text" => /\(\)\[\]\{\}\.\?\+\*\|\\/i))))
      # end
      # let(:meta_name_modal_matcher) do
      #   include("name" => include("$all" => include(/\(\)\[\]\{\}\.\?\+\*\|\\/i)))
      # end
      let(:category_id_matcher) do
        include("$and" => include("category_ids" => include("$in" => include(node_category.id))))
      end
      let(:tag_params) { { tag: "タグ", option: 'any_keywords' } }
      let(:tag_matcher) { include("$and" => include("tags" => "タグ")) }
      let(:area_id_params) { { area_id: "43", option: 'any_keywords' } }
      let(:area_id_matcher) { include("$and" => include("area_ids" => 43)) }
      let(:dataset_group_params) { { dataset_group: "データセット", site: cms_site, option: 'any_keywords' } }
      let(:dataset_group_matcher) do
        include("$and" => include("dataset_group_ids" => include("$in" => include(-1))))
      end
      let(:format_matcher) do
        include("$and" => include("$or" => include("resources.format" => "CSV").and(include("url_resources.format" => "CSV"))))
      end
      let(:license_id_matcher) do
        include("$and" => include("$or" => include("resources.license_id" => 28).and(include("url_resources.license_id" => 28))))
      end
      let(:poster_admin_matcher) do
        include("$and" => include("workflow_member_id" => nil))
      end
      let(:poster_member_matcher) do
        include("$and" => include("workflow_member_id" => include("$exists" => true)))
      end
      it { expect(described_class.search({}).selector.to_h).to include("route" => "opendata/dataset") }
      it { expect(described_class.search(keyword: "キーワード", option: 'any_keywords').selector.to_h).to normal_keyword_matcher }
      it { expect(described_class.search(ids: "11,31", option: 'any_keywords').selector.to_h).to ids_matcher }
      # it { expect(described_class.search(name: "名前", keyword: "キーワード").selector.to_h).to normal_name_keyword_matcher }
      # it { expect(described_class.search(name: "名前", modal: true).selector.to_h).to normal_name_modal_matcher }
      # it { expect(described_class.search(name: "名前", keyword: "()[]{}.?+*|\\").selector.to_h).to meta_name_keyword_matcher }
      # it { expect(described_class.search(name: "()[]{}.?+*|\\", modal: true).selector.to_h).to meta_name_modal_matcher }
      it { expect(described_class.search(tag_params).selector.to_h).to tag_matcher }
      it { expect(described_class.search(area_id_params).selector.to_h).to area_id_matcher }
      it { expect(described_class.search(category_id_params).selector.to_h).to category_id_matcher }
      it { expect(described_class.search(dataset_group_params).selector.to_h).to dataset_group_matcher }
      it { expect(described_class.search(format: "csv", option: 'any_keywords').selector.to_h).to format_matcher }
      it { expect(described_class.search(license_id: "28", option: 'any_keywords').selector.to_h).to license_id_matcher }
      it { expect(described_class.search(poster: "admin", option: 'any_keywords').selector.to_h).to poster_admin_matcher }
      it { expect(described_class.search(poster: "member", option: 'any_keywords').selector.to_h).to poster_member_matcher }
    end

    context 'with any_conditions option' do
      let(:category_id_params) do
        { site: node_category.site, category_id: node_category.id.to_s, option: 'any_conditions' }
      end
      let(:ids_matcher) do
        include("_id" => include("$in" => include(11).and(include(31))))
      end
      let(:normal_keyword_matcher) do
        include("$or" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
      end
      # let(:normal_name_keyword_matcher) do
      #   include("$and" => include("$or" => include("name" => /キーワード/i).and(include("text" => /キーワード/i))))
      # end
      # let(:normal_name_modal_matcher) do
      #   include("name" => include("$all" => include(/名前/i)))
      # end
      # let(:meta_name_keyword_matcher) do
      #   include("$and" => include("$or" => include("name" => /\(\)\[\]\{\}\.\?\+\*\|\\/i).
      #     and(include("text" => /\(\)\[\]\{\}\.\?\+\*\|\\/i))))
      # end
      # let(:meta_name_modal_matcher) do
      #   include("name" => include("$all" => include(/\(\)\[\]\{\}\.\?\+\*\|\\/i)))
      # end
      let(:category_id_matcher) do
        include("$or" => include("category_ids" => include("$in" => include(node_category.id))))
      end
      let(:tag_params) { { tag: "タグ", option: 'any_conditions' } }
      let(:tag_matcher) { include("$or" => include("tags" => "タグ")) }
      let(:area_id_params) { { area_id: "43", option: 'any_conditions' } }
      let(:area_id_matcher) { include("$or" => include("area_ids" => 43)) }
      let(:dataset_group_params) { { dataset_group: "データセット", site: cms_site, option: 'any_conditions' } }
      let(:dataset_group_matcher) do
        include("$or" => include("dataset_group_ids" => include("$in" => include(-1))))
      end
      let(:format_matcher) do
        include("$or" => include("$or" => include("resources.format" => "CSV").and(include("url_resources.format" => "CSV"))))
      end
      let(:license_id_matcher) do
        include("$or" => include("$or" => include("resources.license_id" => 28).and(include("url_resources.license_id" => 28))))
      end
      let(:poster_admin_matcher) do
        include("$or" => include("workflow_member_id" => nil))
      end
      let(:poster_member_matcher) do
        include("$or" => include("workflow_member_id" => include("$exists" => true)))
      end
      it { expect(described_class.search({}).selector.to_h).to include("route" => "opendata/dataset") }
      it { expect(described_class.search(keyword: "キーワード", option: 'any_conditions').selector.to_h).to normal_keyword_matcher }
      it { expect(described_class.search(ids: "11,31", option: 'any_conditions').selector.to_h).to ids_matcher }
      # it { expect(described_class.search(name: "名前", keyword: "キーワード").selector.to_h).to normal_name_keyword_matcher }
      # it { expect(described_class.search(name: "名前", modal: true).selector.to_h).to normal_name_modal_matcher }
      # it { expect(described_class.search(name: "名前", keyword: "()[]{}.?+*|\\").selector.to_h).to meta_name_keyword_matcher }
      # it { expect(described_class.search(name: "()[]{}.?+*|\\", modal: true).selector.to_h).to meta_name_modal_matcher }
      it { expect(described_class.search(tag_params).selector.to_h).to tag_matcher }
      it { expect(described_class.search(area_id_params).selector.to_h).to area_id_matcher }
      it { expect(described_class.search(category_id_params).selector.to_h).to category_id_matcher }
      it { expect(described_class.search(dataset_group_params).selector.to_h).to dataset_group_matcher }
      it { expect(described_class.search(format: "csv", option: 'any_conditions').selector.to_h).to format_matcher }
      it { expect(described_class.search(license_id: "28", option: 'any_conditions').selector.to_h).to license_id_matcher }
      it { expect(described_class.search(poster: "admin", option: 'any_conditions').selector.to_h).to poster_admin_matcher }
      it { expect(described_class.search(poster: "member", option: 'any_conditions').selector.to_h).to poster_member_matcher }
    end
  end

  describe ".format_options" do
    context "empty dataset" do
      it { expect(described_class.format_options).to eq [] }
    end

    context "CSV Resource" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
      let(:content_type) { "application/vnd.ms-excel" }
      let(:license_logo_file) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }

      before do
        license = Fs::UploadedFile.create_from_file(license_logo_file, basename: "spec") do |uploaded_file|
          create(:opendata_license, cur_site: node.site, in_file: uploaded_file)
        end

        dataset = create(:opendata_dataset, cur_node: node)
        resource = dataset.resources.new(attributes_for(:opendata_resource))
        Fs::UploadedFile.create_from_file(file, basename: "spec", content_type: content_type) do |uploaded_file|
          resource.in_file = uploaded_file
          resource.license_id = license.id
          resource.save!
        end
      end

      it { expect(described_class.format_options).to include(%w(CSV CSV)) }
    end
  end
end
