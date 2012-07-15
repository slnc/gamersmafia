# -*- encoding : utf-8 -*-
# Author: http://www.semintelligent.com/blog/articles/29/freezing-ruby-data-structures-recursively
class Object
 # Define a deep_freeze method in Object (based on code posted by flavorrific
 # http://flavoriffic.blogspot.com/2008/08/freezing-deep-ruby-data-structures.html)
 # that will call freeze on the top-level object instance the method is
 # called on in as well as any child object instances contained in the
 # parent. This patch will also raise an IndexError if keys from
 # ‘deeply frozen’ Hashes or Arrays are accessed that do not exist.

def deep_freeze
  #  String doesn’t support each
  if (self.class != String) && (self.respond_to? :each)
    each { |v|
      v.deep_freeze if v.respond_to?(:deep_freeze)
    }
  end

  #  Deep freeze instance variable values
  if self.kind_of? Object
    self.instance_variables.each { |v|
      iv = self.instance_variable_get(v)
      iv.deep_freeze
      self.instance_variable_set(v, iv)
    }
  end

  if self.kind_of? Hash
    instance_eval <<EOF
      def default(key)
        raise IndexError, "Frozen hash: key '\#{key}' does not exist!"
      end
EOF
  end

  #  Prevent user from accessing array elements that do not exist.
  if self.kind_of? Array
    instance_eval <<EOF

      def at(index)
          self.fetch(index)
      end

      def [](arg1, arg2 = nil)

        results = Array.new

        if ! arg2.nil?
          #  Start index and end index given
          arg1.upto(arg1 + arg2) { |index|
            results << self.fetch(index)
          }
        else
          if arg1.kind_of? Range
            #  Range passed in
            arg1.each { |index|
              results << self.fetch(index)
            }
          else
            results << self.fetch(arg1)
          end

        end
        results
      end
EOF
    end

    freeze
  end
end
