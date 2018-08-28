require 'spec_helper'

describe Event::Ical::ImportJob, dbscope: :example, http_server: true do
  http.default port: 56_273
  http.default doc_root: Rails.root.join("spec", "fixtures", "event", "ical")

  context "when importing ics" do
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    context "with regular shirasagi format" do
      let(:path) { "event-1.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(2)
        expect(Event::Page.site(site).node(node).where(ical_link: 'doc-1')).to be_present
        Event::Page.site(site).node(node).find_by(ical_link: 'doc-1').tap do |doc|
          expect(doc.name).to eq "Python 夏休み集中キャンプ"
          expect(doc.event_name).to eq doc.name
          expect(doc.content).to eq "夏休み最後の週に Python の集中キャンプを実施します。"
          expect(doc.summary_html).to eq doc.content
          expect(doc.venue).to eq "教育会館"
          expect(doc.contact).to eq "Python 普及委員会"
          expect(doc.schedule).to eq "8月27日〜8月31日"
          expect(doc.related_url).to eq "http://www.example.jp/sabd/"
          expect(doc.cost).to eq "2,000円"
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
        end
        expect(Event::Page.site(site).node(node).where(ical_link: 'doc-2')).to be_present
        Event::Page.site(site).node(node).find_by(ical_link: 'doc-2').tap do |doc|
          expect(doc.name).to eq "SUMMARY-○○○○○○○○○○"
          expect(doc.event_name).to eq doc.name
          expect(doc.content).to eq "DESCRIPTION-○○○○○○○○○○"
          expect(doc.summary_html).to eq doc.content
          expect(doc.venue).to eq "LOCATION-○○○○○○○○○○"
          expect(doc.contact).to eq "CONTACT-○○○○○○○○○○"
          expect(doc.schedule).to eq "SCHEDULE-〇〇年○月〇日"
          expect(doc.related_url).to eq "http://organizer.example.jp/x/y/z/"
          expect(doc.cost).to eq "COST-○○○○○○○○○○"
          expect(doc.event_dates).to include("2018/07/30", "2018/07/31", "2018/08/01", "2018/08/02", "2018/08/03")
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
          expect(doc.event_dates).to include("2018/09/24", "2018/09/25", "2018/09/26", "2018/09/27", "2018/09/28")
        end
      end
    end

    context "with rdate as period format 2" do
      let(:path) { "event-2.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(2)
        Event::Page.site(site).node(node).find_by(ical_link: 'doc-2').tap do |doc|
          puts "event_dates=#{doc.event_dates}"
          expect(doc.event_dates).to include("2018/07/30", "2018/07/31", "2018/08/01", "2018/08/02", "2018/08/03")
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
          expect(doc.event_dates).to include("2018/09/24", "2018/09/25", "2018/09/26", "2018/09/27", "2018/09/28")
        end
      end
    end

    context "with rdate as period format 1" do
      let(:path) { "event-2.ics" }

      it do
        expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(2)
        Event::Page.site(site).node(node).find_by(ical_link: 'doc-2').tap do |doc|
          puts "event_dates=#{doc.event_dates}"
          expect(doc.event_dates).to include("2018/07/30", "2018/07/31", "2018/08/01", "2018/08/02", "2018/08/03")
          expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/29", "2018/08/30", "2018/08/31")
          expect(doc.event_dates).to include("2018/09/24", "2018/09/25", "2018/09/26", "2018/09/27", "2018/09/28")
        end
      end
    end
  end

  describe ".import_jobs" do
    context "ical_refresh_method is auto" do
      let(:path) { "event-1.ics" }
      let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
      let(:site) { cms_site }
      let!(:node) { create :event_node_ical, site: site, ical_import_url: url, ical_refresh_method: 'auto' }
      let(:user) { cms_user }

      it do
        described_class.register_jobs(site, user)
        expect { described_class.register_jobs(site, user) }.to change { enqueued_jobs.count }.by(1)
      end
    end

    context "ical_refresh_method is manual" do
      let(:path) { "event-1.ics" }
      let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
      let(:site) { cms_site }
      let!(:node) { create :event_node_ical, site: site, ical_import_url: url, ical_refresh_method: 'manual' }
      let(:user) { cms_user }

      it do
        expect { described_class.register_jobs(site, user) }.to change { enqueued_jobs.count }.by(0)
      end
    end
  end

  context "when ical_max_docs is 1" do
    let(:path) { "event-1.ics" }
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url, ical_max_docs: 1 }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(1)
      expect(Event::Page.site(site).node(node).where(ical_link: 'doc-1')).to be_blank
      expect(Event::Page.site(site).node(node).where(ical_link: 'doc-2')).to be_present
    end
  end

  context "when ical is not changed" do
    let(:path) { "event-1.ics" }
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      described_class.bind(bindings).perform_now
      expect(Event::Page.count).to eq 2

      http.options real_path: "/event-1.ics"

      described_class.bind(bindings).perform_now
      expect(Event::Page.count).to eq 2

      doc1 = Event::Page.site(site).node(node).where(ical_link: 'doc-1').first
      expect(doc1.name).to eq "Python 夏休み集中キャンプ"
      doc2 = Event::Page.site(site).node(node).where(ical_link: 'doc-2').first
      expect(doc2.name).to eq "SUMMARY-○○○○○○○○○○"
    end
  end

  context "when ical is updated" do
    let(:path) { "event-1.ics" }
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    after { travel_back }

    it do
      travel_to('2018-05-01 00:00')
      described_class.bind(bindings).perform_now
      expect(Event::Page.count).to eq 2

      http.options real_path: "/updated_event.ics"

      travel_to('2018-07-01 00:00')
      described_class.bind(bindings).perform_now
      expect(Event::Page.count).to eq 1

      doc1 = Event::Page.site(site).node(node).where(ical_link: 'doc-1').first
      expect(doc1).not_to be_nil
      expect(doc1.name).to eq 'new_doc1'
      expect(Event::Page.where(ical_link: 'doc-2')).to be_blank
    end
  end

  context "when importing ics with exdate" do
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }
    let(:path) { "event-exdate-1.ics" }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(1)
      expect(Event::Page.site(site).node(node).where(ical_link: 'doc-1')).to be_present
      Event::Page.site(site).node(node).find_by(ical_link: 'doc-1').tap do |doc|
        expect(doc.name).to eq "Python 夏休み集中キャンプ"
        expect(doc.event_name).to eq doc.name
        expect(doc.event_dates).to include("2018/08/27", "2018/08/28", "2018/08/30", "2018/08/31")
        expect(doc.event_dates).not_to include("2018/08/29")
      end
    end
  end
end
