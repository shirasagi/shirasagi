require 'spec_helper'

describe "guide_questions", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node)   { create :guide_node_guide, filename: "guide" }
  let(:item) { create(:guide_question, cur_site: site, cur_node: node) }

  let!(:procedure1) do
    create :guide_procedure, cur_site: site, cur_node: node, name: "procedure1", id_name: "0.procedure1", order: 10,
      cond_yes_question_ids: [question1.id],
      cond_yes_edge_values: [{ question_id: question1.id.to_s, edge_value: I18n.t("guide.links.applicable") }]
  end
  let!(:procedure2) do
    create :guide_procedure, cur_site: site, cur_node: node, name: "procedure2", id_name: "1.procedure1", order: 20,
      cond_yes_question_ids: [question2.id],
      cond_yes_edge_values: [{ question_id: question2.id.to_s, edge_value: I18n.t("guide.links.applicable") }]
  end

  let!(:question1) do
    create :guide_question, cur_site: site, cur_node: node, name: "question1", id_name: "0.question1", order: 10,
      in_edges: in_edges
  end
  let!(:question2) do
    create :guide_question, cur_site: site, cur_node: node, name: "question2", id_name: "1.question2", order: 20,
      in_edges: in_edges
  end

  let(:index_path) { guide_questions_path site.id, node }
  let(:new_path) { new_guide_question_path site.id, node }

  def in_edges
    [
      { value: I18n.t("guide.links.applicable"), question_type: "yes_no" },
      { value: I18n.t("guide.links.not_applicable"), question_type: "yes_no" }
    ]
  end

  context "basic crud" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[id_name]", with: "0.sample"
        choose "item_question_type_yes_no"
        wait_for_js_ready
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      item = ::Guide::Question.find_by(id_name: '0.sample')
    end
  end
end
