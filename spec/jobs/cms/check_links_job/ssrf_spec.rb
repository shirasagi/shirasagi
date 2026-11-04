require 'spec_helper'

describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site) { cms_site }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  context "with private ip address" do
    let!(:layout) { create_cms_layout cur_site: site }
    let(:url1) { "http://10.224.174.6/" }
    let!(:index) do
      html = <<~HTML
        <a href="#{url1}">#{url1}</a>
      HTML
      create :cms_page, cur_site: site, layout: layout, filename: "index.html", html: html, state: "public"
    end

    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        # SSRF を検出した URL は ignore (skip) 扱いのためエラーとして検出されない
        expect(log.logs).to include(include("[0 errors]"))
      end
    end
  end
end
