class Opendata::Agents::Tasks::Page::DatasetsController < ApplicationController
  def import
    importer = Opendata::Dataset::Importer.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
