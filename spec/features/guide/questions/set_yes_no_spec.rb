require 'spec_helper'

describe "guide_questions", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node)   { create :guide_node_guide, filename: "guide" }
  let(:item) { create(:guide_question, cur_site: site, cur_node: node) }

  let!(:procedure1) do
    create :guide_procedure, cur_site: site, cur_node: node, name: "procedure1", id_name: "0.procedure1", order: 10
  end
  let!(:procedure2) do
    create :guide_procedure, cur_site: site, cur_node: node, name: "procedure2", id_name: "1.procedure1", order: 20
  end

  let!(:question1) do
    create :guide_question, cur_site: site, cur_node: node, name: "question1", id_name: "0.question1", order: 10, in_edges: []
  end
  let!(:question2) do
    create :guide_question, cur_site: site, cur_node: node, name: "question2", id_name: "1.question2", order: 20, in_edges: []
  end

  let(:index_path) { guide_questions_path site.id, node }
  let(:new_path) { new_guide_question_path site.id, node }

  context "basic crud" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[id_name]", with: "0.sample"
        choose "item_question_type_yes_no"
        wait_cbox_open { all(".question-edges .edge a", text: I18n.t("ss.links.select"))[0].click }
      end
      wait_for_cbox do
        within ".cms-modal-tabs" do
          expect(page).to have_css("a.current .tab-name", text: I18n.t("guide.procedure"))
        end
        expect(page).to have_link procedure1.id_name
        expect(page).to have_link procedure2.id_name
        wait_cbox_close { click_on procedure1.id_name }
      end

      within "form#item-form" do
        expect(page).to have_css("#addon-guide-agents-addons-question [data-id='#{procedure1.id}']", text: procedure1.id_name)
        wait_cbox_open { all(".question-edges .edge a", text: I18n.t("ss.links.select"))[0].click }
      end
      wait_for_cbox do
        within ".cms-modal-tabs" do
          click_on I18n.t("guide.question")
        end
        expect(page).to have_css("a.current .tab-name", text: I18n.t("guide.procedure"))
        expect(page).to have_link question1.id_name
        expect(page).to have_link question2.id_name
        wait_cbox_close { click_on question1.id_name }
      end

      within "form#item-form" do
        expect(page).to have_css("#addon-guide-agents-addons-question [data-id='#{question1.id}']", text: question1.id_name)
        wait_cbox_open { all(".question-edges .edge a", text: I18n.t("ss.links.select"))[1].click }
      end
      wait_for_cbox do
        within ".cms-modal-tabs" do
          expect(page).to have_css("a.current .tab-name", text: I18n.t("guide.procedure"))
        end

        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head .checkbox input').set(true) }
        within ".search-ui-select" do
          wait_cbox_close { click_on I18n.t("ss.links.select") }
        end
      end

      within "form#item-form" do
        expect(page).to have_css("#addon-guide-agents-addons-question [data-id='#{procedure2.id}']", text: procedure2.id_name)
        wait_cbox_open { all(".question-edges .edge a", text: I18n.t("ss.links.select"))[1].click }
      end
      wait_for_cbox do
        within ".cms-modal-tabs" do
          click_on I18n.t("guide.question")
        end
        wait_for_js_ready
        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head .checkbox input').set(true) }
        within ".search-ui-select" do
          wait_cbox_close { click_on I18n.t("ss.links.select") }
        end
      end

      within "form#item-form" do
        expect(page).to have_css("#addon-guide-agents-addons-question [data-id='#{question2.id}']", text: question2.id_name)
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      item = ::Guide::Question.first
      expect(item.edges.size).to eq 2
      expect(item.edges[0].value).to eq I18n.t("guide.links.applicable")
      expect(item.edges[0].question_type).to eq "yes_no"
      expect(item.edges[0].point_ids).to match_array [procedure1.id, question1.id]
      expect(item.edges[1].value).to eq I18n.t("guide.links.not_applicable")
      expect(item.edges[1].question_type).to eq "yes_no"
      expect(item.edges[1].point_ids).to match_array [procedure1.id, procedure2.id, question1.id, question2.id]
    end
  end
end
