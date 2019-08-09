class Event::Agents::Tasks::Page::PagesController < ApplicationController
  def import

    if @import_method == "csv"
      importer = Event::Page::CsvImporter.new(@site, @node, @user)
    elsif @import_method == "ical"
      importer = Event::Page::IcalImporter.new(@site, @node, @user)
    else
      raise "unknown import method"
    end

    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
