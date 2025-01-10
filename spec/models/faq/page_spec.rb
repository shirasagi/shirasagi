require 'spec_helper'

describe Faq::Page, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :faq_node_page, cur_site: site }
  subject { create :faq_page, cur_site: site, cur_node: node }
  let(:show_path) { Rails.application.routes.url_helpers.faq_page_path(site: subject.site, cid: subject.parent, id: subject) }

  describe "#attributes" do
    it { expect(subject.dirname).to eq node.filename }
    it { expect(subject.basename).not_to eq nil }
    it { expect(subject.path).not_to eq nil }
    it { expect(subject.url).not_to eq nil }
    it { expect(subject.full_url).not_to eq nil }
    it { expect(subject.parent).to eq node }
    it { expect(subject.private_show_path).to eq show_path }
  end

  describe "validation" do
    let(:site_limit0) { create :cms_site_unique, max_name_length: 0 }
    let(:site_limit80) { create :cms_site_unique, max_name_length: 80 }

    it "basename" do
      item = build(:faq_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end

    it "name with limit 0" do
      item = build(:faq_page_10_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:faq_page_100_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy

      item = build(:faq_page_1000_characters_name, cur_site: site_limit0)
      expect(item.valid?).to be_truthy
    end

    it "name with limit 80" do
      item = build(:faq_page_10_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_truthy

      item = build(:faq_page_100_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey

      item = build(:faq_page_1000_characters_name, cur_site: site_limit80)
      expect(item.valid?).to be_falsey
    end
  end

  describe ".new_size_input" do
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:file) do
      SS::File.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, model: "faq/page", filename: "logo.png", content_type: 'image/png'
      ) do |file|
        ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
      end
    end
    let!(:column1) { create(:cms_column_free, cur_form: form, order: 1) }
    let!(:column2) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'image', html_tag: "a+img") }
    let!(:html_size) { html.bytesize }
    let(:question_size) { question.bytesize }
    let!(:file_size) { File.size(file.path) }

    context "with html only" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:item) { create :faq_page, cur_node: node, html: html }

      it do
        expect(item.size).to eq html_size
      end
    end

    context "with question only" do
      let!(:question) { "<h2>SHIRASAGI</h2>" }
      let!(:item) { create :faq_page, cur_node: node, question: question }

      it do
        expect(item.size).to eq question_size
      end
    end

    context "with file only" do
      let!(:item) { create :faq_page, cur_node: node, file_ids: [file.id] }
      it do
        expect(item.size).to eq file_size
      end
    end

    context "with html and question and file" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:question) { "<h2>SHIRASAGI</h2>" }
      let!(:item) { create :faq_page, cur_node: node, html: html, question: question, file_ids: [file.id] }

      it do
        expect(item.size).to eq html_size + question_size + file_size
      end
    end
  end

end
