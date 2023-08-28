class Gws::Workload::Apis::WorksController < ApplicationController
  include Gws::ApiFilter

  model Gws::Workload::Work

  helper_method :category_options, :load_options, :client_options, :cycle_options

  def form_options
    @item = @model.find(params[:id]) rescue nil
    @item ||= @model.new

    @year = params[:year].to_i if params[:year].match?(/\A\d+\z/)
    @group = Gws::Group.find(params[:group]) rescue nil

    if @year && @group
      @categories = Gws::Workload::Category.site(@cur_site).member_group(@group).search_year(year: @year).to_a
      @loads = Gws::Workload::Load.site(@cur_site).search_year(year: @year).to_a
      @cycles = Gws::Workload::Cycle.site(@cur_site).search_year(year: @year).to_a
      @clients = Gws::Workload::Client.site(@cur_site).search_year(year: @year).to_a
    end

    render layout: false
  end

  def category_options
    @categories.to_a.map { |c| [c.name, c.id] }
  end

  def load_options
    @loads.to_a.map { |l| [l.name, l.id] }
  end

  def client_options
    @clients.to_a.map { |c| [c.name, c.id] }
  end

  def cycle_options
    @cycles.to_a.map { |c| [c.name, c.id] }
  end
end
