class Cuenta::Distrito::CategoriasController < Admin::CategoriasController
  public
  def categorias_skip_path
    '../../../'
  end

  def cats_path
    'cuenta/distrito/categorias'
  end
end
