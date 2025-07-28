require 'spec_helper'

describe "gws_faq_topics", type: :feature, dbscope: :example do
  context "comments" do
    let(:site) { gws_site }
    let(:show_path) { gws_faq_topic_path site, '-', '-', topic }
    let(:name) { unique_id }
    let(:text) { unique_id }

    before { login_gws_user }

    context "with thread topic" do
      let(:topic) { create :gws_faq_topic, mode: 'thread' }

      it "#show" do
        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on I18n.t("gws/faq.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Faq::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Faq::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text
      end
    end

    context "with tree topic" do
      let(:topic) { create :gws_faq_topic, mode: 'tree' }
      let(:name2) { unique_id }
      let(:text2) { unique_id }

      it "#show" do
        visit show_path
        expect(page).to have_css("article.topic .name", text: topic.name)
        expect(page).to have_css("article.topic .body", text: topic.text)

        within "article.topic div.menu" do
          click_on I18n.t("gws/faq.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)

        expect(Gws::Faq::Post.where(topic_id: topic.id).count).to eq 1
        comment = Gws::Faq::Post.where(topic_id: topic.id).first
        expect(comment.name).to eq name
        expect(comment.text).to eq text

        within "aside.comment div.menu" do
          click_on I18n.t("gws/faq.links.comment")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name2
          fill_in "item[text]", with: text2
          click_button I18n.t('ss.buttons.save')
        end

        expect(page).to have_css("aside.comment h2", text: name)
        expect(page).to have_css("aside.comment .body", text: text)
        expect(page).to have_css("aside.comment h2", text: name2)
        expect(page).to have_css("aside.comment .body", text: text2)

        expect(Gws::Faq::Post.where(topic_id: topic.id).count).to eq 2
        comment = Gws::Faq::Post.where(topic_id: topic.id).order_by(created: -1).first
        expect(comment.name).to eq name2
        expect(comment.text).to eq text2
      end
    end
  end
end
