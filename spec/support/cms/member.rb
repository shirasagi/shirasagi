def cms_member(site: cms_site, email: 'admin@example.jp')
  member = Cms::Member.where(email: email).first
  member ||= create(:cms_member, site: site, email: email, in_password: "abc123", in_password_again: "abc123")
  member.attributes = { in_password: "abc123", in_password_again: "abc123" }
  member
end

def login_member(site, node, member = cms_member(site: site))
  login_url = "http://#{site.domain}#{node.url}login.html"

  visit login_url
  within 'form.form-login' do
    fill_in 'item[email]', with: member.email
    fill_in 'item[password]', with: member.in_password
    click_button 'ログイン'
  end
rescue => e
  Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  raise
end

def logout_member(site, node, member = cms_member(site: site))
  logout_url = "http://#{site.domain}#{node.url}logout.html"
  visit logout_url
end
