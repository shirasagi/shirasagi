class SS::PublicFileRemoverJob < SS::ApplicationJob
  before_perform :configure

  def perform
    traverse_directory(@public_root)
  end

  private

  def configure
    @public_root = "#{site.root_path}/fs"
  end

  def traverse_directory(path)
    count = 0

    if ::File.exist?(path) && ::File.directory?(path)
      ::Dir.foreach(path) do |child_path|
        next if %w(. ..).include?(child_path)

        count += 1

        if child_path == "_"
          remove_if_necessary("#{path}/#{child_path}")
          next
        end

        count += traverse_directory("#{path}/#{child_path}")
      end
    end

    remove_directory(path) if count == 0

    count
  end

  def remove_if_necessary(path)
    id = parse_file_id(path)
    if id.nil?
      return
    end

    file = SS::File.find(id) rescue nil
    if file.blank?
      remove_directory(path)
      return
    end

    if !file.previewable?(site: site, user: nil, member: nil)
      remove_directory(path)
      return
    end
  end

  def parse_file_id(path)
    path = path.sub(@public_root, "")
    path = path.sub("/_", "")
    path = path[1..-1] if path.start_with?("/")
    path = path.delete("/")

    Integer(path) rescue nil
  end

  def remove_directory(path)
    Rails.logger.info("removed '#{path}'")
    ::FileUtils.rm_rf(path)
  end
end
