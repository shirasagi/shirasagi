require 'spec_helper'

describe "cms_agents_nodes_node", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "parent node" do
      let!(:node) do
        create(:cms_node_node, filename: "node", loop_format: loop_format,
          loop_html: loop_html, upper_html: upper_html, lower_html: lower_html,
          child_limit: child_limit, child_loop_html: child_loop_html,
          child_upper_html: child_upper_html, child_lower_html: child_lower_html
        )
      end
      let!(:child_node1) { create :cms_node_page, filename: "node/child1", sort: "order" }
      let!(:child_node2) { create :cms_node_page, filename: "node/child2", sort: "order" }

      let!(:child_node1_page1) { create :cms_page, cur_node: child_node1, order: 1 }
      let!(:child_node1_page2) { create :cms_page, cur_node: child_node1, order: 2 }
      let!(:child_node2_page1) { create :cms_page, cur_node: child_node2, order: 1 }
      let!(:child_node2_page2) { create :cms_page, cur_node: child_node2, order: 2 }

      let(:loop_format) { 'shirasagi' }
      let(:loop_html) { '#{child_items}' }
      let(:upper_html) { '<div class="parent">' }
      let(:lower_html) { '</div>' }

      context "limit 1" do
        let(:child_limit) { 1 }
        let(:child_loop_html) { '<li>#{name}</li>' }
        let(:child_upper_html) { '<ul>' }
        let(:child_lower_html) { '</ul>' }

        it "#index" do
          visit node.url
          within ".parent" do
            expect(page).to have_css("ul li", text: child_node1_page1.name)
            expect(page).to have_no_css("ul li", text: child_node1_page2.name)
            expect(page).to have_css("ul li", text: child_node2_page1.name)
            expect(page).to have_no_css("ul li", text: child_node2_page2.name)
          end
        end
      end

      context "limit 5" do
        let(:child_limit) { 5 }
        let(:child_loop_html) { '<li>#{name}</li>' }
        let(:child_upper_html) { '<ul>' }
        let(:child_lower_html) { '</ul>' }

        it "#index" do
          visit node.url
          within ".parent" do
            expect(page).to have_css("ul li", text: child_node1_page1.name)
            expect(page).to have_css("ul li", text: child_node1_page2.name)
            expect(page).to have_css("ul li", text: child_node1_page1.name)
            expect(page).to have_css("ul li", text: child_node1_page2.name)
          end
        end
      end
    end

    context "other issuer" do
      let!(:issuer_node) do
        create(:cms_node_node, filename: "issuer-node", loop_format: loop_format,
          loop_html: loop_html, upper_html: upper_html, lower_html: lower_html,
          child_limit: child_limit, child_loop_html: child_loop_html,
          child_upper_html: child_upper_html, child_lower_html: child_lower_html,
          conditions: [ node.filename ]
        )
      end
      let!(:node) do
        create(:cms_node_node, filename: "node")
      end
      let!(:child_node1) { create :cms_node_page, filename: "node/child1", sort: "order" }
      let!(:child_node2) { create :cms_node_page, filename: "node/child2", sort: "order" }

      let!(:child_node1_page1) { create :cms_page, cur_node: child_node1, order: 1 }
      let!(:child_node1_page2) { create :cms_page, cur_node: child_node1, order: 2 }
      let!(:child_node2_page1) { create :cms_page, cur_node: child_node2, order: 1 }
      let!(:child_node2_page2) { create :cms_page, cur_node: child_node2, order: 2 }

      let(:loop_format) { 'shirasagi' }
      let(:loop_html) { '#{child_items}' }
      let(:upper_html) { '<div class="parent">' }
      let(:lower_html) { '</div>' }

      context "limit 1" do
        let(:child_limit) { 1 }
        let(:child_loop_html) { '<li>#{name}</li>' }
        let(:child_upper_html) { '<ul>' }
        let(:child_lower_html) { '</ul>' }

        it "#index" do
          visit issuer_node.url
          within ".parent" do
            expect(page).to have_css("ul li", text: child_node1_page1.name)
            expect(page).to have_no_css("ul li", text: child_node1_page2.name)
            expect(page).to have_css("ul li", text: child_node2_page1.name)
            expect(page).to have_no_css("ul li", text: child_node2_page2.name)
          end
        end
      end

      context "limit 5" do
        let(:child_limit) { 5 }
        let(:child_loop_html) { '<li>#{name}</li>' }
        let(:child_upper_html) { '<ul>' }
        let(:child_lower_html) { '</ul>' }

        it "#index" do
          visit issuer_node.url
          within ".parent" do
            expect(page).to have_css("ul li", text: child_node1_page1.name)
            expect(page).to have_css("ul li", text: child_node1_page2.name)
            expect(page).to have_css("ul li", text: child_node1_page1.name)
            expect(page).to have_css("ul li", text: child_node1_page2.name)
          end
        end
      end
    end
  end
end
