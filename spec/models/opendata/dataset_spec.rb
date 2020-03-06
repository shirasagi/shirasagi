require 'spec_helper'

describe Opendata::Dataset, dbscope: :example do
  let!(:node_category) { create(:opendata_node_category) }
  let!(:node_search_dataset) { create(:opendata_node_search_dataset) }
  let(:node) { create(:opendata_node_dataset) }

  describe "#attributes" do
    let(:item) { create :opendata_dataset, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.opendata_dataset_path(site: item.site, cid: node, id: item.id) }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end

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
      it { expect(described_class.format_options(cms_site)).to eq [] }
    end

    context "CSV Resource" do
      let(:file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
      let(:content_type) { "application/vnd.ms-excel" }

      before do
        license = create(:opendata_license, cur_site: node.site)

        dataset = create(:opendata_dataset, cur_node: node)
        resource = dataset.resources.new(attributes_for(:opendata_resource))
        Fs::UploadedFile.create_from_file(file, basename: "spec", content_type: content_type) do |uploaded_file|
          resource.in_file = uploaded_file
          resource.license_id = license.id
          resource.save!
        end
      end

      it { expect(described_class.format_options(cms_site)).to include(%w(CSV(1) CSV)) }
    end
  end

  describe "dataset copy" do
    subject { org_dataset.new_clone }

    around do |example|
      Timecop.freeze(Time.zone.now) do
        example.run
      end
    end

    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let(:license) { create(:opendata_license, cur_site: site) }
    let(:org_dataset) do
      dataset = create(:opendata_dataset, dataset_attributes)
      dataset.instance_variable_set(:@cur_node, node)
      dataset.instance_variable_set(:@cur_site, site)
      dataset.instance_variable_set(:@cur_user, user)
      dataset
    end
    let(:dataset_attributes) do
      {
        cur_node: node,
        site_id: site.id,
        user_id: user.id,
        permission_level: 1,
        group_ids: [1],
        state: "public",
        order: 1,
        category_ids: [1],
        related_page_ids: [1],
        related_page_sort: "name",
        created: Time.zone.yesterday,
        updated: Time.zone.yesterday,
        name: "test dataset",
        area_ids: [1],
        point: 1,
        text: "text",
        tags: %w(tag),
        member_id: 1,
        dataset_group_ids: [1],
        contact_state: "hide",
        contact_charge: "test charge",
        contact_tel: "0000-00-00000",
        contact_fax: "0000-00-00001",
        contact_email: "test@example.jp",
        contact_link_url: "http://example.jp",
        contact_link_name: "test link",
        contact_group_id: 1
      }
    end

    def upload_file(file, content_type = nil)
      uploaded_file = Fs::UploadedFile.create_from_file(file, basename: "spec")
      uploaded_file.content_type = content_type || "application/octet-stream"
      uploaded_file
    end

    it do
      target = subject
      expect_reset_fields = {
        id: nil,
        cur_user: user,
        cur_site: site,
        cur_node: node,
        state: "closed",
        created: Time.zone.now,
        updated: Time.zone.now,
        released: nil,
        related_page_ids: [],
        related_page_sort: nil,
        point: 0,
        downloaded: 0
      }
      expect_reset_fields.each { |k, v| expect(target.send(k)).to eq(v) }
      expect_copy_fields = dataset_attributes.reject { |k, v| expect_reset_fields.key?(k) }
      expect_copy_fields.each { |k, v| expect(subject.send(k)).to eq(v) }
    end

    describe "related file resouces copy" do
      subject do
        dataset = org_dataset.new_clone
        dataset.save
        dataset.resources.first
      end

      let!(:file_resource) do
        file = Rails.root.join("spec", "fixtures", "opendata", "test.json")
        resource_attributes = attributes_for(:opendata_resource)
        resource_attributes.merge!(
          created: Time.zone.yesterday,
          updated: Time.zone.yesterday,
          license_id: license.id,
          in_file: upload_file(file, "application/json"),
          in_tsv: upload_file(file, "application/json")
        )
        resource = org_dataset.resources.new(resource_attributes)
        resource.save!
        resource.in_file.close
        resource
      end

      it do
        expect(subject.id).not_to eq file_resource.id
        expect(subject.created).to eq Time.zone.now
        expect(subject.updated).to eq Time.zone.now
        expect(subject.file_id).not_to eq file_resource.file_id
        expect(subject.file.uploaded_file.read).to eq file_resource.file.uploaded_file.read
        expect(subject.tsv_id).not_to eq file_resource.tsv_id
        expect(subject.tsv.uploaded_file.read).to eq file_resource.tsv.uploaded_file.read
        expect_copy_fields = [
          :name,
          :text,
          :format,
          :license_id,
          :filename
        ]
        expect_copy_fields.each { |k| expect(subject.send(k)).to eq(file_resource.send(k)) }
      end
    end

    describe "related url resoruces copy" do
      subject do
        dataset = org_dataset.new_clone
        dataset.save
        dataset.url_resources.first
      end

      let!(:url_resource) do
        file = Rails.root.join("spec", "fixtures", "opendata", "test.json")
        resource_attributes = attributes_for(:opendata_url_resource)
        resource_attributes.merge!(
          created: Time.zone.yesterday,
          updated: Time.zone.yesterday,
          license_id: license.id,
          in_file: upload_file(file, "application/json"),
          original_url: "http://test@example.jp/test.json",
          original_updated: Time.zone.yesterday,
          crawl_state: "same",
          crawl_update: "none",
          format: "JSON"
        )
        resource = org_dataset.url_resources.new(resource_attributes)
        resource.save!
        resource.in_file.close
        resource
      end

      it do
        expect(subject.id).not_to eq url_resource.id
        expect(subject.created).to eq Time.zone.now
        expect(subject.updated).to eq Time.zone.now
        expect(subject.file_id).not_to eq url_resource.file_id
        expect(subject.file.uploaded_file.read).to eq url_resource.file.uploaded_file.read
        expect_copy_fields = [
          :name,
          :text,
          :format,
          :license_id,
          :filename,
          :original_url,
          :original_updated,
          :crawl_state,
          :crawl_update
        ]
        expect_copy_fields.each { |k| expect(subject.send(k)).to eq(url_resource.send(k)) }
      end
    end
  end
end
