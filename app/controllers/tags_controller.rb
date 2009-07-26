class TagsController < ApplicationController
  def index
    
  end
  
  def show
    @tag = Term.find(params[:id])
    @title = @tag.name
  end
end
