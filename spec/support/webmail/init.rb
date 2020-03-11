require 'docker'
require 'net/imap'

module SS::WebmailSupport
  module_function

  def test_by
    @test_by
  end

  def test_by=(value)
    @test_by = value
  end

  def docker_conf
    @docker_conf ||= SS.config.webmail.test_docker || {}
  end

  def docker_conf_api_url
    SS::WebmailSupport.docker_conf["api_url"].presence
  end

  def docker_conf_container_id
    SS::WebmailSupport.docker_conf["container_id"].presence || "test_mail"
  end

  def docker_conf_host
    @docker_conf_host ||= begin
      SS::WebmailSupport.docker_conf["host"].presence || "localhost"
    end
  end

  def docker_conf_auth_type
    @docker_conf_imap_auth_type ||= begin
      SS::WebmailSupport.docker_conf["auth_type"].presence || "CRAM-MD5"
    end
  end

  def docker_conf_account
    @docker_conf_imap_account ||= begin
      SS::WebmailSupport.docker_conf["account"].presence || "user5@example.jp"
    end
  end

  def docker_container
    @docker_container
  end

  def docker_container=(value)
    @docker_container = value
  end

  def docker_imap_port
    @docker_imap_port
  end

  def docker_imap_port=(value)
    @docker_imap_port = value
  end

  def init
    if travis?
      test_by = "docker"
    else
      test_by = SS.config.webmail.test_by
    end

    case test_by
    when "docker"
      init_test_by_docker
      SS::WebmailSupport.test_by = "docker"
    else
      init_test_by_user
      SS::WebmailSupport.test_by = "user"
    end

    RSpec.configuration.extend(SS::WebmailSupport::EventHandler, imap: true)
  rescue => e
    RSpec.configuration.filter_run_excluding(imap: true)
  end

  def init_test_by_user
    if SS.config.webmail.test_user.blank?
      RSpec.configuration.filter_run_excluding(imap: true)
    end
  end

  def init_test_by_docker
    api_url = SS::WebmailSupport.docker_conf_api_url
    Docker.url = api_url if api_url.present?

    container_id = SS::WebmailSupport.docker_conf_container_id
    container = SS::WebmailSupport.docker_container = Docker::Container.get(container_id)

    bindings = container.json["HostConfig"]["PortBindings"]
    version = Docker.version["Version"]
    imap_port = SS::WebmailSupport.docker_imap_port = bindings["143/tcp"].first["HostPort"].to_i

    puts "found docker #{version} and container '#{container_id}' listening on #{imap_port} for imap"
  rescue
    puts "docker seems not to be installed or be running or have container '#{container_id}'"
    RSpec.configuration.filter_run_excluding(imap: true)
  end

  def test_conf
    case SS::WebmailSupport.test_by
    when "docker"
      docker_test_conf
    else
      user_test_conf
    end
  end

  def user_test_conf
    SS.config.webmail.test_user || {}
  end

  def docker_test_conf
    {
      'host' => SS::WebmailSupport.docker_conf_host,
      'imap_port' => SS::WebmailSupport.docker_imap_port,
      'imap_auth_type' => SS::WebmailSupport.docker_conf_auth_type,
      'account' => SS::WebmailSupport.docker_conf_account
    }
  end

  def before_example
    case SS::WebmailSupport.test_by
    when "docker"
      docker_ensure_container_started
      docker_ensure_system_folders_created

      test_conf = docker_test_conf
      default_conf = {
        "host" => test_conf['host'],
        "options" => { "port" => test_conf['imap_port'] },
        "auth_type" => test_conf['imap_auth_type'],
        "account" => "email"
      }
      SS.config.webmail.clients ||= {}
      SS.config.webmail.clients['default'] = default_conf
    end
  end

  def after_example
    case SS::WebmailSupport.test_by
    when "docker"
      docker_clean_mails
    end
  end

  def docker_ensure_container_started
    container = SS::WebmailSupport.docker_container
    return if container.blank?

    status = container.json["State"]["Status"]
    if status != "running"
      print "staring container .. "
      container.start
      sleep(5)
      puts "done"
    end
  end

  def docker_ensure_system_folders_created
    container = SS::WebmailSupport.docker_container
    user = SS::WebmailSupport.docker_conf_account
    return if container.blank? || user.blank?

    @docker_ensure_system_folders_created ||= begin
      container.exec(["doveadm", "mailbox", "create", "INBOX.Draft", "-u", user])
      container.exec(["doveadm", "mailbox", "create", "INBOX.Sent", "-u", user])
      container.exec(["doveadm", "mailbox", "create", "INBOX.Trash", "-u", user])
      true
    end
  end

  def docker_clean_mails
    container = SS::WebmailSupport.docker_container
    return if container.blank?

    user = SS::WebmailSupport.docker_conf_account
    stdout, _, exit_status = container.exec(["doveadm", "mailbox", "list", "-u", user])
    if exit_status != 0
      puts "list to list mailboxes for #{user}"
      return
    end

    stdout.join.lines.each do |line|
      mailbox = line.strip
      _, _, exit_status = container.exec(["doveadm", "expunge", "-u", user, "MAILBOX", mailbox, "ALL"])
      if exit_status != 0
        puts "#{mailbox}: mail cleaner error for user #{user}"
      end
    end
  rescue
    puts "mail cleaner error"
  end

  module EventHandler
    extend ActiveSupport::Concern

    def self.extended(obj)
      obj.before(:example) do
        SS::WebmailSupport.before_example
      end

      obj.after(:example) do
        SS::WebmailSupport.after_example
      end
    end
  end
end

SS::WebmailSupport.init

def webmail_new_part(media_type)
  return Net::IMAP::BodyTypeMultipart.new if media_type == "MULTIPART"
  return Net::IMAP::BodyTypeBasic.new if media_type == 'IMAGE'

  Net::IMAP::BodyTypeText.new
end

def webmail_new_parts(conf)
  conf.to_a.map do |y|
    part = webmail_new_part(y['media_type'])
    y.each { |k, v| part.send("#{k}=", v) }
    part.disposition = webmail_new_disposition(y['disposition']) if y['disposition']
    part
  end
end

def webmail_new_disposition(conf)
  disp = Net::IMAP::ContentDisposition.new
  conf.each { |k, v| disp.send("#{k}=", v) }
  disp
end

def webmail_load_mail(name)
  yaml = YAML.load_file("#{Rails.root}/spec/fixtures/webmail/mail/#{name}")

  data = Net::IMAP::FetchData.new
  data.attr = yaml.dup

  body = webmail_new_part(yaml["BODYSTRUCTURE"]["media_type"])

  yaml["BODYSTRUCTURE"].each do |key, val|
    next if key == 'parts'

    body.send("#{key}=", val)
  end
  data.attr["BODYSTRUCTURE"] = body

  if yaml["BODYSTRUCTURE"]['parts']
    data.attr["BODYSTRUCTURE"]['parts'] = webmail_new_parts(yaml["BODYSTRUCTURE"]['parts'])
  end

  item = Webmail::Mail.new
  item.parse(data)
  item.parse_body_structure
  item.text = yaml['BODY'][item.text_part_no.to_i] if item.text_part_no
  item.html = yaml['BODY'][item.html_part_no.to_i] if item.html_part_no

  item.attachments.each do |part|
    part.data = yaml['BODY'][part.section.to_i]
  end
  item
end

def webmail_import_mail(user, mail_or_msg, account: 0, date: Time.zone.now, mailbox: 'INBOX')
  msg = mail_or_msg.is_a?(String) ? mail_or_msg : mail_or_msg.to_s

  # Use IMAP api directly to import none-sanitized eml message.
  imap_setting = user.imap_settings[account]
  imap = Webmail::Imap::Base.new_by_user(user, imap_setting)
  imap.login
  imap.examine(mailbox)
  imap.conn.append(mailbox, msg, [:Seen], date)
end

def webmail_reload_mailboxes(user, account: 0)
  imap_setting = user.imap_settings[account]
  imap = Webmail::Imap::Base.new_by_user(user, imap_setting)
  imap.login
  imap.mailboxes.reload
end
