require 'spec_helper'

describe Event::Ical::ImportJob, dbscope: :example, http_server: true do
  http.default port: 56_273
  http.default doc_root: Rails.root.join("spec", "fixtures", "event", "ical")

  context "when importing ics" do
    let(:path) { "event.ics" }
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(2)
      expect(Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/1.html').first).not_to be_nil
      expect(Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/2.html').first).not_to be_nil
    end
  end

  describe ".import_jobs" do
    context "ical_refresh_method is auto" do
      let(:path) { "event.ics" }
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
      let(:path) { "event.ics" }
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
    let(:path) { "event.ics" }
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url, ical_max_docs: 1 }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(1)
      expect(Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/1.html').first).to be_nil
      expect(Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/2.html').first).not_to be_nil
    end
  end

  context "when ical is not changed" do
    let(:path) { "event.ics" }
    let(:url) { "http://127.0.0.1:#{http.port}/#{path}" }
    let(:site) { cms_site }
    let(:node) { create :event_node_ical, site: site, ical_import_url: url }
    let(:user) { cms_user }
    let(:bindings) { { site_id: site.id, node_id: node.id, user_id: user.id } }

    it do
      described_class.bind(bindings).perform_now
      expect(Event::Page.count).to eq 2

      http.options real_path: "/event.ics"

      described_class.bind(bindings).perform_now
      expect(Event::Page.count).to eq 2

      doc1 = Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/1.html').first
      expect(doc1).not_to be_nil
      expect(doc1.name).to eq 'doc1'
      doc2 = Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/2.html').first
      expect(doc2).not_to be_nil
      expect(doc2.name).to eq 'doc2'
    end
  end

  context "when ical is updated" do
    let(:path) { "event.ics" }
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

      doc1 = Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/1.html').first
      expect(doc1).not_to be_nil
      expect(doc1.name).to eq 'new_doc1'
      doc2 = Event::Page.where(ical_link: 'http://127.0.0.1:56273/docs/2.html').first
      expect(doc2).to be_nil
    end
  end
end
