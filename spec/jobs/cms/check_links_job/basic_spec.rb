require 'spec_helper'

describe Cms::CheckLinksJob, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:site) { create :cms_site_subdir, parent: site0 }
  let!(:site_url) { "http://#{site.domain}/#{site.subdir}" }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
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
    let!(:layout) do
      html = <<~HTML
        <html>
          <body>
            <br><br><br>
            <h1 id="ss-page-name">\#{page_name}</h1><br>
            <div id="main" class="page">
              {{ yield }}
            </div>
            <a href="https://www.example.jp/not_found_outer_yield.pdf" target="_blank">Not Found</a>
          </body>
        </html>
      HTML
      create :cms_layout, cur_site: site, html: html
    end
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }
    let!(:docs) { create :article_node_page, cur_site: site, layout: layout, filename: "docs" }
    let!(:page1) { create :article_page, cur_site: site, layout: layout, filename: "docs/page1.html" }
    let!(:page2) { create :article_page, cur_site: site, layout: layout, filename: "docs/page2.html" }
    let!(:page3) { create :article_page, cur_site: site, layout: layout, filename: "docs/page3.html" }

    before do
      stub_request(:any, "https://www.example.jp/not_found_outer_yield.pdf")
        .to_return(status: 404, body: "", headers: SS::EMPTY_HASH)

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
        expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/6 errors/).to_stdout

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

          # ログやコンソールには yield 外のリンク切れのみも報告される
          expect(log.logs).to include(include("  - https://www.example.jp/not_found_outer_yield.pdf"))
        end

        expect(Cms::CheckLinks::Report.all.count).to eq 1
        Cms::CheckLinks::Report.all.first.tap do |report|
          expect(report.site_id).to eq site.id
          expect(report.name).to include "実行結果"
          expect(report.link_errors.count).to eq 3
          expect(report.pages.count).to eq 3
          expect(report.nodes.count).to eq 0
          report.pages.to_a.tap do |page_reports|
            expect(page_reports[0].site_id).to eq site.id
            expect(page_reports[0].report_id).to eq report.id
            expect(page_reports[0].ref).to eq site.url
            expect(page_reports[0].ref_url).to eq site.full_url
            expect(page_reports[0].page_id).to eq index.id
            expect(page_reports[0].name).to eq index.name
            expect(page_reports[0].filename).to eq index.filename
            # yield 内のリンク切れのみを記録する
            expect(page_reports[0].urls).to have(1).items
            expect(page_reports[0].urls).to include("#{site.url}notfound1.html")
            expect(page_reports[0].urls).not_to include("https://www.example.jp/not_found_outer_yield.pdf")

            expect(page_reports[1].site_id).to eq site.id
            expect(page_reports[1].report_id).to eq report.id
            expect(page_reports[1].ref).to eq index.url
            expect(page_reports[1].ref_url).to eq index.full_url
            expect(page_reports[1].page_id).to eq index.id
            expect(page_reports[1].name).to eq index.name
            expect(page_reports[1].filename).to eq index.filename
            # yield 内のリンク切れのみを記録する
            expect(page_reports[1].urls).to have(1).items
            expect(page_reports[1].urls).to include("#{site.url}notfound1.html")
            expect(page_reports[1].urls).not_to include("https://www.example.jp/not_found_outer_yield.pdf")

            expect(page_reports[2].site_id).to eq site.id
            expect(page_reports[2].report_id).to eq report.id
            expect(page_reports[2].ref).to eq page1.url
            expect(page_reports[2].ref_url).to eq page1.full_url
            expect(page_reports[2].page_id).to eq page1.id
            expect(page_reports[2].name).to eq page1.name
            expect(page_reports[2].filename).to eq page1.filename
            # yield 内のリンク切れのみを記録する
            expect(page_reports[2].urls).to have(1).items
            expect(page_reports[2].urls).to include("#{site.url}notfound2.html")
            expect(page_reports[2].urls).not_to include("https://www.example.jp/not_found_outer_yield.pdf")
          end
        end

        expect(ActionMailer::Base.deliveries.length).to eq 0

        # 外部サイトURLについては転送量を押さえる目的で HEAD でアクセスする
        expect(a_request(:head, "https://www.example.jp/not_found_outer_yield.pdf")).to have_been_made.times(1)
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
          expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/6 errors/).to_stdout

          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          mail = ActionMailer::Base.deliveries.first
          expect(mail.from.first).to eq site.sender_address
          expect(mail.to.first).to eq email1
          expect(mail_subject(mail)).to eq "[#{site.name}] Link Check: 6 errors"
          expect(mail_body(mail)).to include "[6 errors]"
          expect(mail_body(mail)).to include "#{site_url}/"
          expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
          expect(mail_body(mail)).to include "#{site_url}/index.html"
          expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
          expect(mail_body(mail)).to include "#{site_url}/docs/page1.html"
          expect(mail_body(mail)).to include "  - #{site_url}/notfound2.html"
          # メールには yield 外のリンク切れも記載されている
          expect(mail_body(mail)).to include "  - https://www.example.jp/not_found_outer_yield.pdf"
        end
      end

      context "format csv" do
        let!(:message_format) { "csv" }

        it do
          expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/6 errors/).to_stdout

          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          mail = ActionMailer::Base.deliveries.first
          expect(mail.from.first).to eq site.sender_address
          expect(mail.to.first).to eq email1

          expect(mail_subject(mail)).to eq "[#{site.name}] Link Check: 6 errors"
          expect(mail.multipart?).to be_truthy
          expect(mail.parts[0].body.raw_source).to include "[6 errors]"
          expect(mail.parts[0].body.raw_source).to include "error details are in the attached csv"

          csv = mail.parts[1].body.raw_source
          csv = csv.delete_prefix(SS::Csv::UTF8_BOM)
          csv = CSV.parse(csv)

          expect(csv.length).to eq 10
          expect(csv[0]).to eq %w(reference url)
          expect(csv[1]).to eq %W(#{site.url} #{site.url}notfound1.html)
          expect(csv[2]).to eq %W(#{site.url} https://www.example.jp/not_found_outer_yield.pdf)
          expect(csv[3]).to eq %W(#{site.url}docs/ https://www.example.jp/not_found_outer_yield.pdf)
          expect(csv[4]).to eq %W(#{site.url}docs/page1.html #{site.url}notfound2.html)
          expect(csv[5]).to eq %W(#{site.url}docs/page1.html https://www.example.jp/not_found_outer_yield.pdf)
          expect(csv[6]).to eq %W(#{site.url}docs/page2.html https://www.example.jp/not_found_outer_yield.pdf)
          expect(csv[7]).to eq %W(#{site.url}docs/page3.html https://www.example.jp/not_found_outer_yield.pdf)
          expect(csv[8]).to eq %W(#{site.url}index.html #{site.url}notfound1.html)
          expect(csv[9]).to eq %W(#{site.url}index.html https://www.example.jp/not_found_outer_yield.pdf)
        end
      end

      context "set email in task arguments" do
        let!(:message_format) { "text" }

        it do
          expect { ss_perform_now described_class.bind(site_id: site.id), email: email2 }.to output(/6 errors/).to_stdout

          expect(Job::Log.count).to eq 1
          Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          mail = ActionMailer::Base.deliveries.first
          expect(mail.from.first).to eq site.sender_address
          expect(mail.to.first).to eq email2
          expect(mail_subject(mail)).to eq "[#{site.name}] Link Check: 6 errors"
          expect(mail_body(mail)).to include "[6 errors]"
          expect(mail_body(mail)).to include "#{site_url}/"
          expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
          expect(mail_body(mail)).to include "#{site_url}/index.html"
          expect(mail_body(mail)).to include "  - #{site_url}/notfound1.html"
          expect(mail_body(mail)).to include "#{site_url}/docs/page1.html"
          expect(mail_body(mail)).to include "  - #{site_url}/notfound2.html"
          # メールには yield 外のリンク切れも記載されている
          expect(mail_body(mail)).to include "  - https://www.example.jp/not_found_outer_yield.pdf"
        end
      end
    end
  end

  context "when a node include broken links" do
    let!(:layout) { create_cms_layout cur_site: site }
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
    let!(:layout) { create_cms_layout cur_site: site }
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
    let!(:layout) { create_cms_layout cur_site: site }
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
    let!(:layout) { create_cms_layout cur_site: site }
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
    let!(:layout) { create_cms_layout cur_site: site }
    let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }
    let(:url) { "//#{unique_domain}/#{unique_id}/#{unique_id}" }

    before do
      not_found_return = { body: "", status: 404, headers: { 'Content-Type' => 'text/html; charset=utf-8' } }
      stub_request(:any, url).to_return(not_found_return)

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
          expect(page_reports[0].ref).to eq site.url
          expect(page_reports[0].ref_url).to eq site.full_url
          expect(page_reports[0].page_id).to eq index.id
          expect(page_reports[0].name).to eq index.name
          expect(page_reports[0].filename).to eq index.filename
          expect(page_reports[0].urls).to have(1).items
          expect(page_reports[0].urls).to include(url)
        end
        expect(report.nodes.count).to eq 0
      end

      # 外部サイトURLについては転送量を押さえる目的で HEAD でアクセスする
      expect(a_request(:head, url)).to have_been_made.times(1)
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

      stub_request(:any, "https://www.example.jp/notfound1.html").to_return(status: 404, body: "", headers: {})
      stub_request(:any, "https://www.example.jp/notfound2.html").to_return(status: 404, body: "", headers: {})

      expect { ss_perform_now Cms::Node::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      expect { ss_perform_now Cms::Page::GenerateJob.bind(site_id: site.id) }.to output.to_stdout
      Job::Log.destroy_all
    end

    it do
      expect { ss_perform_now described_class.bind(site_id: site.id) }.to output(/5 errors/).to_stdout

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
        # yield 外のリンク切れからレポートは作成されない
        expect(report.link_errors.count).to eq 0
        expect(report.pages.count).to eq 0
        expect(report.nodes.count).to eq 0
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0

      # 外部サイトURLについては転送量を押さえる目的で HEAD でアクセスする
      expect(a_request(:head, "https://www.example.jp/notfound1.html")).to have_been_made.times(1)
      expect(a_request(:head, "https://www.example.jp/notfound2.html")).to have_been_made.times(1)

      expect(SS::Task.all.count).to eq 3
      Cms::Task.all.where(name: "cms:check_links").first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.node_id).to be_blank
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
        expect(task.closed.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
        expect(task.current_count).to eq 7

        url_log_path = task.log_file_path.sub(".log", "") + "-url-log.json.gz"
        url_logs = Zlib::GzipReader.open(url_log_path) { _1.readlines }.map { JSON.parse(_1.chomp) }
        # puts url_logs.map { _1["full_url"] }.join("\n")
        expect(url_logs.length).to eq 25

        next_month_url = "#{calendar.full_url}#{Time.zone.today.next_month.strftime("%Y%m")}/"
        expect(url_logs.select { _1["full_url"].start_with?(next_month_url) }.map { _1["status"] }.uniq).to eq %w(nofollow)

        prev_month_url = "#{calendar.full_url}#{Time.zone.today.prev_month.strftime("%Y%m")}/"
        expect(url_logs.select { _1["full_url"].start_with?(prev_month_url) }.map { _1["status"] }.uniq).to eq %w(nofollow)

        event_url = "#{calendar.full_url}#{event_date.strftime("%Y%m%d")}/"
        expect(url_logs.select { _1["full_url"] == event_url }.map { _1["status"] }.uniq).to eq %w(success)

        expect(url_logs.select { _1["full_url"] == page1.full_url }.map { _1["status"] }.uniq).to eq %w(success)

        list_url = "#{calendar.full_url}#{Time.zone.today.strftime("%Y%m")}/list.html"
        expect(url_logs.select { _1["full_url"] == list_url }.map { _1["status"] }.uniq).to eq %w(success)

        list_ics_url = "#{calendar.full_url}#{Time.zone.today.strftime("%Y%m")}/list.ics"
        expect(url_logs.select { _1["full_url"] == list_ics_url }.map { _1["status"] }.uniq).to eq %w(nofollow)
      end
    end
  end

  context "with sns share part" do
    context "with 'show'" do
      let!(:part) do
        share_states = Cms::Part::SnsShare::SERVICES.index_with { "show" }
        create :cms_part_sns_share, cur_site: site, sns_share_states: share_states
      end
      let!(:layout) { create_cms_layout part, cur_site: site }
      let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html", state: "public" }

      before do
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
          # yield 外のリンク切れからレポートは作成されない
          expect(report.link_errors.count).to eq 0
          expect(report.pages.count).to eq 0
          expect(report.nodes.count).to eq 0
        end

        expect(ActionMailer::Base.deliveries.length).to eq 0

        expect(SS::Task.all.count).to eq 3
        Cms::Task.all.where(name: "cms:check_links").first.tap do |task|
          expect(task.site_id).to eq site.id
          expect(task.node_id).to be_blank
          expect(task.state).to eq "completed"
          expect(task.started.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
          expect(task.closed.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
          expect(task.current_count).to eq 1

          url_log_path = task.log_file_path.sub(".log", "") + "-url-log.json.gz"
          url_logs = Zlib::GzipReader.open(url_log_path) { _1.readlines }.map { JSON.parse(_1.chomp) }
          # puts url_logs.map { _1["full_url"] }.join("\n")
          expect(url_logs.length).to eq 6

          statuses = url_logs.select { _1["full_url"].start_with?("https://www.facebook.com/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
          statuses = url_logs.select { _1["full_url"].start_with?("https://twitter.com/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
          statuses = url_logs.select { _1["full_url"].start_with?("https://b.hatena.ne.jp/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
        end
      end
    end

    context "with 'link_only'" do
      let!(:part) do
        share_states = Cms::Part::SnsShare::SERVICES.index_with { "link_only" }
        create :cms_part_sns_share, cur_site: site, sns_share_states: share_states
      end
      let!(:layout) { create_cms_layout part, cur_site: site }
      let!(:index) { create :cms_page, cur_site: site, layout: layout, filename: "index.html", state: "public" }

      before do
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
          # yield 外のリンク切れからレポートは作成されない
          expect(report.link_errors.count).to eq 0
          expect(report.pages.count).to eq 0
          expect(report.nodes.count).to eq 0
        end

        expect(ActionMailer::Base.deliveries.length).to eq 0

        expect(SS::Task.all.count).to eq 3
        Cms::Task.all.where(name: "cms:check_links").first.tap do |task|
          expect(task.site_id).to eq site.id
          expect(task.node_id).to be_blank
          expect(task.state).to eq "completed"
          expect(task.started.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
          expect(task.closed.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
          expect(task.current_count).to eq 1

          url_log_path = task.log_file_path.sub(".log", "") + "-url-log.json.gz"
          url_logs = Zlib::GzipReader.open(url_log_path) { _1.readlines }.map { JSON.parse(_1.chomp) }
          # puts url_logs.map { _1["full_url"] }.join("\n")
          expect(url_logs.length).to eq 7

          statuses = url_logs.select { _1["full_url"].start_with?("https://www.facebook.com/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
          statuses = url_logs.select { _1["full_url"].start_with?("https://x.com/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
          statuses = url_logs.select { _1["full_url"].start_with?("https://b.hatena.ne.jp/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
          statuses = url_logs.select { _1["full_url"].start_with?("https://line.me/") }.map { _1["status"] }.uniq
          expect(statuses).to eq %w(nofollow)
        end
      end
    end
  end
end
