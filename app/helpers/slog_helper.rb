module SlogHelper
  def submenu_items
    its = []
    # TODO permisos
    its << ['Webmaster', '/slog/webmaster'] if @user.is_superadmin?
    its << ['Capo', '/slog/capo'] if @user.has_admin_permission?(:capo)
    its << ['Alcalde', '/slog/bazar_manager'] if @user.has_admin_permission?(:bazar_manager)
    its << ['Gladiador', '/slog/gladiador'] if @user.has_admin_permission?(:gladiador)
    its << ['Boss', '/slog/faction_bigboss'] if @user.is_faction_leader?
    its << ['Don', '/slog/bazar_district_bigboss'] if @user.is_district_leader?
    its << ['Moderador', '/slog/moderator'] if @user.is_moderator?
    its << ['Editor', '/slog/editor'] if @user.is_faction_editor?
    its << ['Sicario', '/slog/sicario'] if @user.is_sicario?
    its << ['Admin comp', '/slog/competition_admin'] if @user.is_competition_admin?
    its << ['Supervisor comp', '/slog/competition_supervisor'] if @user.is_competition_supervisor?
    its
  end
end
