# LOGIN_REGEXP = /[-a-zA-Z0-9_.!~\[\]\(\)\:=|*^]{3,18}/

LOGIN_REGEXP = /[^\/]+/
ActionController::Routing::Routes.draw do |map|
  map.resources :tags
  
  map.namespace(:admin) do |admin|
    admin.resources :tags
  end


#  map.resources :plataformas, :controller => 'admin/plataformas', :path_prefix => '/admin'

  # map.connect 'admin/', :controller => 'admin/menu', :action => 'index'
  map.connect 'admin/contenidos/recover/:id', :controller => 'admin/contenidos', :action => 'recover'

  map.connect 'admin/categorias/', :controller => 'admin/categorias', :action => 'index'
  
  map.connect 'admin/categorias/create', :controller => 'admin/categorias', :action => 'create'
  map.connect 'admin/categorias/term/:id', :controller => 'admin/categorias', :action => 'root'
  map.connect 'admin/categorias/term/:id/update', :controller => 'admin/categorias', :action => 'update'
  map.connect 'admin/categorias/term/:id/destroy', :controller => 'admin/categorias', :action => 'destroy'
  map.connect 'admin/categorias/term/:id/hijos/:content_type', :controller => 'admin/categorias', :action => 'hijos'
  map.connect 'admin/categorias/term/:id/contenidos/:content_type', :controller => 'admin/categorias', :action => 'contenidos'
  map.connect 'admin/categorias/term/:id/contenidos/:content_type/mass_move', :controller => 'admin/categorias', :action => 'mass_move'

  map.connect 'site/banners/duke', :controller => 'site', :action => 'banners_duke'
  map.connect 'site/banners/misc', :controller => 'site', :action => 'banners_misc'

  map.connect 'competiciones', :controller => 'competiciones', :action => 'index'
  map.connect 'competiciones/cancelar_reto/:participant1_id/:participant2_id', :controller => 'competiciones', :action => 'cancelar_reto'
  map.connect 'competiciones/show/:id', :controller => 'competiciones', :action => 'show'
  map.connect 'competiciones/show/:id/:action', :controller => 'competiciones'
  #map.connect 'competiciones/show/:id/partidas', :controller => 'competiciones', :action =>
  #map.connect 'competiciones/show/:id/participantes', :controller => 'competiciones', :action =>

  map.connect 'cuenta', :controller => 'cuenta/cuenta', :action => 'index'

  map.connect 'cuenta/mis_borradores', :controller => 'cuenta/cuenta', :action => 'mis_borradores'
  map.connect 'cuenta/competiciones', :controller => 'cuenta/competiciones', :action => 'index'
  map.connect 'cuenta/competiciones/hack/:action', :controller => 'cuenta/competiciones'
  map.connect 'cuenta/competiciones/:action', :controller => 'cuenta/competiciones'
  map.connect 'cuenta/configuracion', :controller => 'cuenta/cuenta', :action => 'configuracion'
  map.connect 'cuenta/perfil', :controller => 'cuenta/cuenta', :action => 'perfil'
  map.connect 'cuenta/distrito', :controller => 'cuenta/distrito', :action => 'index'

  map.connect 'cuenta/distrito/categorias', :controller => 'cuenta/distrito/categorias', :action => 'index'
  map.connect 'cuenta/distrito/categorias/create', :controller => 'cuenta/distrito/categorias', :action => 'create'
  map.connect 'cuenta/distrito/categorias/term/:id', :controller => 'cuenta/distrito/categorias', :action => 'root'
  map.connect 'cuenta/distrito/categorias/term/:id/update', :controller => 'cuenta/distrito/categorias', :action => 'update'
  map.connect 'cuenta/distrito/categorias/term/:id/destroy', :controller => 'cuenta/distrito/categorias', :action => 'destroy'
  map.connect 'cuenta/distrito/categorias/term/:id/hijos/:content_type', :controller => 'cuenta/distrito/categorias', :action => 'hijos'
  map.connect 'cuenta/distrito/categorias/term/:id/contenidos/:content_type', :controller => 'cuenta/distrito/categorias', :action => 'contenidos'
  map.connect 'cuenta/distrito/categorias/term/:id/contenidos/:content_type/mass_move', :controller => 'cuenta/distrito/categorias', :action => 'mass_move'

  map.connect 'cuenta/mis_compras', :controller => 'cuenta/tienda', :action => 'mis_compras'
  map.connect 'cuenta/mis_compras/:id', :controller => 'cuenta/tienda', :action => 'configurar_compra'
  map.connect 'cuenta/mis_compras/:id/:action', :controller => 'cuenta/tienda'
  map.connect 'cuenta/clanes', :controller => 'cuenta/clanes/general', :action => 'index'
  map.connect 'cuenta/clanes/banco', :controller => 'cuenta/clanes/general', :action => 'banco'
  map.connect 'cuenta/clanes/new', :controller => 'cuenta/clanes/general', :action => 'new'
  map.connect 'cuenta/clanes/configuracion', :controller => 'cuenta/clanes/general', :action => 'configuracion'
  map.connect 'cuenta/clanes/miembros', :controller => 'cuenta/clanes/general', :action => 'miembros'
  map.connect 'cuenta/clanes/add_member_to_group', :controller => 'cuenta/clanes/general', :action => 'add_member_to_group'
  map.connect 'cuenta/clanes/remove_member_from_group', :controller => 'cuenta/clanes/general', :action => 'remove_member_from_group'
  #map.connect 'cuenta/clanes/miembros', :controller => 'cuenta/clanes/general', :action => 'miembros'
  #map.connect 'cuenta/clanes/contenidos', :controller => 'cuenta/clanes/general', :action => 'contenidos'
  #map.connect 'cuenta/clanes/categorias', :controller => 'cuenta/clanes/general', :action => 'categorias'
  #map.connect 'cuenta/clanes/sponsors', :controller => 'cuenta/clanes/general', :action => 'sponsors'
  map.connect 'cuenta/clanes/amigos', :controller => 'cuenta/clanes/general', :action => 'amigos'
  #map.connect 'cuenta/clanes/banco', :controller => 'cuenta/clanes/general', :action => 'banco'
  map.connect 'cuenta/clanes/switch_active_clan/:id', :controller => 'cuenta/clanes/general', :action => 'switch_active_clan'
  map.connect 'cuenta/notificaciones', :controller => 'cuenta/cuenta', :action => 'notificaciones'
  map.connect 'cuenta/amigos', :controller => 'cuenta/amigos', :action => 'index'
  map.connect 'cuenta/amigos/aceptar_amistad/:login', :controller => 'cuenta/amigos', :action => 'aceptar_amistad', :login => LOGIN_REGEXP
  map.connect 'cuenta/amigos/iniciar_amistad/:login', :controller => 'cuenta/amigos', :action => 'iniciar_amistad', :login => LOGIN_REGEXP
  map.connect 'cuenta/amigos/cancelar_amistad/:login', :controller => 'cuenta/amigos', :action => 'cancelar_amistad', :login => LOGIN_REGEXP
  map.connect 'cuenta/amigos/:action', :controller => 'cuenta/amigos', :action => 'index'
  map.connect 'cuenta/tienda', :controller => 'cuenta/tienda', :action => 'index'
  map.connect 'cuenta/mis_canales', :controller => 'cuenta/mis_canales', :action => 'index'
  map.connect 'cuenta/mis_canales/:action', :controller => 'cuenta/mis_canales'
  map.connect 'cuenta/mis_canales/:action/:id', :controller => 'cuenta/mis_canales'
  map.connect 'cuenta/tienda/:id', :controller => 'cuenta/tienda', :action => 'show'
  map.connect 'cuenta/tienda/:id/:action', :controller => 'cuenta/tienda'
  map.connect 'cuenta/avatar', :controller => 'cuenta/cuenta', :action => 'avatar'
  map.connect 'cuenta/banco', :controller => 'cuenta/banco', :action => 'index'
  map.connect 'cuenta/mensajes', :controller => 'cuenta/mensajes', :action => 'mensajes'
  map.connect 'cuenta/comentarios', :controller => 'cuenta/comentarios', :action => 'index'
  map.connect 'cuenta/skins', :controller => 'cuenta/skins', :action => 'index'
  map.connect 'cuenta/estadisticas', :controller => 'cuenta/cuenta', :action => 'estadisticas'
  map.connect 'cuenta/estadisticas/registros', :controller => 'cuenta/cuenta', :action => 'estadisticas_registros'
  map.connect 'cuenta/estadisticas/resurrecciones', :controller => 'cuenta/cuenta', :action => 'estadisticas_resurrecciones'
  map.connect 'cuenta/estadisticas/hits', :controller => 'cuenta/cuenta', :action => 'estadisticas_hits'
  map.connect 'cuenta/imagenes', :controller => 'cuenta/cuenta', :action => 'imagenes'
  map.connect 'cuenta/imagenes/borrar', :controller => 'cuenta/cuenta', :action => 'borrar_imagen'
  map.connect 'cuenta/faccion', :controller => 'cuenta/faccion', :action => 'index'
  map.connect 'cuenta/faccion/mapas_juegos', :controller => 'cuenta/faccion', :action => 'mapas_juegos'
  map.connect 'cuenta/faccion/mapas_juegos/:action/:id', :controller => 'cuenta/faccion'
  map.connect 'cuenta/faccion/informacion', :controller => 'cuenta/faccion', :action => 'informacion'
  
  map.connect 'cuenta/faccion/categorias', :controller => 'cuenta/faccion/categorias', :action => 'index'
  map.connect 'cuenta/faccion/categorias/create', :controller => 'cuenta/faccion/categorias', :action => 'create'
  map.connect 'cuenta/faccion/categorias/term/:id', :controller => 'cuenta/faccion/categorias', :action => 'root'
  map.connect 'cuenta/faccion/categorias/term/:id/update', :controller => 'cuenta/faccion/categorias', :action => 'update'
  map.connect 'cuenta/faccion/categorias/term/:id/destroy', :controller => 'cuenta/faccion/categorias', :action => 'destroy'
  map.connect 'cuenta/faccion/categorias/term/:id/hijos/:content_type', :controller => 'cuenta/faccion/categorias', :action => 'hijos'
  map.connect 'cuenta/faccion/categorias/term/:id/contenidos/:content_type', :controller => 'cuenta/faccion/categorias', :action => 'contenidos'
  map.connect 'cuenta/faccion/categorias/term/:id/contenidos/:content_type/mass_move', :controller => 'cuenta/faccion/categorias', :action => 'mass_move'
  
  map.connect 'cuenta/faccion/cabeceras/new', :controller => 'cuenta/faccion', :action => 'cabeceras_new'
  map.connect 'cuenta/faccion/cabeceras/create', :controller => 'cuenta/faccion', :action => 'cabeceras_create'
  map.connect 'cuenta/faccion/cabeceras/update/:id', :controller => 'cuenta/faccion', :action => 'cabeceras_update'
  map.connect 'cuenta/faccion/cabeceras/edit/:id', :controller => 'cuenta/faccion', :action => 'cabeceras_edit', :requirements => { :id => /\d+/ }
  map.connect 'cuenta/faccion/cabeceras/destroy/:id', :controller => 'cuenta/faccion', :action => 'cabeceras_destroy', :requirements => { :id => /\d+/ }
  map.connect 'cuenta/faccion/links/new', :controller => 'cuenta/faccion', :action => 'links_new'
  map.connect 'cuenta/faccion/links/create', :controller => 'cuenta/faccion', :action => 'links_create'
  map.connect 'cuenta/faccion/links/update/:id', :controller => 'cuenta/faccion', :action => 'links_update'
  map.connect 'cuenta/faccion/links/edit/:id', :controller => 'cuenta/faccion', :action => 'links_edit', :requirements => { :id => /\d+/ }
  map.connect 'cuenta/faccion/links/destroy/:id', :controller => 'cuenta/faccion', :action => 'links_destroy', :requirements => { :id => /\d+/ }
  map.connect 'cuenta/faccion/alertas/show/:id', :controller => 'cuenta/faccion', :action => 'alertas_show', :requirements => { :id => /\d+/ }
  map.connect 'cuenta/faccion/alertas/new', :controller => 'cuenta/faccion', :action => 'alertas_new'

  map.connect 'cuenta/apuestas', :controller => 'cuenta/apuestas'
  map.connect 'cuenta/faccion', :controller => 'cuenta/faccion'
  map.connect 'cuenta/guids', :controller => 'cuenta/guids'
  map.connect 'cuenta/blog', :controller => 'cuenta/blog'
  map.connect 'cuenta/blog/:action/:id', :controller => 'cuenta/blog'
  map.connect 'cuenta/:action', :controller => 'cuenta/cuenta'

  map.connect 'account/messages', :controller => 'account', :action => 'messages'
  map.connect 'account/messages/:id', :controller => 'account', :action => 'show_message'
  map.connect 'miembros/buscar', :controller => 'miembros', :action => 'buscar'
  map.connect 'miembros/buscar/:s', :controller => 'miembros', :action => 'buscar'
  map.connect 'miembros/buscar_por_guid', :controller => 'miembros', :action => 'buscar_por_guid'
  map.connect "blogs/ranking", :controller => 'blogs', :action => 'ranking'
  map.connect "blogs/:login", :controller => 'blogs', :action => 'blog', :login => LOGIN_REGEXP
  map.connect "blogs/:login/:id", :controller => 'blogs', :action => 'blogentry', :requirements => { :id => /\d+/ }, :login => LOGIN_REGEXP
  map.connect 'miembros/explorar', :controller => 'miembros', :action => 'explorar'
  map.connect 'miembros/del_firma/:id', :controller => 'miembros', :action => 'del_firma'
  map.connect 'miembros/:login', :controller => 'miembros', :action => 'member' , :login => LOGIN_REGEXP
  map.connect "miembros/:login/contenidos/:content_name", :controller => 'miembros', :action => 'contenidos_tipo'  , :login => LOGIN_REGEXP
  map.connect "miembros/:login/contenidos", :controller => 'miembros', :action => 'contenidos' , :login => LOGIN_REGEXP
  map.connect "miembros/:login/:action", :controller => 'miembros' , :login => LOGIN_REGEXP

  map.connect 'clanes/clan/:id/miembros', :controller => 'clanes', :action => 'clan_miembros'
  map.connect 'clanes/clan/:id/noticias', :controller => 'clanes', :action => 'clan_noticias'
  map.connect 'clanes/clan/:id/eventos', :controller => 'clanes', :action => 'clan_eventos'
  map.connect 'clanes/clan/:id/descargas', :controller => 'clanes', :action => 'clan_descargas'
  map.connect 'clanes/clan/:id/imagenes', :controller => 'clanes', :action => 'clan_imagenes'
  map.connect 'clanes/:action', :controller => 'clanes'

  map.connect "imagenes/new", :controller => 'imagenes', :action => 'new'
  map.connect "imagenes/create_from_zip", :controller => 'imagenes', :action => 'create_from_zip'
  map.connect "imagenes/potds", :controller => 'imagenes', :action => 'potds'
  map.connect "imagenes/create", :controller => 'imagenes', :action => 'create'
  map.connect "imagenes/:category", :controller => 'imagenes', :action => 'category', :requirements => { :category => /\d+/ }
  map.connect "descargas/list", :controller => 'descargas', :action => 'index'
  map.connect "descargas/create", :controller => 'descargas', :action => 'create'
  map.connect "descargas/create_from_zip", :controller => 'descargas', :action => 'create_from_zip'
  map.connect "descargas/new", :controller => 'descargas', :action => 'new'
  map.connect "descargas/:category", :controller => 'descargas', :action => 'index', :requirements => { :category => /\d+/ }

  map.connect "foros/nuevo_topic", :controller => 'foros', :action => 'nuevo_topic'
  map.connect "foros/topics_activos", :controller => 'foros', :action => 'topics_activos'
  
  map.connect "tutoriales/list", :controller => 'tutoriales', :action => 'index'
  map.connect "tutoriales/create", :controller => 'tutoriales', :action => 'create'
  map.connect "tutoriales/new", :controller => 'tutoriales', :action => 'new'
  map.connect "tutoriales/:category", :controller => 'tutoriales', :action => 'index', :requirements => { :category => /\d+/ }


  map.connect 'cache/thumbnails/:mode/:dim/*path', :controller => 'cache', :action => 'thumbnails'
  map.connect 'cache/graphs/:action/:date/*faction_id', :controller => 'cache'
  map.connect "site/sponsors", :controller => 'site', :action => 'sponsors'
  map.connect "site/sponsors/:sponsor", :controller => 'site', :action => 'sponsor'
  map.connect '', :controller => 'home', :action => 'index', :title => 'Inicio'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect 'site/slog.:format', :controller => 'site', :action => 'slog' 
  map.connect '*path' , :controller => 'application' , :action => 'http_404' # necesario para coger todas las demás rutas inexistentes
  
    # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"
end
