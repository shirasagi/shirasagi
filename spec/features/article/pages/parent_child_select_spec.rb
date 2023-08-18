require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: sub_type) }
  let(:parent_options) do
    Array.new(rand(2..3)) { "parent-#{unique_id}" }
  end
  let(:child_options) do
    parent_options.map do |parent_option|
      Array.new(rand(2..3)) { "#{parent_option}/child-#{unique_id}" }
    end.flatten
  end
  let!(:column1) do
    create(
      :cms_column_select, cur_site: site, cur_form: form, name: "parent-#{unique_id}", order: 10,
      place_holder: "parent-placeholder", select_options: parent_options
    )
  end
  let!(:column2) do
    create(
      :cms_column_select, cur_site: site, cur_form: form, name: "child-#{unique_id}", order: 20,
      place_holder: "child-placeholder", parent_column_name: column1.name, select_options: child_options
    )
  end

  before do
    node.st_form_ids = [ form.id ]
    node.save!

    login_cms_user
  end

  describe "parent-child select" do
    let(:name) { unique_id }
    let(:column1_value) { parent_options.sample }
    let(:column2_value) { child_options.select { |option| option.start_with?("#{column1_value}/") }.sample }

    context 'with static form' do
      let(:sub_type) { 'static' }

      it do
        visit new_article_page_path(site: site, cid: node, form_id: form.id)

        within 'form#item-form' do
          fill_in 'item[name]', with: name

          selects = all(".column-value-cms-column-select")
          expect(selects.length).to eq 2

          within selects[0] do
            select column1_value, from: "item[column_values][][in_wrap][value]"
          end
          within selects[1] do
            select column2_value.split("/").last, from: "item[column_values][][in_wrap][value]"
          end

          click_on I18n.t('ss.buttons.publish_save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Article::Page.all.count).to eq 1

        Article::Page.all.site(site).node(node).first.tap do |item|
          expect(item.name).to eq name
          expect(item.form_id).to eq form.id
          expect(item.column_values).to have(2).items
          item.column_values[0].tap do |column_value|
            expect(column_value.column_id).to eq column1.id
            expect(column_value.value).to eq column1_value
          end
          item.column_values[1].tap do |column_value|
            expect(column_value.column_id).to eq column2.id
            expect(column_value.value).to eq column2_value
          end
        end
      end
    end

    context 'with entry form' do
      let(:sub_type) { 'entry' }
      let(:fetch_options_script) do
        <<~SCRIPT.freeze
          Array.from(
            arguments[0].querySelectorAll('option'),
            node => node.textContent.trim())
        SCRIPT
      end

      it do
        visit new_article_page_path(site: site, cid: node, form_id: form.id)

        within 'form#item-form' do
          fill_in 'item[name]', with: name

          # 最初に子を追加してみる
          within ".column-value-palette" do
            wait_event_to_fire("ss:columnAdded") do
              click_on column2.name
            end
          end
          expect(all(".column-value-cms-column-select").count).to eq 1

          # （親が存在しないので）全ての選択肢が表示されている
          within all(".column-value-cms-column-select")[0] do
            options = page.evaluate_script(fetch_options_script, first('[name="item[column_values][][in_wrap][value]"]'))
            expect(options.length).to eq child_options.length + 1
            expect(options).to include(column2.place_holder, *child_options)
          end

          # 次に親を追加してみる
          within ".column-value-palette" do
            wait_event_to_fire("ss:columnAdded") do
              click_on column1.name
            end
          end
          expect(all(".column-value-cms-column-select").count).to eq 2

          # （親が存在し、未選択なので）子の選択肢は一つも表示されていない
          within all(".column-value-cms-column-select")[0] do
            options = page.evaluate_script(fetch_options_script, first('[name="item[column_values][][in_wrap][value]"]'))
            expect(options.length).to eq 1
            expect(options).to include(column2.place_holder)
          end
          # 親の選択肢は全て表示されている
          within all(".column-value-cms-column-select")[1] do
            options = page.evaluate_script(fetch_options_script, first('[name="item[column_values][][in_wrap][value]"]'))
            expect(options.length).to eq 1 + parent_options.length
            expect(options).to include(column1.place_holder, *parent_options)
          end

          # 親を選択すると、子の選択肢が変化する点も確認する
          within all(".column-value-cms-column-select")[1] do
            select column1_value, from: "item[column_values][][in_wrap][value]"
          end
          within all(".column-value-cms-column-select")[0] do
            options = page.evaluate_script(fetch_options_script, first('[name="item[column_values][][in_wrap][value]"]'))
            expected_options = child_options.
              select { |option| option.start_with?("#{column1_value}/") }.
              map { |option| option.split("/").last }
            expect(options.length).to eq 1 + expected_options.length
            expect(options).to include(column2.place_holder, *expected_options)
            expect(options).to include(column2_value.split("/").last)

            select column2_value.split("/").last, from: "item[column_values][][in_wrap][value]"
          end

          click_on I18n.t('ss.buttons.publish_save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(Article::Page.all.count).to eq 1

        Article::Page.all.site(site).node(node).first.tap do |item|
          expect(item.name).to eq name
          expect(item.form_id).to eq form.id
          expect(item.column_values).to have(2).items
          item.column_values[0].tap do |column_value|
            expect(column_value.column_id).to eq column2.id
            expect(column_value.value).to eq column2_value
          end
          item.column_values[1].tap do |column_value|
            expect(column_value.column_id).to eq column1.id
            expect(column_value.value).to eq column1_value
          end
        end
      end
    end
  end
end
