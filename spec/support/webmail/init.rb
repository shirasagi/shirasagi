if SS.config.webmail.test_user.blank?
  RSpec.configuration.filter_run_excluding(imap: true)
end

require 'net/imap'

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
