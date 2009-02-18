load RAILS_ROOT + '/Rakefile'

class Admin::ScriptsController < ApplicationController
  before_filter :require_auth_admins

  def index
  end
  
  def fix_categories
    Rake::Task["gm:sync_indexes:fix_categories"].invoke
    flash[:notice] = "Categorías de contenidos principales revisadas correctamente."
    redirect_to '/admin/scripts'
  end
  
  def fix_categories_count
    Rake::Task["gm:sync_indexes:fix_categories_count"].invoke
    flash[:notice] = "Índices recalculados correctamente."
    redirect_to '/admin/scripts'
  end
end
