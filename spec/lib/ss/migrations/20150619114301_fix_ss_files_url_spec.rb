require 'spec_helper'
require Rails.root.join('lib/migrations/ss/20150619114301_fix_ss_files_url')

RSpec.describe SS::Migration20150619114301, dbscope: :example do
  let(:before_html_path) { Rails.root.join("spec/fixtures/ss/migration/fix_ss_files_url/before.html") }
  let(:before_layout_html_path) { Rails.root.join("spec/fixtures/ss/migration/fix_ss_files_url/before_layout.html") }
  let(:after_html_path) { Rails.root.join("spec/fixtures/ss/migration/fix_ss_files_url/after.html") }
  let(:after_layout_html_path) { Rails.root.join("spec/fixtures/ss/migration/fix_ss_files_url/after_layout.html") }

  before do
    @before_html = ::File.open(before_html_path).read
    @before_layout_html = ::File.open(before_layout_html_path).read
    @after_html = ::File.open(after_html_path).read
    @after_layout_html = ::File.open(after_layout_html_path).read

    create_once :cms_page, name: "cms_page", html: @before_html
    create_once :article_page, name: "article_page", html: @before_html
    create_once :cms_part_free, name: "free_part", html: @before_html
    create_once :article_part_page, name: "list_part", upper_html: @before_html, lower_html: @before_html
    create_once :cms_layout, name: "layout", html: @before_layout_html

    SS.config.replace_value_at(:env, :multibyte_filename, "underscore")
    SS::File.destroy_all
    file = SS::File.new
    file.in_file = Fs::UploadedFile.create_from_file("spec/fixtures/ss/logo.png")
    file.model = "ss/file"
    file.id = 1000
    file.save!
    file.set(filename: "ロゴ.png")
    file.set(name: nil)
  end

  it do
    described_class.new.change

    Cms::Page.all.each do |item|
      expect(item.html).to eq(@after_html.strip)
    end

    Cms::Part.all.each do |item|
      expect(item.html).to eq(@after_html.strip) if item.respond_to?(:html)
      expect(item.upper_html).to eq(@after_html.strip) if item.respond_to?(:upper_html)
      expect(item.lower_html).to eq(@after_html.strip) if item.respond_to?(:lower_html)
    end

    Cms::Layout.all.each do |item|
      expect(item.html).to eq(@after_layout_html.strip)
    end
  end
end
