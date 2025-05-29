require 'spec_helper'

describe 'article_pages', type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }

  let!(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
  end
  let!(:column2) do
    create(:cms_column_date_field, cur_site: site, cur_form: form, required: "optional", order: 2)
  end
  let!(:column3) do
    create(:cms_column_url_field2, cur_site: site, cur_form: form, required: "optional", order: 3, html_tag: '')
  end
  let!(:column4) do
    create(:cms_column_text_area, cur_site: site, cur_form: form, required: "optional", order: 4)
  end
  let!(:column5) do
    create(:cms_column_select, cur_site: site, cur_form: form, required: "optional", order: 5)
  end
  let!(:column6) do
    create(:cms_column_radio_button, cur_site: site, cur_form: form, required: "optional", order: 6)
  end
  let!(:column7) do
    create(:cms_column_check_box, cur_site: site, cur_form: form, required: "optional", order: 7)
  end
  let!(:column8) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 8, file_type: "image")
  end
  let!(:column9) do
    create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 9)
  end
  let!(:column10) do
    create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional", order: 10)
  end
  let!(:column11) do
    create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 11)
  end
  let!(:column12) do
    create(:cms_column_table, cur_site: site, cur_form: form, required: "optional", order: 12)
  end
  let!(:column13) do
    create(:cms_column_youtube, cur_site: site, cur_form: form, required: "optional", order: 13)
  end

  let(:name) { unique_id }
  let(:column13_1_youtube_id) { "dQw4w9WgXcQ" }
  let(:column13_1_url) { "https://www.youtube.com/watch?v=#{column13_1_youtube_id}" }
  let(:column13_1_title) { "Rick Astley - Never Gonna Give You Up" }
  let(:column13_2_youtube_id) { "9bZkp7q19f0" }
  let(:column13_2_url) { "https://www.youtube.com/watch?v=#{column13_2_youtube_id}" }
  let(:column13_2_title) { "PSY - GANGNAM STYLE" }
  let(:column13_3_youtube_id) { "e-ORhEE9VVg" }
  let(:column13_3_url) { "https://www.youtube.com/watch?v=#{column13_3_youtube_id}" }
  let(:column13_3_title) { "Adele - Hello" }
  let!(:body_layout) { create(:cms_body_layout) }

  def article_pages
    Article::Page.where(filename: /^#{node.filename}\//)
  end

  before do
    cms_role.add_to_set(permissions: %w(read_cms_body_layouts))
    site.set(auto_keywords: 'enabled', auto_description: 'enabled')
    node.st_form_ids = [ form.id ]
    node.save!
  end

  context 'basic crud with form' do
    before { login_cms_user }

    context 'first, create empty pagen and then add columns' do
      it 'fetches title for single column' do
        # 新規ページを作成し、カラムを追加して保存する一連の流れをテスト
        # 1. 空のページを作成
        visit new_article_page_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        expect(page).to have_selector('#item_body_layout_id')

        within 'form#item-form' do
          fill_in 'item[name]', with: name
          # フォーム選択のダイアログを開き、フォームを選択
          wait_for_event_fired("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end

          expect(page).to have_css("#addon-cms-agents-addons-form-page .addon-head", text: form.name)
          expect(page).to have_no_selector('#item_body_layout_id', visible: true)
          # 公開保存
          click_on I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(article_pages.count).to eq 1
        article_pages.first.tap do |item|
          expect(item.name).to eq name
          expect(item.description).to eq form.html
          expect(item.summary).to eq form.html
          expect(item.column_values).to be_blank
          expect(item.backups.count).to eq 1
        end

        # 2. カラム追加画面に遷移し、YouTubeカラムを追加
        visit article_pages_path(site: site, cid: node)
        click_on name
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.links.edit')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within 'form#item-form' do
          # YouTubeカラムを追加
          within ".column-value-palette" do
            wait_for_event_fired("ss:columnAdded") do
              click_on column13.name
            end
          end
          wait_for_all_ckeditors_ready
          wait_for_all_turbo_frames
          within ".column-value-cms-column-youtube" do
            # YouTubeのURLを入力
            fill_in "item[column_values][][in_wrap][url]", with: column13_1_url
            find('.youtube-title-check').click
            expect(page).to have_field('item[column_values][][in_wrap][title]', with: /Rick Astley|Never Gonna Give You Up/i,
wait: 10)
          end
        end
        within 'form#item-form' do
          # JSの完了を待って下書き保存
          wait_for_js_ready
          click_on I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(article_pages.count).to eq 1
        article_pages.first.tap do |item|
          expect(item.name).to eq name
          expect(item.column_values).to have(1).items
          expect(item.column_values.find_by(column_id: column13.id).youtube_id).to eq column13_1_youtube_id
          expect(item.backups.count).to eq 2
        end
        #
        # Update columns
        #
        visit article_pages_path(site: site, cid: node)
        expect(page).to have_no_selector('#item_body_layout_id', visible: true)

        click_on name
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.links.edit')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within 'form#item-form' do
          within ".column-value-cms-column-youtube" do
            fill_in "item[column_values][][in_wrap][url]", with: column13_2_url
            find('.youtube-title-check').click
            expect(page).to have_field('item[column_values][][in_wrap][title]', with: /GANGNAM STYLE|PSY/i, wait: 10)
          end
        end
        within 'form#item-form' do
          wait_for_js_ready
          click_on I18n.t('ss.buttons.publish_save')
        end
        wait_for_notice I18n.t('ss.notice.saved')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(article_pages.count).to eq 1
        article_pages.first.tap do |item|
          expect(item.name).to eq name
          expect(item.column_values).to have(1).items
          expect(item.column_values.find_by(column_id: column13.id).youtube_id).to eq column13_2_youtube_id
          expect(item.column_values.find_by(column_id: column13.id).title).to eq "PSY - GANGNAM STYLE(강남스타일) M/V"
          expect(item.backups.count).to eq 3
        end
      end

      it 'fetches title for each column independently when multiple columns exist' do
        # 複数のYouTube埋め込みカラムを追加し、それぞれのボタンが独立して正しく動作するかをテスト
        visit new_article_page_path(site: site, cid: node)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        # フォーム内の操作
        fill_in 'item[name]', with: name
        # フォーム選択
        wait_for_event_fired("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end
        expect(page).to have_css("#addon-cms-agents-addons-form-page .addon-head", text: form.name)

        # 1つ目のYouTubeカラムを追加
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column13.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        # 2つ目のYouTubeカラムを追加
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column13.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        # 3つ目のYouTubeカラムを追加
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on column13.name
          end
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        # 1つ目のカラムでタイトル取得
        within all('.column-value-cms-column-youtube')[0] do
          fill_in "item[column_values][][in_wrap][url]", with: column13_1_url
          find('.youtube-title-check').click
          expect(page).to have_field('item[column_values][][in_wrap][title]', with: /Rick Astley|Never Gonna Give You Up/i,
wait: 10)
        end

        # 2つ目のカラムでタイトル取得
        within all('.column-value-cms-column-youtube')[1] do
          fill_in "item[column_values][][in_wrap][url]", with: column13_2_url
          find('.youtube-title-check').click
          expect(page).to have_field('item[column_values][][in_wrap][title]', with: /GANGNAM STYLE|PSY/i, wait: 10)
        end

        # 3つ目のカラムでタイトル取得
        within all('.column-value-cms-column-youtube')[2] do
          fill_in "item[column_values][][in_wrap][url]", with: column13_3_url
          find('.youtube-title-check').click
          expect(page).to have_field('item[column_values][][in_wrap][title]', with: /Taylor Swift|Blank Space/i, wait: 10)
        end

        # JSの完了を待って公開保存
        wait_for_js_ready
        click_on I18n.t('ss.buttons.publish_save')
        # 保存完了を待つ
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'), wait: 10)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(article_pages.count).to eq 1
        article_pages.first.tap do |item|
          expect(item.name).to eq name
          expect(item.column_values).to have(3).items
          # 各YouTubeカラムの存在確認
          expect(item.column_values.find_by(column_id: column13.id, youtube_id: column13_1_youtube_id)).to be_present
          expect(item.column_values.find_by(column_id: column13.id, youtube_id: column13_2_youtube_id)).to be_present
          expect(item.column_values.find_by(column_id: column13.id, youtube_id: column13_3_youtube_id)).to be_present
          expect(item.backups.count).to eq 1
        end
      end
    end
  end
end
