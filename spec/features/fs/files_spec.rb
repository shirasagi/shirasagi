require 'spec_helper'

describe "fs_files", dbscope: :example do
  let(:site) { cms_site }
  let(:file) do
    src = Fs::UploadedFile.new("spec")

    src.binmode
    src.write ::File.binread(filename)
    src.rewind
    src.original_filename = ::File.basename(filename)
    src.content_type      = "image/png"

    file = SS::File.new
    file.in_file = src
    file.site_id = site.id
    file.model   = 'article/page'
    file.save
    file.in_file.delete
    file
  end

  context "[logo.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    it "#index" do
      visit file.url
      expect(status_code).to eq 200
    end

    it "#thumb" do
      visit file.thumb_url
      expect(status_code).to eq 200
    end
  end

  # https://github.com/shirasagi/shirasagi/issues/307
  context "[logo.png.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/fs/logo.png.png" }

    it "#index" do
      visit file.url
      expect(status_code).to eq 200
    end

    it "#thumb" do
      visit file.thumb_url
      expect(status_code).to eq 200
    end
  end

  after(:each) do
    Fs.rm_rf "#{Rails.root}/tmp/ss_files"
  end
end
