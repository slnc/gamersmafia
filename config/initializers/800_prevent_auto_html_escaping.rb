# TODO(slnc): rails3 this doesn't look pretty, search for a better solution
class Object
  def html_safe?
    true
  end
end

 class String
  def html_safe?
    true
  end
end
