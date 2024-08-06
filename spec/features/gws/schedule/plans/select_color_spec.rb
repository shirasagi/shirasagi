require 'spec_helper'

describe 'gws_schedule_plans_form', type: :feature, dbscope: :example do
  let(:site) { gws_site }

  before { login_gws_user }

  describe 'select color', js: true do
    context 'new' do
      let(:new_path) { new_gws_schedule_plan_path site }

      before do
        visit new_path
      end

      it do
        find('input[name="item[color]"]').click
        first('ul.minicolors-swatches li.minicolors-swatch').click
        expect(find('input[name="item[color]"]').value).to eq '#dc143c'

        within 'form#item-form' do
          fill_in 'item[name]', with: 'name'
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_js_ready
        expect(Gws::Schedule::Plan.count).to eq 1
        expect(Gws::Schedule::Plan.first.color).to eq '#dc143c'
      end
    end

    context 'edit' do
      let(:item) { create(:gws_schedule_plan, color: '#dc143c') }
      let(:edit_path) { edit_gws_schedule_plan_path site, item }

      before do
        visit edit_path
      end

      it do
        find('input[name="item[color]"]').click
        find('ul.minicolors-swatches li.minicolors-swatch:nth-child(2)').click
        expect(find('input[name="item[color]"]').value).to eq '#ff0000'

        within 'form#item-form' do
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_js_ready
        item.reload
        expect(item.color).to eq '#ff0000'
      end
    end

    context 'copy' do
      let(:item) { create(:gws_schedule_plan, color: '#dc143c') }
      let(:copy_path) { copy_gws_schedule_plan_path site, item }

      before do
        visit copy_path
      end

      it do
        find('input[name="item[color]"]').click
        find('ul.minicolors-swatches li.minicolors-swatch:nth-child(2)').click
        expect(find('input[name="item[color]"]').value).to eq '#ff0000'

        within 'form#item-form' do
          fill_in 'item[name]', with: 'copied'
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_js_ready
        expect(Gws::Schedule::Plan.find_by(name: 'copied').color).to eq '#ff0000'
      end
    end
  end
end
