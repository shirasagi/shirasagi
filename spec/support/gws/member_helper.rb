GWS_MEMBER_DEFAULT_FORM_SELECTOR = "form#item-form".freeze
GWS_MEMBER_DEFAULT_ADDON_SELECTOR = "#addon-gws-agents-addons-member".freeze

def gws_select_member(user, form_selector: nil, addon_selector: nil)
  form_selector ||= GWS_MEMBER_DEFAULT_FORM_SELECTOR
  addon_selector ||= GWS_MEMBER_DEFAULT_ADDON_SELECTOR

  within form_selector do
    within addon_selector do
      click_on I18n.t("ss.apis.users.index")
    end
  end
  wait_for_cbox do
    click_on user.long_name
  end
  within form_selector do
    within addon_selector do
      expect(page).to have_css(".ajax-selected", text: user.name)
    end
  end
end

def gws_select_member_group(group, form_selector: nil, addon_selector: nil)
  form_selector ||= GWS_MEMBER_DEFAULT_FORM_SELECTOR
  addon_selector ||= GWS_MEMBER_DEFAULT_ADDON_SELECTOR

  within form_selector do
    within addon_selector do
      click_on I18n.t("ss.apis.groups.index")
    end
  end
  wait_for_cbox do
    click_on group.trailing_name
  end
  within form_selector do
    within addon_selector do
      expect(page).to have_css(".ajax-selected", text: group.trailing_name)
    end
  end
end

def gws_select_member_custom_group(custom_group, form_selector: nil, addon_selector: nil)
  form_selector ||= GWS_MEMBER_DEFAULT_FORM_SELECTOR
  addon_selector ||= GWS_MEMBER_DEFAULT_ADDON_SELECTOR

  within form_selector do
    within addon_selector do
      click_on I18n.t("gws.apis.custom_groups.index")
    end
  end
  wait_for_cbox do
    click_on custom_group.name
  end
  within form_selector do
    within addon_selector do
      expect(page).to have_css(".ajax-selected", text: custom_group.name)
    end
  end
end
