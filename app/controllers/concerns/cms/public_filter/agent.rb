module Cms::PublicFilter::Agent
  extend ActiveSupport::Concern

  private
    def recognize_path(path, env = {})
      env[:method] ||= request.request_method rescue "GET"
      Rails.application.routes.recognize_path(path, env) rescue {}
    end

    def recognize_agent(path, env = {})
      spec = recognize_path path, env
      spec[:cell] ? spec : nil
    end

    def write_file(item, data, opts = {})
      file = opts[:file] || item.path

      #data_md5 = Digest::MD5.hexdigest(data)
      #if data_md5 != item.md5
      #  item.class.where(id: item.id).update_all md5: data_md5
      #end

      #updated = true
      #if Fs.exists?(file)
      #  updated = false if data_md5 == Digest::MD5.hexdigest(Fs.read(file))
      #end

      updated = true
      if Fs.exists?(file)
        updated = false if data == Fs.read(file)
      end

      updated ? Fs.write(file, data) : nil
    end
end
