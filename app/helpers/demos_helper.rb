# -*- encoding : utf-8 -*-
module DemosHelper
  def demo_participant(participant)
    if participant.kind_of?(String)
      participant
    else
      "<a href=\"#{gmurl(participant)}\">#{participant.to_s}</a>"
    end
  end

  def demo_event(event)
    "<a href=\"#{gmurl(event)}\">#{event.title}</a>" if event
  end

  def demo_pov_type(pov_type)
    Demo::POVS.index(pov_type)
  end

  def demo_demotype(demotype)
    Demo::DEMOTYPES.index(demotype)
  end

  def demo_download_link(demo)
    if demo.file
      ("<a href=\"/demos/download/#{demo.id}\"><img class=\"icon\""+
       " src=\"/skins/default/images/btn_descargar.png\" /></a>")
    end
  end
end
