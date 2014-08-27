# coding: utf-8
namespace :ss do
  task :update => :environment  do

    #puts "replace user password"
    #SS::User.all.each do |item|
    #  item.password = SS::Crypt.crypt("pass")
    #  item.save
    #end

    puts "update parts.mobile_view"
    Cms::Part.all.each do |item|
      item.mobile_view = "show" if item.mobile_view.blank?
      item.save
    end

    puts "success"
  end
end
