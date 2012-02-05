module AccountHelper

  # Taken from the webrick server
  module Utils
		RAND_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
		             "0123456789" +
		             "abcdefghijklmnopqrstuvwxyz"
    def random_string(len)
      rand_max = RAND_CHARS.size
      ret = ""
      len.times{ ret << RAND_CHARS[rand(rand_max)] }
      ret
    end
    module_function :random_string

  end

  # store current uri in the ccokies
  # we can return to this location by calling return_location
  def store_location
    cookies[:return_to] = {:value => request.fullpath, :expires => nil, :domain => COOKIEDOMAIN}
  end
end
