namespace :inquiry do
  task delete_inquiry_temp_files: :environment do
    puts "delete_inquiry_temp_files"

    yesterday = Time.zone.now.yesterday
    ss_files = SS::File.where(model: "inquiry/temp_file").where(updated: { "$lt" => yesterday })
    ss_files.destroy_all
  end
end
