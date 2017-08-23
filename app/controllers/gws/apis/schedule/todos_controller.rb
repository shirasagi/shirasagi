# class Gws::Apis::Schedule::TodosController < ApplicationController
#   include Gws::ApiFilter
#   include Gws::CrudFilter
#
#   model Gws::Schedule::Todo
#
#   before_action :set_item
#
#   # [GET] /todos/:id/finish(.:format)
#   def finish
#     @item.finished = true
#
#     if @item.valid? && @item.save
#       render plain: @item.finished_name, layout: false
#     else
#       render plain: 'Error', layout: false
#     end
#   end
#
#   # [GET] /todos/:id/revert(.:format)
#   def revert
#     @item.finished = false
#
#     if @item.valid? && @item.save
#       render plain: @item.finished_name, layout: false
#     else
#       render plain: 'Error', layout: false
#     end
#   end
# end
