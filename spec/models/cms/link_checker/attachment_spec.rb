require 'spec_helper'

describe Cms::LinkChecker, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    Fs.rm_rf site0.path
  end

  after do
    Fs.rm_rf site0.path
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  context "with PDF under /fs/" do
    let!(:user) { cms_user }
    let!(:file) do
      content_path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
      tmp_ss_file(Cms::TempFile, site: site, user: user, contents: content_path)
    end
    let!(:layout) { create_cms_layout cur_site: site }
    let!(:index) do
      create :cms_page, cur_site: site, cur_user: user, layout: layout, filename: "index.html", file_ids: [ file.id ]
    end

    before do
      html1 = <<~HTML
        <p><a class="icon-pdf" href="#{file.url}">#{file.humanized_name}</a></p>
      HTML
      index.update!(html: html1)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      Job::Log.destroy_all

      file.reload
    end

    it do
      checker = Cms::LinkChecker.new(root_url: site.full_url, fetch_content: true)
      result = checker.check_url(file.full_url)
      expect(result.success?).to be_truthy
      expect(result.result).to eq :success
      expect(result.error_code).to be_blank
      expect(result.redirection_count).to eq 0
      expect(result.content_type).to eq "application/pdf"
      expect(result.content).to be_blank
    end
  end
end
