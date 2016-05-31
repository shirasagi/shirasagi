require 'spec_helper'

describe "inquiry_agents_parts_feedback", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form, cur_site: site }
  let(:part) { create :inquiry_part_feedback, cur_site: site, cur_node: node }
  let(:layout) { create_cms_layout [part] }
  let(:page1) { create :cms_page, cur_site: site, layout_id: layout.id }

  let(:contents_column) { node.columns[0] }
  let(:findable_column) { node.columns[1] }
  let(:comment_column) { node.columns[2] }
  let(:contents_index) { rand(contents_column.select_options.count) }
  let(:findable_index) { rand(findable_column.select_options.count) }
  let(:contents_value) { contents_column.select_options[contents_index] }
  let(:findable_value) { findable_column.select_options[findable_index] }
  let(:comment_value) { "#{unique_id}\n#{unique_id}" }

  before do
    node.columns.create! attributes_for(:inquiry_column_radio_contents).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_radio_findable).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_text_comment).reverse_merge({cur_site: site})
    node.reload
  end

  context "with enable captcha and enable confirmation" do
    before do
      node.inquiry_captcha = "enabled"
      node.save!
      part.feedback_confirmation = "enabled"
      part.save!
    end

    it do
      visit page1.full_url

      within ".inquiry-form" do
        choose "item_#{contents_column.id}_#{contents_index}"
        choose "item_#{findable_column.id}_#{findable_index}"
        fill_in "item[#{comment_column.id}]", with: comment_value
      end

      click_on "確認画面へ"

      expect(page).to have_css("dd", text: page1.name)
      expect(page).to have_css("label", text: contents_column.name)
      expect(page).to have_css("label", text: findable_column.name)
      expect(page).to have_css("label", text: comment_column.name)
      expect(page).to have_css("dd", text: contents_value)
      expect(page).to have_css("dd", text: findable_value)
      expect(page).to have_css("dd", text: comment_value.split("\n")[0])
      expect(page).to have_css("dd", text: comment_value.split("\n")[1])
      expect(page).to have_css(".captcha-label", text: "画像の数字を入力してください")

      # unable to proceed ahead, because there is captcha
    end
  end

  context "with enable captcha and disable confirmation" do
    before do
      node.inquiry_captcha = "enabled"
      node.save!
      part.feedback_confirmation = "disabled"
      part.save!
    end

    it do
      visit page1.full_url

      within ".inquiry-form" do
        choose "item_#{contents_column.id}_#{contents_index}"
        choose "item_#{findable_column.id}_#{findable_index}"
        fill_in "item[#{comment_column.id}]", with: comment_value
      end

      click_on "確認画面へ"

      expect(page).to have_css("dd", text: page1.name)
      expect(page).to have_css("label", text: contents_column.name)
      expect(page).to have_css("label", text: findable_column.name)
      expect(page).to have_css("label", text: comment_column.name)
      expect(page).to have_css("dd", text: contents_value)
      expect(page).to have_css("dd", text: findable_value)
      expect(page).to have_css("dd", text: comment_value.split("\n")[0])
      expect(page).to have_css("dd", text: comment_value.split("\n")[1])
      expect(page).to have_css(".captcha-label", text: "画像の数字を入力してください")

      # unable to proceed ahead, because there is captcha
    end
  end

  context "with disable captcha and enable confirmation" do
    before do
      node.inquiry_captcha = "disabled"
      node.save!
      part.feedback_confirmation = "enabled"
      part.save!
    end

    it do
      visit page1.full_url

      within ".inquiry-form" do
        choose "item_#{contents_column.id}_#{contents_index}"
        choose "item_#{findable_column.id}_#{findable_index}"
        fill_in "item[#{comment_column.id}]", with: comment_value
      end

      click_on "確認画面へ"

      expect(page).to have_css("dd", text: page1.name)
      expect(page).to have_css("label", text: contents_column.name)
      expect(page).to have_css("label", text: findable_column.name)
      expect(page).to have_css("label", text: comment_column.name)
      expect(page).to have_css("dd", text: contents_value)
      expect(page).to have_css("dd", text: findable_value)
      expect(page).to have_css("dd", text: comment_value.split("\n")[0])
      expect(page).to have_css("dd", text: comment_value.split("\n")[1])
      expect(page).not_to have_css(".captcha-label", text: "画像の数字を入力してください")

      # proceed ahead
      click_on "送信する"

      expect(page).to have_css(".inquiry-sent", text: "お問い合わせを受け付けました。")
      expect(page).to have_css(".back-to-ref", text: "元のページに戻る")

      expect(Inquiry::Answer.count).to eq 1

      item = Inquiry::Answer.first
      item.cur_site = site
      item.cur_node = node
      expect(item.source_name).to eq page1.name
      expect(item.source_full_url).to eq page1.full_url
      expect(item.source_content.becomes_with_route).to eq page1
    end
  end

  context "with disable captcha and disable confirmation" do
    before do
      node.inquiry_captcha = "disabled"
      node.save!
      part.feedback_confirmation = "disabled"
      part.save!
    end

    it do
      visit page1.full_url

      within ".inquiry-form" do
        choose "item_#{contents_column.id}_#{contents_index}"
        choose "item_#{findable_column.id}_#{findable_index}"
        fill_in "item[#{comment_column.id}]", with: comment_value
      end

      click_on "送信する"

      expect(page).to have_css(".inquiry-sent", text: "お問い合わせを受け付けました。")
      expect(page).to have_css(".back-to-ref", text: "元のページに戻る")

      expect(Inquiry::Answer.count).to eq 1

      item = Inquiry::Answer.first
      item.cur_site = site
      item.cur_node = node
      expect(item.source_name).to eq page1.name
      expect(item.source_full_url).to eq page1.full_url
      expect(item.source_content.becomes_with_route).to eq page1
    end
  end

  context "with upper_html and lower_html" do
    before do
      part.upper_html = '<div class="upper">upper</div>'
      part.lower_html = '<div class="lower">lower</div>'
      part.save!
    end

    it do
      visit page1.full_url

      expect(page).to have_css("div.upper", text: "upper")
      expect(page).to have_css("div.lower", text: "lower")
    end
  end
end
