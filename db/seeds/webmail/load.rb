#
# Webmail demo
#

domain = 'demo.ss-proj.org'
uids = %w(sys admin user1 user2 user3)
users = SS::User.where(:uid.in => uids)

# --------------------------------------
puts "# Convet users"

users.each do |user|
  user.email = user.email.sub(/@.*/, "@#{domain}")
  #user.imap_account = ''
  #user.in_imap_password = 'pass'
  user.save!

  puts "#{user.name}: #{user.email}"
end

# --------------------------------------
puts "# Create addresses"

users.each do |user|
  others = uids.select { |c| c != user.uid }
  others.each do |uid|
    cond = { user_id: user.id, name: uid, email: "#{uid}@#{domain}" }
    item = Webmail::Address.find_or_create_by(cond)
  end

  puts "#{user.name}: [" + others.join(',') + "]"
end

# --------------------------------------
puts "# Create signatures"

users.each do |user|
  cond = { user_id: user.id, name: 'Default Signature', default: 'enabled' }
  item = Webmail::Signature.find_or_create_by(cond)
  item.text = ("=" * 30) + "\n#{user.name} <#{user.email}>"
  item.save

  puts "#{user.name}: #{item.name}"
end
