require 'spec_helper'

describe "link_checker", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create_once :article_node_page, filename: unique_id, name: "article" }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
  let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }

  let!(:item1) { create :article_page, cur_node: node }
  let!(:item2) { create :article_page, cur_node: node, form_id: form.id }

  let(:new_path) { new_article_page_path site.id, node }
  let(:edit_path1) { edit_article_page_path site.id, node, item1 }
  let(:edit_path2) { edit_article_page_path site.id, node, item2 }

  before do
    @save_config = SS.config.lgwan.mode
  end

  after do
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def with_lgwan_cms
    SS.config.replace_value_at(:lgwan, :mode, "cms")
    yield
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  def with_lgwan_web
    SS.config.replace_value_at(:lgwan, :mode, "web")
    yield
    SS.config.replace_value_at(:lgwan, :mode, @save_config)
  end

  describe "basic crud" do
    before { login_cms_user }

    context "usual case" do
      it do
        visit new_path
        within "#addon-cms-agents-addons-body" do
          expect(page).to have_button I18n.t("cms.link_check")
        end
      end

      it do
        visit edit_path1
        within "#addon-cms-agents-addons-body" do
          expect(page).to have_button I18n.t("cms.link_check")
        end
      end

      it do
        visit edit_path2
        within ".column-value-palette" do
          wait_event_to_fire("ss:columnAdded") do
            click_on column.name
          end
        end
        within "#addon-cms-agents-addons-body" do
          expect(page).to have_button I18n.t("cms.link_check")
        end
      end
    end

    context "lgwan web" do
      it do
        with_lgwan_web do
          visit new_path
          within "#addon-cms-agents-addons-body" do
            expect(page).to have_button I18n.t("cms.link_check")
          end
        end
      end

      it do
        with_lgwan_web do
          visit edit_path1
          within "#addon-cms-agents-addons-body" do
            expect(page).to have_button I18n.t("cms.link_check")
          end
        end
      end

      it do
        with_lgwan_web do
          visit edit_path2
          within ".column-value-palette" do
            wait_event_to_fire("ss:columnAdded") do
              click_on column.name
            end
          end
          within "#addon-cms-agents-addons-body" do
            expect(page).to have_button I18n.t("cms.link_check")
          end
        end
      end
    end

    context "lgwan cms" do
      it do
        with_lgwan_cms do
          visit new_path
          within "#addon-cms-agents-addons-body" do
            expect(page).to have_no_button I18n.t("cms.link_check")
          end
        end
      end

      it do
        with_lgwan_cms do
          visit edit_path1
          within "#addon-cms-agents-addons-body" do
            expect(page).to have_no_button I18n.t("cms.link_check")
          end
        end
      end

      it do
        with_lgwan_cms do
          visit edit_path2
          within ".column-value-palette" do
            wait_event_to_fire("ss:columnAdded") do
              click_on column.name
            end
          end
          within "#addon-cms-agents-addons-body" do
            expect(page).to have_no_button I18n.t("cms.link_check")
          end
        end
      end
    end
  end
end
