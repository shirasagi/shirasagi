require 'spec_helper'

describe "fs_files", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file) do
    basename = ::File.basename(filename)
    SS::File.create_empty!(
      site_id: site.id, cur_user: cms_user, name: basename, filename: basename,
      content_type: "image/png", model: 'article/page'
    ) do |file|
      ::FileUtils.cp(filename, file.path)
    end
  end

  context "[logo.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    context "without auth" do
      it "#index" do
        visit file.url
        expect(status_code).to eq 404
      end

      it "#thumb" do
        visit file.thumb_url
        expect(status_code).to eq 404
      end
    end

    context "with auth" do
      before { login_cms_user }

      it "#index" do
        visit file.url
        expect(status_code).to eq 200
      end

      it "#thumb" do
        visit file.thumb_url
        expect(status_code).to eq 200
      end
    end
  end

  # https://github.com/shirasagi/shirasagi/issues/307
  context "[logo.png.png]" do
    let(:filename) { "#{Rails.root}/spec/fixtures/fs/logo.png.png" }

    context "without auth" do
      it "#index" do
        visit file.url
        expect(status_code).to eq 404
      end

      it "#thumb" do
        visit file.thumb_url
        expect(status_code).to eq 404
      end
    end

    context "with auth" do
      before { login_cms_user }

      it "#index" do
        visit file.url
        expect(status_code).to eq 200
      end

      it "#thumb" do
        visit file.thumb_url
        expect(status_code).to eq 200
      end
    end
  end

  context "error page" do
    let(:url) { "/fs/1/_/error.png" }
    let(:item) { create :cms_page, filename: "404.html", name: "404", html: unique_id.to_s }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "without auth" do
      it "when not created 404.html" do
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_falsey
      end

      it "when created 404.html" do
        item
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_truthy
      end
    end

    context "with auth" do
      before { login_cms_user }

      it "when not created 404.html" do
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_falsey
      end

      it "when created 404.html" do
        visit url
        expect(status_code).to eq 404
        expect(page.html.include?(item.html)).to be_falsey
      end
    end
  end

  after(:each) do
    Fs.rm_rf "#{Rails.root}/tmp/ss_files"
  end
end
