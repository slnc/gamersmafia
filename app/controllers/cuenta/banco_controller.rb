class Cuenta::BancoController < ApplicationController
  before_filter :require_auth_users

  def index
    @navpath = [['Preferencias', '/cuenta'], ['Banco', '/cuenta/banco']]
  end
end
