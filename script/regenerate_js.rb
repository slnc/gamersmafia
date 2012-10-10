#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# Este script está pensado para ejecutarse desde Rails.root.
# TODO: convertir a una rake task

def compress_js
  # TODO(slnc): eliminar los archivos de syntaxhighlighter, apenas se están
  # usando.
  js_libraries = %w(
      web.shared/jquery-1.7.1
      web.shared/jquery.scrollTo-1.4.0
      jquery-ui-1.7.2.custom
      jquery_ujs
      jquery.facebox
      jquery.elastic.source
      web.shared/jgcharts-0.9
      web.shared/slnc
      app
      tracking
      app.bbeditor
      colorpicker
      syntaxhighlighter/shCore
      syntaxhighlighter/shBrushPhp
      syntaxhighlighter/shBrushPython
  )

  dst = 'public/gm.js'
  f = open(dst, 'w')
  js_libraries.each do |library|
    f.write(open("public/javascripts/#{library}.js").read)
  end
  f.close

  `java -jar script/yuicompressor-2.4.2.jar #{dst} -o #{dst} --line-break 500`
end

def app_update
  `rake gm:after_deploy`
end

compress_js
app_update
