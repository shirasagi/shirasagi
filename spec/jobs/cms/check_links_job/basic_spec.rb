require 'spec_helper'
describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }
  let!(:site_url) { "http://#{site.domain}/#{site.subdir}" }
  let!(:layout) { create_cms_layout cur_site: site }

  let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html", html: html1 }
  let!(:docs) { create :article_node_page, cur_site: site, layout: layout, filename: "docs" }
  let!(:page1) { create :article_page, cur_site: site, layout: layout, filename: "docs/page1.html", html: html2 }
  let!(:page2) { create :article_page, cur_site: site, layout: layout, filename: "docs/page2.html" }
  let!(:page3) { create :article_page, cur_site: site, layout: layout, filename: "docs/page3.html" }

  before do
    ActionMailer::Base.deliveries = []

    Fs.rm_rf site.path
    expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
    expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
    Job::Log.destroy_all
  end

  after do
    ActionMailer::Base.deliveries = []

    Fs.rm_rf site.path
  end

  let!(:html1) do
    <<~HTML
      <a href="#{docs.url}">#{docs.name}</a>
      <a href="#{page1.url}">#{page1.name}</a>
      <a href="#{page2.url}">#{page2.name}</a>
      <a href="#{site.url}notfound1.html">notfound1</a>
      <!-- <a href="#{site.url}commentout1.html">commentout1</a> -->
      <!--
        <a href="#{site.url}commentout2.html">commentout2.html</a>
      -->
    HTML
  end

  let!(:html2) do
    <<~HTML
      <a href="#{site.url}index.html">#{site.name}</a>
      <a href="#{page3.url}">#{page3.name}</a>
      <a href="#{site.url}notfound2.html">notfound2</a>
    HTML
  end

  context "normal case" do
    it do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/3 errors/).to_stdout

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

      expect(Cms::CheckLinks::Report.all.count).to eq 1
      Cms::CheckLinks::Report.all.first.tap do |report|
        expect(report.site_id).to eq site.id
        expect(report.name).to include "実行結果"
        expect(report.link_errors.count).to eq 2
        expect(report.pages.count).to eq 2
        expect(report.nodes.count).to eq 0
        report.pages.to_a.tap do |page_reports|
          expect(page_reports[0].site_id).to eq site.id
          expect(page_reports[0].report_id).to eq report.id
          expect(page_reports[0].ref).to eq index.url
          expect(page_reports[0].ref_url).to eq index.full_url
          expect(page_reports[0].name).to eq index.name
          expect(page_reports[0].filename).to eq index.filename
          expect(page_reports[0].urls).to have(1).items
          expect(page_reports[0].urls).to include("#{site.url}notfound1.html")
          expect(page_reports[0].page_id).to eq index.id

          expect(page_reports[1].site_id).to eq site.id
          expect(page_reports[1].report_id).to eq report.id
          expect(page_reports[1].ref).to eq page1.url
          expect(page_reports[1].ref_url).to eq page1.full_url
          expect(page_reports[1].name).to eq page1.name
          expect(page_reports[1].filename).to eq page1.filename
          expect(page_reports[1].urls).to have(1).items
          expect(page_reports[1].urls).to include("#{site.url}notfound2.html")
          expect(page_reports[1].page_id).to eq page1.id
        end
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
        expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/3 errors/).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.check_links_default_sender_address
        expect(mail.to.first).to eq email1
        expect(mail_subject(mail)).to eq "[#{site.name}] Link Check: 3 errors"
        expect(mail_body(mail)).to include "[3 errors]"
        expect(mail_body(mail)).to include "#{site_url}/"
        expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
        expect(mail_body(mail)).to include "#{site_url}/index.html"
        expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
        expect(mail_body(mail)).to include "#{site_url}/docs/page1.html"
        expect(mail_body(mail)).to include "  - #{site_url}/notfound2.html"
      end
    end

    context "format csv" do
      let!(:message_format) { "csv" }

      it do
        expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/3 errors/).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.check_links_default_sender_address
        expect(mail.to.first).to eq email1

        expect(mail_subject(mail)).to eq "[#{site.name}] Link Check: 3 errors"
        expect(mail.multipart?).to be_truthy
        expect(mail.parts[0].body.raw_source).to include "[3 errors]"
        expect(mail.parts[0].body.raw_source).to include "error details are in the attached csv"

        csv = mail.parts[1].body.raw_source
        csv = csv.delete_prefix(SS::Csv::UTF8_BOM)
        csv = CSV.parse(csv)

        expect(csv[0]).to eq %w(reference url)
        expect(csv[1]).to eq %W(#{site.url} #{site.url}notfound1.html)
        expect(csv[3]).to eq %W(#{site.url}index.html #{site.url}notfound1.html)
        expect(csv[2]).to eq %W(#{site.url}docs/page1.html #{site.url}notfound2.html)
      end
    end

    context "set email in task arguments" do
      let!(:message_format) { "text" }

      it do
        expect { ss_perform_now described_class.bind(site_id: site.id), email: email2 }.to output(/3 errors/).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(ActionMailer::Base.deliveries.length).to eq 1
        mail = ActionMailer::Base.deliveries.first
        expect(mail.from.first).to eq site.check_links_default_sender_address
        expect(mail.to.first).to eq email2
        expect(mail_subject(mail)).to eq "[#{site.name}] Link Check: 3 errors"
        expect(mail_body(mail)).to include "[3 errors]"
        expect(mail_body(mail)).to include "#{site_url}/"
        expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
        expect(mail_body(mail)).to include "#{site_url}/index.html"
        expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
        expect(mail_body(mail)).to include "#{site_url}/docs/page1.html"
        expect(mail_body(mail)).to include "  - #{site_url}/notfound2.html"
      end
    end
  end
end
