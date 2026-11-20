require 'spec_helper'

describe Cms::Form::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:form) { create(:cms_form, cur_site: site, sub_type: 'static') }
  let(:name) { unique_id }
  let(:name2) { unique_id }
  let(:name3) { unique_id }
  let(:place_holder) { unique_id }

  before { login_cms_user }

  context 'with text' do
    it do
      visit cms_form_path(site, form)
      click_on I18n.t('cms.buttons.manage_columns')

      within '.gws-column-list-toolbar[data-placement="top"]' do
        wait_for_event_fired("gws:column:added") { click_on I18n.t('cms.columns.cms/text_field') }
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.gws-column-form' do
        fill_in 'item[name]', with: name
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name
        expect(item.required).to eq 'required'
      end

      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }
      within_dialog do
        fill_in 'item[name]', with: name2
        fill_in 'item[place_holder]', with: place_holder
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      Cms::Column::Base.site(site).where(form_id: form.id).first.tap do |item|
        expect(item.name).to eq name2
        expect(item.place_holder).to eq place_holder
      end
      # ダイアログ内での編集結果が一覧に反映されている
      expect(page).to have_css(".column-value-header", text: name2)

      # 「キャンセル」が動作するかチェック
      # text input のときだけ特別なチェック
      # 入力に変更があると、閉じる際に確認ダイアログが表示されるが、その確認ダイアログをキャンセル => OK してみる
      wait_for_cbox_opened { find('.btn-gws-column-item-detail').click }
      within_dialog do
        fill_in 'item[name]', with: name3

        page.dismiss_confirm(I18n.t("ss.confirm.unload")) do
          click_on I18n.t("ss.buttons.cancel")
        end

        wait_for_cbox_closed do
          page.accept_confirm(I18n.t("ss.confirm.unload")) do
            click_on I18n.t("ss.buttons.cancel")
          end
        end
      end

      page.accept_confirm do
        find('.btn-gws-column-item-delete').click
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(Cms::Column::Base.site(site).where(form_id: form.id).count).to eq 0
    end
  end
end
