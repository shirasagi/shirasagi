class Gws::Monitor::TopicZipTask
  include Gws::Model::Task

  embeds_ids :zipped_files, class_name: "SS::File"
end
