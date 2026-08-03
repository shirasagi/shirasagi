require 'spec_helper'

describe "guide_agents_nodes_guide", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) do
    loop_liquid = <<~HTML
      <div data-type="liquid">
        {% for item in procedures %}
          <div class="guide__lists">
            <h2>{{item.name}}</h2>
            <div class="procedure__wrap">
              <dl class="procedure item-{{item.id}}">
                <dt>リンク URL</dt>
                <dd><a href="{{item.link_url}}">{{item.link_url}}</a></dd>
                <dt>実施場所</dt>
                <dd>{{item.procedure_location}}</dd>
                <dt>必要なもの</dt>
                <dd>{{item.belongings}}</dd>
                <dt>対象者</dt>
                <dd>{{item.procedure_applicant}}</dd>
                <dt>備考</dt>
                <dd>{{item.remarks}}</dd>
              </dl>
              <div class="close-btn"><span>×</span>閉じる</div>
            </div>
          </div>
        {% endfor %}
        <a class="print-btn" href="javascript:void(0)" onclick="window.print();return false;">結果ページを印刷</a>
      </div>
    HTML
    create :guide_node_guide, cur_site: site, layout: layout, loop_format: "liquid", loop_liquid: loop_liquid
  end

  let(:xss_text) { "xss-#{unique_id}" }
  let!(:procedure1) do
    xss_link = %Q(#" onclick="console.log('#{xss_text}')" data-dummy=")
    create(
      :guide_procedure, cur_site: site, cur_node: node, name: "procedure1", id_name: "0.procedure1", order: 10,
      link_url: xss_link
    )
  end
  let!(:question1) do
    edges = [
      { value: I18n.t("guide.links.applicable"), question_type: "yes_no", point_ids: [procedure1.id] },
      { value: I18n.t("guide.links.not_applicable"), question_type: "yes_no", point_ids: [] }
    ]

    create :guide_question, cur_site: site, cur_node: node, name: "question1", id_name: "0.question1", order: 10,
           in_edges: edges
  end

  context "JVN#37476837" do
    it do
      visit node.full_url
      within ".guide-node-form" do
        within "footer.send" do
          click_on I18n.t("guide.links.start_guide")
        end
      end

      expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
      expect(page).to have_css(".question", text: question1.name)
      within "footer.send" do
        click_on I18n.t("guide.links.applicable")
      end

      expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 1))
      expect(page).to have_css("[data-type='liquid'] .guide__lists", count: 1)
      within "[data-type='liquid'] .guide__lists" do
        expect(page).to have_css("h2", text: procedure1.name)
        first("a").click
      end
      capture_console_logs.tap do |logs|
        expect(logs.any? { _1.include?(xss_text) }).to be_falsey
      end
    end
  end
end
