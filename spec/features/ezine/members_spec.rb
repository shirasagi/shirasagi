require 'spec_helper'

describe "ezine_members", type: :feature do
  let!(:site) { cms_site }
  let!(:node) { create :ezine_node_page, cur_site: site }

  before { login_cms_user }

  context "basic crud" do
    it do
      visit ezine_members_path(site.id, node)
      expect(current_path).not_to eq sns_login_path

      visit new_ezine_member_path(site.id, node)
      within "form#item-form" do
        fill_in "item[email]", with: "sample@example.jp"
        find("input[name='item[email_type]'][value='text']").set(true) #choose "テキスト版"
        find("input[name='item[state]'][value='enabled']").set(true)   #choose "配信する"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_ezine_member_path(site.id, node)
      expect(page).to have_no_css("form#item-form")

      item = Ezine::Member.last
      visit ezine_member_path(site.id, node, item)
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path

      visit edit_ezine_member_path(site.id, node, item)
      within "form#item-form" do
        find("input[name='item[email_type]'][value='html']").set(true) #choose "HTML版"
        find("input[name='item[state]'][value='disabled']").set(true)  #choose "配信しない"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      visit delete_ezine_member_path(site.id, node, item)
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      expect(current_path).to eq ezine_members_path(site.id, node)
    end
  end

  context "with column" do
    before do
      @column1 = create(:ezine_column, node: node, name: "text_field", input_type: "text_field", state: "public")
      @column2 = create(:ezine_column, node: node, name: "text_area", input_type: "text_area", state: "public")
      @column3 = create(:ezine_column, node: node, name: "radio_button", input_type: "radio_button",
                        select_options: %w(radio_button1 radio_button2), state: "public")
      @column4 = create(:ezine_column, node: node, name: "select", input_type: "select",
                        select_options: %w(select1 select2), state: "public")
      @column5 = create(:ezine_column, node: node, name: "check_box", input_type: "check_box",
                        select_options: %w(check_box1 check_box2), state: "public")
    end

    it do
      visit new_ezine_member_path(site.id, node)
      within "form#item-form" do
        fill_in "item[email]", with: "sample2@example.jp"
        find("input[name='item[email_type]'][value='text']").set(true) #choose "テキスト版"
        find("input[name='item[state]'][value='enabled']").set(true)   #choose "配信する"
        fill_in "item[in_data][#{@column1.id}]", with: "text_field1"
        fill_in "item[in_data][#{@column2.id}]", with: "text_area1"
        choose @column3.select_options.first
        select @column4.select_options.first
        check @column5.select_options.first
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_ezine_member_path(site.id, node)
      expect(page).to have_no_css("form#item-form")

      item = Ezine::Member.last
      expect(item.data.count).to eq 5
      expect(item.data.where(column_id: @column1.id).first.try(:value)).to eq 'text_field1'
      expect(item.data.where(column_id: @column2.id).first.try(:value)).to eq 'text_area1'
      expect(item.data.where(column_id: @column3.id).first.try(:value)).to eq 'radio_button1'
      expect(item.data.where(column_id: @column4.id).first.try(:value)).to eq 'select1'
      expect(item.data.where(column_id: @column5.id).first.try(:value)).to eq "check_box1"

      visit edit_ezine_member_path(site.id, node, item)
      within "form#item-form" do
        find("input[name='item[email_type]'][value='html']").set(true) #choose "HTML版"
        find("input[name='item[state]'][value='disabled']").set(true)  #choose "配信しない"
        fill_in "item[in_data][#{@column1.id}]", with: "text_field2"
        fill_in "item[in_data][#{@column2.id}]", with: "text_area2"
        choose @column3.select_options.last
        select @column4.select_options.last
        @column5.select_options.each do |opt|
          check opt
        end
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      item.reload
      expect(item.data.count).to eq 5
      expect(item.data.where(column_id: @column1.id).first.try(:value)).to eq 'text_field2'
      expect(item.data.where(column_id: @column2.id).first.try(:value)).to eq 'text_area2'
      expect(item.data.where(column_id: @column3.id).first.try(:value)).to eq 'radio_button2'
      expect(item.data.where(column_id: @column4.id).first.try(:value)).to eq 'select2'
      expect(item.data.where(column_id: @column5.id).first.try(:value)).to eq "check_box1\ncheck_box2"

      visit delete_ezine_member_path(site.id, node, item)
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      expect(current_path).to eq ezine_members_path(site.id, node)
    end
  end
end
