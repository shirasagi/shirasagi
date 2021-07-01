require 'spec_helper'

describe "guide_agents_nodes_guide", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :guide_node_guide, layout_id: layout.id, filename: "guide" }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    context "no procedures" do
      it "#index" do
        visit node.url
        within ".guide-node-form" do
          within "footer.send" do
            click_on I18n.t("guide.links.start_guide")
          end

          expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 0))
          click_on I18n.t("guide.links.show_answer")

          expect(page).to have_text(I18n.t("guide.views.your-answers"))
          click_on I18n.t("guide.links.show_result")

          expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 0))
          click_on I18n.t("guide.links.show_procedure")

          expect(page).to have_text(I18n.t("guide.views.all_procedure"))
          click_on I18n.t("guide.links.show_result")

          expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 0))
          click_on I18n.t("guide.links.back_to_first")

          within "footer.send" do
            click_on I18n.t("guide.links.start_guide")
          end
        end
      end
    end

    context "diagram" do
      let!(:procedure1) { create :guide_procedure, cur_site: site, cur_node: node, name: "procedure1", id_name: "0.procedure1", order: 10 }
      let!(:procedure2) { create :guide_procedure, cur_site: site, cur_node: node, name: "procedure2", id_name: "1.procedure2", order: 20 }
      let!(:procedure3) { create :guide_procedure, cur_site: site, cur_node: node, name: "procedure3", id_name: "2.procedure3", order: 30 }
      let!(:procedure4) { create :guide_procedure, cur_site: site, cur_node: node, name: "procedure4", id_name: "3.procedure4", order: 40 }
      let!(:procedure5) { create :guide_procedure, cur_site: site, cur_node: node, name: "procedure5", id_name: "4.procedure5", order: 50 }

      let!(:question1) { create :guide_question, cur_site: site, cur_node: node, name: "question1", id_name: "0.question1", order: 10, in_edges: in_edges(procedure1) }
      let!(:question2) { create :guide_question, cur_site: site, cur_node: node, name: "question2", id_name: "1.question2", order: 20, in_edges: in_edges(procedure2) }
      let!(:question3) { create :guide_question, cur_site: site, cur_node: node, name: "question3", id_name: "2.question3", order: 30, in_edges: in_edges(procedure3) }
      let!(:question4) { create :guide_question, cur_site: site, cur_node: node, name: "question4", id_name: "3.question4", order: 40, in_edges: in_edges(procedure4) }
      let!(:question5) { create :guide_question, cur_site: site, cur_node: node, name: "question5", id_name: "4.question5", order: 50, in_edges: in_edges(procedure5) }

      def in_edges(point)
        [
          { value: I18n.t("guide.links.applicable"), question_type: "yes_no", point_ids: [point.id] },
          { value: I18n.t("guide.links.not_applicable"), question_type: "yes_no", point_ids: [] }
        ]
      end

      it "#index" do
        visit node.url
        within ".guide-node-form" do
          # 5 times yes
          within "footer.send" do
            click_on I18n.t("guide.links.start_guide")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question1.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question2.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question3.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question4.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question5.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 5))
          expect(page).to have_link(procedure1.name)
          expect(page).to have_link(procedure2.name)
          expect(page).to have_link(procedure3.name)
          expect(page).to have_link(procedure4.name)
          expect(page).to have_link(procedure5.name)

          click_on I18n.t("guide.links.back_to_first")

          # 3 times yes, 2 times no
          within "footer.send" do
            click_on I18n.t("guide.links.start_guide")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question1.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question2.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question3.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question4.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question5.name)
          within "footer.send" do
            click_on I18n.t("guide.links.applicable")
          end

          expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 3))
          expect(page).to have_link(procedure1.name)
          expect(page).to have_no_link(procedure2.name)
          expect(page).to have_link(procedure3.name)
          expect(page).to have_no_link(procedure4.name)
          expect(page).to have_link(procedure5.name)

          click_on I18n.t("guide.links.back_to_first")

          # 5 times no
          within "footer.send" do
            click_on I18n.t("guide.links.start_guide")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question1.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question2.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question3.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question4.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".question-nav", text: I18n.t("guide.views.choose_yes_no"))
          expect(page).to have_css(".question", text: question5.name)
          within "footer.send" do
            click_on I18n.t("guide.links.not_applicable")
          end

          expect(page).to have_css(".procedure-count", text: I18n.t("guide.views.procedures_needed", count: 0))
          expect(page).to have_no_link(procedure1.name)
          expect(page).to have_no_link(procedure2.name)
          expect(page).to have_no_link(procedure3.name)
          expect(page).to have_no_link(procedure4.name)
          expect(page).to have_no_link(procedure5.name)
        end
      end
    end
  end
end
