module AttributesHelper
  include SyntaxesHelper

  def link_to_attribute(attribute)
    link_to(h(la_(attribute)),
            :controller => "attributes",
            :action => "show",
            :id => attribute)
  end
end
