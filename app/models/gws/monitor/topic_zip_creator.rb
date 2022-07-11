class Gws::Monitor::TopicZipCreator
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :cur_group, :topic

  delegate :zip_path, to: :topic

  def create_zip
    synchronized do
      topic.attend_groups.each do |group|
        order = group.order || 0
        basename = "#{order}_#{group.trailing_name}"

        topic.comment(group.id).each do |post|
          SS::File.each_file(post.file_ids) do |file|
            next unless ::File.exist?(file.path)
            @zip_file.add ::Fs.zip_safe_name("#{basename}_#{file.name}"), file.path rescue nil
          end
        end
      end

      order = cur_group.order || 0
      basename = "own_#{order}_#{cur_group.trailing_name}"
      SS::File.each_file(topic.file_ids) do |file|
        next unless ::File.exist?(file.path)
        @zip_file.add ::Fs.zip_safe_name("#{basename}_#{file.name}"), file.path rescue nil
      end
    end

    self.errors.blank?
  end

  private

  def synchronized(&block)
    zip_path = topic.zip_path

    Gws::Task.find_or_create_for_model(topic, site: cur_site).tap do |task|
      rejected = -> { self.errors.add :base, :other_task_is_running }
      task.run_with(rejected: rejected) do
        ::File.dirname(zip_path).tap do |zip_dir|
          ::FileUtils.mkdir_p(zip_dir) unless ::Dir.exist?(zip_dir)
        end

        ::FileUtils.rm_f zip_path
        Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
          @zip_file = zip_file
          yield
        ensure
          @zip_file = nil
        end
      end
    end

    zip_path
  end
end
