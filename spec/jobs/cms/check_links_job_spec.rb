require 'spec_helper'
describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:site_url) { "http://#{site.domain}" }
  let!(:layout) { create_cms_layout }

  let!(:index) { create :cms_page, cur_site: site, layout_id: layout.id, filename: "index.html", html: html1 }
  let!(:docs) { create :article_node_page, cur_site: site, layout_id: layout.id, filename: "docs" }
  let!(:page1) { create :article_page, cur_site: site, layout_id: layout.id, filename: "docs/page1.html", html: html2 }
  let!(:page2) { create :article_page, cur_site: site, layout_id: layout.id, filename: "docs/page2.html" }
  let!(:page3) { create :article_page, cur_site: site, layout_id: layout.id, filename: "docs/page3.html" }

  before do
    ActionMailer::Base.deliveries = []

    Fs.rm_rf site.path
    Cms::Node::GenerateJob.bind(site_id: site.id).perform_now
    Cms::Page::GenerateJob.bind(site_id: site.id).perform_now
    Job::Log.destroy_all
  end

  after do
    ActionMailer::Base.deliveries = []

    Fs.rm_rf site.path
  end

  let!(:html1) do
    h = []
    h << '<a href="/docs/">docs</a>'
    h << '<a href="/docs/page1.html">page1</a>'
    h << '<a href="/docs/page2.html">page2</a>'
    h << '<a href="/notfound1.html">notfound1</a>'
    h << '<!-- <a href="/commentout1.html">commentout1</a> -->'
    h << '<!--'
    h << '  <a href="/commentout2.html">commentout2.html</a>'
    h << '-->'
    h.join("\n")
  end

  let!(:html2) do
    h = []
    h << '<a href="/index.html">index</a>'
    h << '<a href="/docs/page3.html">page3</a>'
    h << '<a href="/notfound2.html">notfound2</a>'
    h.join("\n")
  end

  context "normal case" do
    it do
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
        expect(log.logs).to include(include("  - #{site_url}/notfound1.html"))
        expect(log.logs).not_to include(include("  - #{site_url}/commentout1.html"))

        expect(log.logs).to include(include("#{site_url}/index.html"))
        expect(log.logs).to include(include("  - #{site_url}/notfound1.html"))

        expect(log.logs).to include(include("#{site_url}/docs/page1.html"))
        expect(log.logs).to include(include("  - #{site_url}/notfound2.html"))
        expect(log.logs).not_to include(include("  - #{site_url}/commentout2.html"))
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end

  context "send mail" do
    let!(:email1) { "#{unique_id}@example.jp" }
    let!(:email2) { "#{unique_id}@example.jp" }

    before do
      site.check_links_email = email1
      site.check_links_message_format = message_format
      site.update!
    end

    context "format text" do
      let!(:message_format) { "text" }

      it do
        ss_perform_now described_class.bind(site_id: site.id)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.check_links_default_sender_address
        expect(mail.to.first).to eq email1
        expect(mail.subject).to eq "[#{site.name}] Link Check: 3 errors"
        expect(mail.body.raw_source).to include "[3 errors]"
        expect(mail.body.raw_source).to include "#{site_url}/"
        expect(mail.body.raw_source).to include "  - #{site_url}/notfound1.html"
        expect(mail.body.raw_source).to include "#{site_url}/index.html"
        expect(mail.body.raw_source).to include "  - #{site_url}/notfound1.html"
        expect(mail.body.raw_source).to include "#{site_url}/docs/page1.html"
        expect(mail.body.raw_source).to include "  - #{site_url}/notfound2.html"
      end
    end

    context "format csv" do
      let!(:message_format) { "csv" }

      it do
        ss_perform_now described_class.bind(site_id: site.id)

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.check_links_default_sender_address
        expect(mail.to.first).to eq email1

        expect(mail.subject).to eq "[#{site.name}] Link Check: 3 errors"
        expect(mail.multipart?).to be_truthy
        expect(mail.parts[0].body.raw_source).to include "[3 errors]"
        expect(mail.parts[0].body.raw_source).to include "error details are in the attached csv"

        csv = mail.parts[1].body.raw_source
        csv = csv.delete_prefix(SS::Csv::UTF8_BOM)
        csv = CSV.parse(csv)

        expect(csv[0]).to eq %w(reference url)
        expect(csv[1]).to eq %w(/ /notfound1.html)
        expect(csv[2]).to eq %w(/index.html /notfound1.html)
        expect(csv[3]).to eq %w(/docs/page1.html /notfound2.html)
      end
    end

    context "set email in task arguments" do
      let!(:message_format) { "text" }

      it do
        ss_perform_now described_class.bind(site_id: site.id), email: email2

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.check_links_default_sender_address
        expect(mail.to.first).to eq email2
        expect(mail.subject).to eq "[#{site.name}] Link Check: 3 errors"
        expect(mail.body.raw_source).to include "[3 errors]"
        expect(mail.body.raw_source).to include "#{site_url}/"
        expect(mail.body.raw_source).to include "  - #{site_url}/notfound1.html"
        expect(mail.body.raw_source).to include "#{site_url}/index.html"
        expect(mail.body.raw_source).to include "  - #{site_url}/notfound1.html"
        expect(mail.body.raw_source).to include "#{site_url}/docs/page1.html"
        expect(mail.body.raw_source).to include "  - #{site_url}/notfound2.html"
      end
    end
  end
end
