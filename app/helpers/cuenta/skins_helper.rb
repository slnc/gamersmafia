module Cuenta::SkinsHelper

  def css_background_edit(name, options={})
    controller.send(:render_to_string, :partial => '/cuenta/skins/css_background_edit', :locals => { :base => name, :options => options })
  end

  def css_editor_separator
    <<-END
    <tr>
      <td colspan="2"><hr /></td>
    </tr>
    END
  end
end
