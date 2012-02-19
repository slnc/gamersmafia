class Cuenta::Faccion::CategoriasController < Admin::CategoriasController
  public
  def categorias_skip_path
    '../../../'
  end

  def cats_path
    'cuenta/faccion/categorias'
  end
end
