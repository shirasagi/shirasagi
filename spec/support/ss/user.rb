def ss_user
  ss_user = SS::User.where(email: build(:ss_user).email).first
  ss_user ||= create(:ss_user)
  ss_user
end

def ss_group
  ss_group = SS::Group.where(name: build(:ss_group).name).first
  ss_group ||= create(:ss_group)
  ss_group
end

def ss_site
  ss_site = Cms::Site.where(host: build(:ss_site).host).first
  ss_site ||= create(:ss_site, group_ids: [ss_group.id])
  ss_site
end

def login_user(user, pass: nil, login_path: nil, to: nil)
  visit login_path.presence || sns_login_path
  ref = to.presence || '/robots.txt'
  within "form" do
    fill_in "item[email]", with: user.email.presence || user.uid
    fill_in "item[password]", with: pass.presence || user.in_password.presence || "pass"
    set_value_to_hidden_input('input[name="ref"]', ref)
    click_button I18n.t("ss.login", locale: I18n.default_locale)
  end
  # rubocop:disable Rails/I18nLocaleAssignment
  if user.lang.present?
    I18n.locale = user.lang.to_sym
  end
  # rubocop:enable Rails/I18nLocaleAssignment

  if ref == '/robots.txt'
    expect(page).to have_content('User-agent')
  else
    expect(page).to have_css('#head', text: user.name)
  end
end

# set value to hidden input
def set_value_to_hidden_input(selector, value)
  if page.driver.is_a?(Capybara::Selenium::Driver)
    page.execute_script("$('#{selector}').val('#{value}');")
  else
    first(selector, visible: false).set(value)
  end
end

def login_ss_user(to: nil)
  login_user ss_user, to: to
end
