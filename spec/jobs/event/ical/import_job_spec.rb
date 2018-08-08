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
      expect { described_class.bind(bindings).perform_now }.to change { Event::Page.count }.from(0).to(1)
      expect(Event::Page.where(ical_link: 'http://127.0.0.1:3000/calendar/page28.html').first).not_to be_nil
    end
  end
end
