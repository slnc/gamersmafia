class CacheController < ApplicationController
  def thumbnails
    # TODO proteger
    raise ActiveRecord::RecordNotFound if (not %w(f k i).include?(params[:mode]) or not params[:dim])
    sp = request.request_uri
    
    begin
      5.times { sp = sp[(sp.index('/') + 1)..-1] }
    rescue
      raise ActiveRecord::RecordNotFound
    end
    sp = URI::unescape(sp.gsub(/\.\./, '').gsub('+', '%20'))
    raise ActiveRecord::RecordNotFound if not sp =~ /\./ or sp.match(/\/$/) # no es una url válida
    
    match_dim = params[:dim].match(/([0-9]+)x([0-9]+)/)
    raise ActiveRecord::RecordNotFound if not match_dim
    
    thumbpath = "#{RAILS_ROOT}/public/cache/thumbnails/#{params[:mode]}/#{match_dim[1]}x#{match_dim[2]}/#{sp}"
    Cms::image_thumbnail("#{RAILS_ROOT}/public/#{sp}", thumbpath, match_dim[1].to_i, match_dim[2].to_i, params[:mode])
    
    send_file(thumbpath, :type => 'image/jpg', :stream => false, :disposition => 'inline')
    # redirect_to "/cache/thumbnails/#{params[:mode]}/#{params[:dim]}/#{params[:path]}"
  end  
  
  def faction_users_ratios
    require 'rubygems'
    require 'gruff'
    g = Gruff::Mini::Pie.new(150)
    g.theme = {
      :marker_color => '#666666',
      :background_colors => %w(white white)
    }
    
    f = Faction.find(params[:faction_id][0].gsub('.png', '').to_i)
    g.data('Activos', [f.active_members_count], '#BB0012')
    g.data('Inactivos', [f.inactive_members_count], '#BBA9AB')
    g.font= "#{RAILS_ROOT}/public/ttf/verdana.ttf"
    # no usamos date para evitar ataques de denegación de servicio generando imágenes para cada año
    dst = "#{RAILS_ROOT}/public/cache/graphs/faction_users_ratios/#{Time.now.strftime('%Y%m%d')}/#{f.id}.png"
    FileUtils.mkdir_p(File.dirname(dst)) if !File.exists?(File.dirname(dst))
    begin
      g.write(dst)
    rescue NoMethodError # necesario para que Gruff no genere error 500 al intentar pintar gráficas de facciones con 0 miembros
      raise ActiveRecord::RecordNotFound
    end
    
    raise 'foo' unless File.exists? dst
    
    if request.respond_to?(:user_agent) and /MSIE/ =~ request.user_agent
      send_file(dst, :type => 'image/png', :streaming => true, :disposition => 'inline')
    else
      redirect_to request.path
    end
  end
end
