# coding: utf-8
namespace :cms do

  namespace :layout do
    task :generate => :environment do
      Cms::Task::LayoutsController.new.generate
    end
    
    task :remove => :environment  do
      Cms::Task::LayoutsController.new.remove
    end
  end
  
  namespace :page do
    task :release => :environment do
      Cms::Task::PagesController.new.release
    end
    
    task :generate => :environment do
      Cms::Task::PagesController.new.generate
    end
    
    task :remove => :environment do
      Cms::Task::PagesController.new.remove
    end
  end
end
