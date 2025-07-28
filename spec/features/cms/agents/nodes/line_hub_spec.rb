require 'spec_helper'

describe "cms_agents_nodes_line_hub", type: :feature, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node)   { create :cms_node_line_hub, layout_id: layout.id, filename: "receiver" }
  let!(:mail_handler1) { create :cms_line_mail_handler, handle_state: "deliver" }
  let!(:mail_handler2) { create :cms_line_mail_handler, handle_state: "disabled" }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
    end

    it "#line" do
      expect { visit "#{node.url}line" }.to raise_error "400"
    end

    it "#mail" do
      visit "#{node.url}mail/#{mail_handler1.filename}"
      expect(status_code).to eq 200

      visit "#{node.url}mail/#{mail_handler2.filename}"
      expect(status_code).to eq 404
    end
  end
end
