module ObjectClassesHelper
  include AttributesHelper

  def link_to_object_class(object_class)
    link_to(h(loc_(object_class)),
            :controller => "object_classes",
            :action => "show",
            :id => object_class)
  end
end
