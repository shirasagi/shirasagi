require 'spec_helper'

describe "cms_agents_nodes_line_hub", type: :feature, dbscope: :example do
  let!(:site)   { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node)   { create :cms_node_line_hub, layout_id: layout.id, filename: "receiver" }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "no mail handler" do
      let!(:url) { "#{node.url}mail" }

      it "#index" do
        expect { visit url }.to raise_error "404"
      end
    end

    context "exists mail handler" do
      let!(:mail_handler) { create :cms_line_mail_handler }
      let!(:url) { "#{node.url}mail/#{mail_handler.filename}" }

      it "#index" do
        visit url
        expect(status_code).to eq 200
      end
    end
  end
end
