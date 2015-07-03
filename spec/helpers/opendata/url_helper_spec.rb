require 'spec_helper'

describe Opendata::UrlHelper, type: :helper, dbscope: :example do
  let(:icon_file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:icon_file) { Fs::UploadedFile.create_from_file(icon_file_path) }

  describe ".member_icon" do
    context "when menber has icon" do
      let(:member) { create(:opendata_member, icon_file: icon_file) }
      subject { helper.member_icon(member) }
      it { is_expected.to eq '<img alt="" src="/fs/1/_/logo.png" />' }
    end

    context "when menber doesn't have icon" do
      let(:member) { create(:opendata_member) }
      subject { helper.member_icon(member) }
      it { is_expected.to eq '<img alt="" src="/assets/opendata/icon-user.png" />' }
    end

    context "when size parameter is given" do
      let(:member) { create(:opendata_member) }
      subject { helper.member_icon(member, size: :small) }
      it { is_expected.to eq '<img alt="" width="38" height="38" src="/assets/opendata/icon-user.png" />' }
    end

    context "when alt parameter is given" do
      let(:member) { create(:opendata_member) }
      subject { helper.member_icon(member, alt: "alt") }
      it { is_expected.to eq '<img alt="alt" src="/assets/opendata/icon-user.png" />' }
    end
  end

  describe ".build_path" do
    context "when sort parameter is given" do
      subject { helper.build_path "/dataset/search/", "sort" => "popular" }
      it { is_expected.to eq "/dataset/search/?sort=popular" }
    end

    context "when s[area] parameter is given" do
      subject { helper.build_path "/dataset/search/", "s[area]" => "32" }
      it { is_expected.to eq "/dataset/search/?s%5Barea%5D=32" }
    end

    context "when s[tag] parameter is given" do
      subject { helper.build_path "/dataset/search/", "s[tag]" => "人口" }
      it { is_expected.to eq "/dataset/search/?s%5Btag%5D=%E4%BA%BA%E5%8F%A3" }
    end

    context "when s[format] parameter is given" do
      subject { helper.build_path "/dataset/search/", "s[format]" => "XLS" }
      it { is_expected.to eq "/dataset/search/?s%5Bformat%5D=XLS" }
    end

    context "when s[license] parameter is given" do
      subject { helper.build_path "/dataset/search/", "s[license]" => "2" }
      it { is_expected.to eq "/dataset/search/?s%5Blicense%5D=2" }
    end

    context "when composite parameters is given" do
      subject do
        helper.build_path "/dataset/search/",
                          "sort" => "popular",
                          "s[area]" => "32",
                          "s[tag]" => "人口"
      end
      it { is_expected.to eq "/dataset/search/?s%5Barea%5D=32&s%5Btag%5D=%E4%BA%BA%E5%8F%A3&sort=popular" }
    end
  end

  describe ".search_datasets_path" do
    before do
      @cur_site = cms_site
      @search_dataset = create :opendata_node_search_dataset
    end
    subject { helper.search_datasets_path }
    it { is_expected.to eq @search_dataset.url }
  end

  describe ".search_groups_path" do
    before do
      @cur_site = cms_site
      @search_dataset_group = create :opendata_node_search_dataset_group
    end
    subject { helper.search_groups_path }
    it { is_expected.to eq @search_dataset_group.url }
  end

  describe ".search_apps_path" do
    before do
      @cur_site = cms_site
      @search_app = create :opendata_node_search_app
    end
    subject { helper.search_apps_path }
    it { is_expected.to eq @search_app.url }
  end

  describe ".search_ideas_path" do
    before do
      @cur_site = cms_site
      @search_idea = create :opendata_node_search_idea
    end
    subject { helper.search_ideas_path }
    it { is_expected.to eq @search_idea.url }
  end

  describe ".sparql_path" do
    before do
      @cur_site = cms_site
      @sparql = create :opendata_node_sparql
    end
    subject { helper.sparql_path }
    it { is_expected.to eq @sparql.url }
  end

  describe ".mypage_path" do
    before do
      @cur_site = cms_site
      @mypage = create :opendata_node_mypage
    end
    subject { helper.mypage_path }
    it { is_expected.to eq @mypage.url }
  end

  describe ".member_path" do
    before do
      @cur_site = cms_site
      @member = create :opendata_node_member
    end
    subject { helper.member_path }
    it { is_expected.to eq @member.url }
  end

  describe ".mypage_path" do
    before do
      @cur_site = cms_site
      @mypage = create :opendata_node_mypage
    end
    subject { helper.mypage_path }
    it { is_expected.to eq @mypage.url }
  end
end
