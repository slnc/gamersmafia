module Admin::MotorHelper
  def show_var(name, value)
    "<tr class=\"#{oddclass}\">
    <td style=\"width: 250px;\"><strong>#{name}</strong></td>
    <td>#{value}</td>
    </tr>"
  end

  def show_hash_var(name, hash)
    out = '<table>'
    hash.keys.sort.each { |k| out << "<tr class=\"#{oddclass}\"><td>#{k}</td><td class=\"w150\">#{hash[k]}</td></tr>" }
    show_var(name, out << '</table>')
  end
end
