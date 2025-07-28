class Event::Agents::Tasks::Page::PagesController < ApplicationController
  def import_ical
    importer = Event::Page::IcalImporter.new(@site, @node, @user)
    options = { task: @task }
    importer.import(*(@args + [options]))
    head :ok
  end
end
