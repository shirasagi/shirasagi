require 'spec_helper'

describe "cms_generate_nodes", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  before { login_cms_user }

  context "with multiple tasks" do
    let!(:layout) { create_cms_layout }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
    let(:now) { Time.zone.now.change(usec: 0) }

    before do
      Timecop.freeze(now - 5.days) do
        Cms::Task.create!(
          site_id: site.id, node_id: node.id, name: 'cms:generate_nodes', state: 'running', total_count: 300, current_count: 100,
          started: now - 1.hour
        )
      end
      Timecop.freeze(now - 3.days) do
        Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_nodes', state: 'ready')
      end
    end

    it do
      visit cms_generate_nodes_path(site: site.id)
      expect(page).to have_css(".state", text: I18n.t("job.state.ready"))
      expect(page).to have_css(".count", text: "0")
    end
  end
end
