class Event::Agents::Tasks::Page::PagesController < ApplicationController
  def import_csv
    importer = Event::Page::CsvImporter.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end

  def import_ical
    importer = Event::Page::IcalImporter.new(@site, @node, @user)
    options = { task: @task }
    importer.import(*(@args + [options]))
    head :ok
  end
end
