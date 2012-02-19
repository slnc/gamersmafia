# module ActionController
#class TestRequest < Request
# attr_accessor :user_agent
#end
#end


module ActionControllerMixings
  def self.included(base)
    base.class_eval do
      before_filter :init_xab
      include ActionControllerMixings::InstanceMethods
      attr_accessor :_xad
      attr_accessor :smodel_id
    end
  end
    
  module InstanceMethods
    def init_xab
      params['_xab'] = {} unless params['_xab']
      params['_xab'] = ActiveSupport::JSON.decode(CGI::unescape(params['_xab'])) if params['_xab'].kind_of?(String)
      params['_xab_new_treated_visitors'] = {}
      
      self._xad = [] unless self._xad
      self._xad = params[:_xad] if params[:_xad]
      self._xad = ActiveSupport::JSON.decode(CGI::unescape(self._xad)) if self._xad.kind_of?(String)
      
      self.smodel_id = params[:id] if self.smodel_id.nil? && params[:id]
    end
  end
end

