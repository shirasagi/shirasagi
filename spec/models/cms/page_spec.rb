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

  # check_mobile_html_size at addon body
  describe "addon body" do
    let(:html) { "<p>本文本文</p>" }
    let(:item) { create(:cms_page, route: "article/page", html: html) }
    context "check_mobile_html_size" do

      it "html_size too big" do
        item.site.mobile_size = 1
        item.site.mobile_state = 'enabled'
        100.times.each do
          item.html += "<p>あいうえおカキクケコ</p>"
        end
        expect(item.save).to be_falsey

        item.site.mobile_state = 'disabled'
        expect(item.save).to be_truthy
      end

      it "html_size ok" do
        item.site.mobile_size = 1
        expect(item.valid?).to be_truthy

        item.html = "<p>あいうえおカキクケコ</p>"
        expect(item.valid?).to be_truthy
      end

      context "file_size" do
        let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
        it "mobile_size 1/1000 and 100" do
          file = Cms::File.new model: "cms/file", site_id: item.site.id
          Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") do |test_file|
            file.in_file = test_file
            file.save!
          end
          item.file_ids = [file.id]
          item.html += "<img src=\"/fs/#{file.id}/_/\""
          item.site.mobile_size = 1/1000
          expect(item.valid?).to be_falsey

          item.site.mobile_size = 100
          expect(item.valid?).to be_truthy
        end

        it "many same files in html" do
          file = Cms::File.new model: "cms/file", site_id: item.site.id
          Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") do |test_file|
            file.in_file = test_file
            file.save!
          end
          item.file_ids = [file.id]
          item.site.mobile_size = 20
          item.html += "<img src=\"/fs/#{file.id}/_/\">"
          expect(item.valid?).to be_truthy
          10.times.each do
            item.html += "<img src=\"/fs/#{file.id}/_/\">"
          end

          expect(item.valid?).to be_truthy

        end

        it "many different files in html" do
          file = Cms::File.new model: "cms/file", site_id: item.site.id
          Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") do |test_file|
            file.in_file = test_file
            file.save!
          end
          file2 = Cms::File.new model: "cms/file", site_id: item.site.id
          file_path = Rails.root.join("spec", "fixtures", "ss", "file", "keyvisual.jpg")
          Fs::UploadedFile.create_from_file(file_path, basename: "spec") do |test_file|
            file2.in_file = test_file
            file2.save!
          end

          item.file_ids = [file.id, file2.id]
          item.site.mobile_size = 20

          item.html += "<img src=\"/fs/#{file.id}/_/\">"
          expect(item.valid?).to be_truthy

          item.html += "<img src=\"/fs/#{file2.id}/_/\">"
          expect(item.valid?).to be_falsey
        end

      end
    end
  end
end
