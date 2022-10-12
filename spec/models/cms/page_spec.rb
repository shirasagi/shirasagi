require 'spec_helper'

describe Cms::Page, type: :model, dbscope: :example do
  describe "factory" do
    let(:factory) { :cms_page }
    it_behaves_like "mongoid#save"
  end

  describe ".first" do
    subject { create :cms_page }
    let(:model) { subject.class }
    it_behaves_like "mongoid#find"
  end

  describe "#attributes" do
    subject(:item) { create :cms_page }
    let(:show_path) { Rails.application.routes.url_helpers.cms_page_path(site: subject.site, id: subject) }

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
    subject { create(:cms_page) }
    it { expect(subject.becomes_with_route("article/page")).to be_kind_of(Article::Page) }
  end

  describe "#name_for_index" do
    let(:item) { create :cms_page }
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
        expect(subject).to be_valid
      end
    end

    context "when absolute path is given" do
      it do
        subject.redirect_link = "/a/b/c"
        expect(subject).to be_valid
      end
    end

    context "when relative host url is given" do
      it do
        subject.redirect_link = "//#{subject.site.domain_with_subdir}/a/b/c"
        expect(subject).to be_valid
      end
    end

    context "when absolute url is given" do
      it do
        subject.redirect_link = "#{subject.site.full_url}/a/b/c"
        expect(subject).to be_valid
      end
    end

    context "when relative untrusted host url is given" do
      before do
        @save_url_type = SS.config.sns.url_type
        SS.config.replace_value_at(:sns, :url_type, "restricted")
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      after do
        SS.config.replace_value_at(:sns, :url_type, @save_url_type)
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      it do
        subject.redirect_link = "//#{unique_domain}/a/b/c"
        expect(subject).to be_invalid
        expect(subject.errors[:redirect_link].length).to eq 1
        expect(subject.errors[:redirect_link]).to include(I18n.t("errors.messages.trusted_url"))
      end
    end

    context "when absolute untrusted host url is given" do
      before do
        @save_url_type = SS.config.sns.url_type
        SS.config.replace_value_at(:sns, :url_type, "restricted")
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      after do
        SS.config.replace_value_at(:sns, :url_type, @save_url_type)
        Sys::TrustedUrlValidator.send(:clear_trusted_urls)
      end

      it do
        subject.redirect_link = "#{unique_url}/a/b/c"
        expect(subject).to be_invalid
        expect(subject.errors[:redirect_link].length).to eq 1
        expect(subject.errors[:redirect_link]).to include(I18n.t("errors.messages.trusted_url"))
      end
    end
  end

  context "database access" do
    let(:site) { cms_site }

    before do
      create :cms_page, cur_site: site
      expect(Cms::Page.all.count).to eq 1
    end

    context "without cur_site" do
      it do
        page = Cms::Page.all.first

        case rand(0..6)
        when 0
          expect { page.path }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 1
          expect { page.url }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 2
          expect { page.full_url }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 3
          expect { page.json_path }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 4
          expect { page.json_url }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 5
          expect { page.preview_path }.to change { MongoAccessCounter.succeeded_count }.by(1)
        when 6
          expect { page.mobile_preview_path }.to change { MongoAccessCounter.succeeded_count }.by(1)
        end
      end
    end

    context "with cur_site" do
      it do
        page = Cms::Page.all.first
        page.cur_site = site

        expect { page.path }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { page.url }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { page.full_url }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { page.json_path }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { page.json_url }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { page.preview_path }.to change { MongoAccessCounter.succeeded_count }.by(0)
        expect { page.mobile_preview_path }.to change { MongoAccessCounter.succeeded_count }.by(0)
      end
    end
  end

  describe ".and_public_selector: able to use with aggregate" do
    let(:now) { Time.zone.now.change(usec: 0) }
    let!(:page1) do
      create :cms_page, state: "public", released_type: "fixed", released: now, release_date: nil, close_date: nil
    end

    context "date is nil" do
      it do
        selector = Cms::Page.and_public_selector(nil)

        expect(Cms::Page.all.where(selector).count).to eq 1
        Cms::Page.collection.aggregate([{ "$match" => selector }]).tap do |result|
          expect(result.count).to eq 1
        end
      end
    end

    context "date is given" do
      it do
        selector = Cms::Page.and_public_selector(now)

        expect(Cms::Page.all.where(selector).count).to eq 1
        Cms::Page.collection.aggregate([{ "$match" => selector }]).tap do |result|
          expect(result.count).to eq 1
        end
      end
    end
  end
end
