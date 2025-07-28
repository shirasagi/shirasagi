require 'spec_helper'

describe "webmail_groups", type: :feature, dbscope: :example do
  before { login_webmail_admin }

  it do
    #
    # Create
    #
    visit webmail_groups_path
    click_on I18n.t("ss.links.new")
    within "form#item-form" do
      fill_in "item[name]", with: "#{webmail_admin.groups.first.name}/name"
      click_button I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t('ss.notice.saved')

    #
    # Update
    #
    visit webmail_groups_path
    click_on "#{webmail_admin.groups.first.name}/name"
    click_on I18n.t("ss.links.edit")
    within "form#item-form" do
      fill_in "item[name]", with: "#{webmail_admin.groups.first.name}/name2"
      click_button I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t('ss.notice.saved')

    #
    # Delete
    #
    visit webmail_groups_path
    click_on "#{webmail_admin.groups.first.name}/name2"
    click_on I18n.t("ss.links.delete")
    within "form" do
      click_button I18n.t("ss.buttons.delete")
    end
    wait_for_notice I18n.t('ss.notice.deleted')
  end
end
