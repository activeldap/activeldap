module AttributesHelper
  include SyntaxesHelper

  def attribute_url_for_options(attribute)
    {
      :controller => "attributes",
      :action => "show",
      :id => attribute
    }
  end

  def link_to_attribute(attribute)
    link_to(h(la_(attribute)), attribute_url_for_options(attribute))
  end
end
