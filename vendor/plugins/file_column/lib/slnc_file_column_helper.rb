module SlncFileColumnHelper
  def fc_thumbnail(im_path, mode, dim, link_original=true, title='')
    if im_path.to_s.strip != '' then
      im_path = '/' << im_path unless im_path =~ /^\//
      # TODO añadir parsing de dim si mode == f
      if mode == 'f' then
        style = 'style="width: ' << dim.split('x')[0] << 'px; height: ' << dim.split('x')[1] << 'px;"'
      else
        style = ''
      end
      html_out = '<img ' << style << ' src="/cache/thumbnails/' << mode << '/' << dim << im_path << '" />'

      if link_original
        '<a ' << 'title="' << tohtmlattribute(title) << '" href="' << im_path << '">' << html_out << '</a>'
      else
        html_out
      end
    else
      ''
    end
  end

  def fc_image(im_path, alt='')
    if im_path.to_s.strip != '' then
      im_path = '/' << im_path unless im_path =~ /^\//
      '<img alt="' << tohtmlattribute(alt) << '" src="' << im_path << '" />'
    else
      ''
    end
  end

  def fc_path(file_path)
    ((file_path =~ /^\//) ? file_path : '/' << file_path) unless file_path.nil?
  end
end
