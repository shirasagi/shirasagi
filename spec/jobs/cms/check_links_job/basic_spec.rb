require 'spec_helper'

describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }
  let!(:site_url) { "http://#{site.domain}/#{site.subdir}" }
  let!(:layout) { create_cms_layout cur_site: site }

  before do
    WebMock.disable_net_connect!
    ActionMailer::Base.deliveries = []
    Fs.rm_rf site.path
  end

  after do
    ActionMailer::Base.deliveries = []
    Fs.rm_rf site.path
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  context "normal case" do
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }
    let!(:docs) { create :article_node_page, cur_site: site, layout: layout, filename: "docs" }
    let!(:page1) { create :article_page, cur_site: site, layout: layout, filename: "docs/page1.html" }
    let!(:page2) { create :article_page, cur_site: site, layout: layout, filename: "docs/page2.html" }
    let!(:page3) { create :article_page, cur_site: site, layout: layout, filename: "docs/page3.html" }

    before do
      html1 = <<~HTML
        <a href="#{docs.url}">#{docs.name}</a>
        <a href="#{page1.url}">#{page1.name}</a>
        <a href="#{page2.url}">#{page2.name}</a>
        <a href="#{site.url}notfound1.html">notfound1</a>
        <!-- <a href="#{site.url}commentout1.html">commentout1</a> -->
        <!--
          <a href="#{site.url}commentout2.html">commentout2.html</a>
        -->
      HTML
      index.update!(html: html1)

      html2 = <<~HTML
        <a href="#{site.url}index.html">#{site.name}</a>
        <a href="#{page3.url}">#{page3.name}</a>
        <a href="#{site.url}notfound2.html">notfound2</a>
      HTML
      page1.update!(html: html2)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout

      Job::Log.destroy_all
    end

    context "check" do
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

  context "when a node include break links" do
    let!(:index) { create :cms_page, cur_site: site, layout: layout, basename: "index.html" }
    let!(:docs) { create(:article_node_page, cur_site: site, layout: layout, basename: "docs") }
    let!(:docs_page1) { create(:article_page, cur_site: site, layout: layout, cur_node: docs, basename: "page1.html") }
    let!(:docs_page2) { create(:article_page, cur_site: site, layout: layout, cur_node: docs, basename: "page2.html") }

    before do
      html = <<~HTML
        <a href="#{docs.url}">"#{docs.name}"</a>
      HTML
      index.update!(html: html)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout

      Job::Log.destroy_all
      docs_page2.destroy!
    end

    context "check" do
      it do
        expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/1 errors/).to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)

          expect(log.logs).to include(include("#{site_url}/docs/"))
          expect(log.logs).to include(include("  - #{site_url}/docs/page2.html"))
        end

        expect(Cms::CheckLinks::Report.all.count).to eq 1
        Cms::CheckLinks::Report.all.first.tap do |report|
          expect(report.site_id).to eq site.id
          expect(report.name).to include "実行結果"
          expect(report.link_errors.count).to eq 1
          expect(report.pages.count).to eq 0
          expect(report.nodes.count).to eq 1
          report.nodes.to_a.tap do |node_reports|
            expect(node_reports[0].site_id).to eq site.id
            expect(node_reports[0].report_id).to eq report.id
            expect(node_reports[0].ref).to eq docs.url
            expect(node_reports[0].ref_url).to eq docs.full_url
            expect(node_reports[0].name).to eq docs.name
            expect(node_reports[0].filename).to eq docs.filename
            expect(node_reports[0].urls).to have(1).items
            expect(node_reports[0].urls).to include(docs_page2.url)
            expect(node_reports[0].node_id).to eq docs.id
          end
        end

        expect(ActionMailer::Base.deliveries.length).to eq 0
      end
    end
  end

  context "some other schemes" do
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }

    before do
      html1 = <<~HTML
        <a href="mailto:#{unique_email}">Mail Me!</a>
        <a href="javascript:void(0);">Nothing Happened!</a>
      HTML
      index.update!(html: html1)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout

      Job::Log.destroy_all
    end

    it do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/0 errors/).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
      end

      expect(Cms::CheckLinks::Report.all.count).to eq 1
      Cms::CheckLinks::Report.all.first.tap do |report|
        expect(report.site_id).to eq site.id
        expect(report.name).to include "実行結果"
        expect(report.link_errors.count).to eq 0
        expect(report.pages.count).to eq 0
        expect(report.nodes.count).to eq 0
      end
    end
  end

  context "fragment" do
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }

    before do
      html1 = <<~HTML
        <h1 id="top">This is Top</h1>
        <p>
          <a href="#top">Back to Top</a>
        </p>
      HTML
      index.update!(html: html1)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout

      Job::Log.destroy_all
    end

    it do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/0 errors/).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
      end

      expect(Cms::CheckLinks::Report.all.count).to eq 1
      Cms::CheckLinks::Report.all.first.tap do |report|
        expect(report.site_id).to eq site.id
        expect(report.name).to include "実行結果"
        expect(report.link_errors.count).to eq 0
        expect(report.pages.count).to eq 0
        expect(report.nodes.count).to eq 0
      end
    end
  end

  context "recursive link" do
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }

    before do
      html1 = <<~HTML
        <a href="#{index.url}">It's me!</a>
      HTML
      index.update!(html: html1)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout

      Job::Log.destroy_all
    end

    it do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/0 errors/).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
      end

      expect(Cms::CheckLinks::Report.all.count).to eq 1
      Cms::CheckLinks::Report.all.first.tap do |report|
        expect(report.site_id).to eq site.id
        expect(report.name).to include "実行結果"
        expect(report.link_errors.count).to eq 0
        expect(report.pages.count).to eq 0
        expect(report.nodes.count).to eq 0
      end
    end
  end

  context "relative scheme" do
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }
    let(:url) { "//#{unique_domain}/#{unique_id}/#{unique_id}" }

    before do
      not_found_return = { body: "", status: 404, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
      stub_request(:get, url).to_return(not_found_return)

      html1 = <<~HTML
        <a href="#{url}">External Page</a>
      HTML
      index.update!(html: html1)

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout

      Job::Log.destroy_all
    end

    it do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/1 errors/).to_stdout

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
      end

      expect(Cms::CheckLinks::Report.all.count).to eq 1
      Cms::CheckLinks::Report.all.first.tap do |report|
        expect(report.site_id).to eq site.id
        expect(report.name).to include "実行結果"
        expect(report.link_errors.count).to eq 1
        expect(report.pages.count).to eq 1
        report.pages.to_a.tap do |page_reports|
          expect(page_reports[0].site_id).to eq site.id
          expect(page_reports[0].report_id).to eq report.id
          expect(page_reports[0].ref).to eq index.url
          expect(page_reports[0].ref_url).to eq index.full_url
          expect(page_reports[0].name).to eq index.name
          expect(page_reports[0].filename).to eq index.filename
          expect(page_reports[0].urls).to have(1).items
          expect(page_reports[0].urls).to include(url)
          expect(page_reports[0].page_id).to eq index.id
        end
        expect(report.nodes.count).to eq 0
      end

      expect(a_request(:get, url)).to have_been_made.times(1)
    end
  end

  context "with complex contents like calendar" do
    let!(:layout) do
      html = <<~HTML
        <html>
          <body>
            <br><br><br>
            <a href="https://www.example.jp/notfound1.html">Not Found1</a>
            <div id="main" class="page">
              {{ yield }}
            </div>
            <a href="https://www.example.jp/notfound2.html">Not Found2</a>
          </body>
        </html>
      HTML
      create :cms_layout, cur_site: site, html: html
    end

    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html", state: "public" }
    let!(:calendar) { create :event_node_page, cur_site: site, layout: layout, state: "public" }
    let!(:event_date) { Time.zone.today }
    let!(:page1) do
      event_recurrences = [ { kind: "date", start_at: event_date, frequency: "daily", until_on: event_date } ]
      create(
        :event_page, cur_site: site, layout: layout, cur_node: calendar, state: "public",
        event_recurrences: event_recurrences, related_url: nil, ical_link: nil)
    end

    before do
      html = <<~HTML
        <a href="#{calendar.url}">#{calendar.name}</a>
      HTML
      index.update!(html: html)

      stub_request(:get, "https://www.example.jp/notfound1.html").to_return(status: 404, body: "", headers: {})
      stub_request(:get, "https://www.example.jp/notfound2.html").to_return(status: 404, body: "", headers: {})

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      Job::Log.destroy_all
    end

    it do
      # expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/784 errors/).to_stdout
      ss_perform_now described_class.bind(site_id: site.id)

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)

        expect(log.logs).to include(include("#{site_url}/"))
      end

      expect(Cms::CheckLinks::Report.all.count).to eq 1
      Cms::CheckLinks::Report.all.first.tap do |report|
        expect(report.site_id).to eq site.id
        expect(report.name).to include "実行結果"
        expect(report.link_errors.count).to eq 784
        expect(report.pages.count).to eq 2
        expect(report.nodes.count).to eq 782
        report.pages.to_a.tap do |page_reports|
          expect(page_reports[0].site_id).to eq site.id
          expect(page_reports[0].report_id).to eq report.id
          expect(page_reports[0].ref).to eq site.url
          expect(page_reports[0].ref_url).to eq site.full_url
          expect(page_reports[0].page_id).to eq index.id
          expect(page_reports[0].name).to eq index.name
          expect(page_reports[0].filename).to eq index.filename
          expect(page_reports[0].urls).to have(2).items
          expect(page_reports[0].urls).to include("https://www.example.jp/notfound1.html")
          expect(page_reports[0].urls).to include("https://www.example.jp/notfound2.html")

          expect(page_reports[1].site_id).to eq site.id
          expect(page_reports[1].report_id).to eq report.id
          expect(page_reports[1].ref).to eq page1.url
          expect(page_reports[1].ref_url).to eq page1.full_url
          expect(page_reports[1].page_id).to eq page1.id
          expect(page_reports[1].name).to eq page1.name
          expect(page_reports[1].filename).to eq page1.filename
          expect(page_reports[1].urls).to have(2).items
          expect(page_reports[1].urls).to include("https://www.example.jp/notfound1.html")
          expect(page_reports[1].urls).to include("https://www.example.jp/notfound2.html")
        end
        report.nodes.to_a.tap do |node_reports|
          expect(node_reports[0].site_id).to eq site.id
          expect(node_reports[0].report_id).to eq report.id
          expect(node_reports[0].ref).to eq calendar.url
          expect(node_reports[0].ref_url).to eq calendar.full_url
          expect(node_reports[0].node_id).to eq calendar.id
          expect(node_reports[0].name).to eq calendar.name
          expect(node_reports[0].filename).to eq calendar.filename
          expect(node_reports[0].urls).to have(2).items
          expect(node_reports[0].urls).to include("https://www.example.jp/notfound1.html")
          expect(node_reports[0].urls).to include("https://www.example.jp/notfound2.html")

          expect(node_reports[5].site_id).to eq site.id
          expect(node_reports[5].report_id).to eq report.id
          expect(node_reports[5].ref).to eq "#{calendar.url}#{event_date.prev_month.strftime("%Y%m")}/list.html"
          expect(node_reports[5].ref_url).to eq "#{calendar.full_url}#{event_date.prev_month.strftime("%Y%m")}/list.html"
          expect(node_reports[5].node_id).to eq calendar.id
          expect(node_reports[5].name).to eq calendar.name
          expect(node_reports[5].filename).to eq calendar.filename
          expect(node_reports[0].urls).to have(2).items
          expect(node_reports[0].urls).to include("https://www.example.jp/notfound1.html")
          expect(node_reports[0].urls).to include("https://www.example.jp/notfound2.html")
        end
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end
end
