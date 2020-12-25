require 'spec_helper'

describe Cms::Page do
  subject(:model) { Cms::Page }
  subject(:factory) { :cms_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }
    let(:show_path) { Rails.application.routes.url_helpers.cms_page_path(site: subject.site, id: subject) }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.parent).to eq false }
    it { expect(item.private_show_path).to eq show_path }
  end

  describe "#attributes with node" do
    let(:node) { create :cms_node_page }
    let(:item) { create :cms_page, cur_node: node }
    let(:show_path) { Rails.application.routes.url_helpers.node_page_path(site: item.site, cid: node.id, id: item.id) }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.parent).to eq node }
    it { expect(item.private_show_path).to eq show_path }
  end

  describe "validation" do
    let(:site_limit0) { create :cms_site_unique, max_name_length: 0 }
    let(:site_limit80) { create :cms_site_unique, max_name_length: 80 }

    it "basename" do
      item = build(:cms_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end

    it "name with limit 0" do
      item = build(:cms_page_10_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:cms_page_100_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:cms_page_1000_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy
    end

    it "name with limit 80" do
      item = build(:cms_page_10_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_truthy

      item = build(:cms_page_100_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey

      item = build(:cms_page_1000_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey
    end
  end

  describe "#becomes_with_route" do
    subject { create(:cms_page, route: "article/page") }
    it { expect(subject.becomes_with_route).to be_kind_of(Article::Page) }
  end

  describe "#name_for_index" do
    let(:item) { model.last }
    subject { item.name_for_index }

    context "the value is set" do
      before { item.index_name = "Name for index" }
      it { is_expected.to eq "Name for index" }
    end

    context "the value isn't set" do
      it { is_expected.to eq item.name }
    end
  end

  describe "#redirect_link" do
    subject { create(:cms_page, route: "article/page") }

    context "when relative path is given" do
      it do
        subject.redirect_link = "a/b/c"
        expect(subject).to be_invalid
        expect(subject.errors[:redirect_link].length).to eq 1
        expect(subject.errors[:redirect_link]).to include(I18n.t("errors.messages.trusted_url"))
      end

      context "when absolute path is given" do
        it do
          subject.redirect_link = "/a/b/c"
          expect(subject).to be_valid
        end
      end

      context "when site url is given" do
        it do
          subject.redirect_link = "#{subject.site.full_url}/a/b/c"
          expect(subject).to be_valid
        end
      end
    end
  end
end
