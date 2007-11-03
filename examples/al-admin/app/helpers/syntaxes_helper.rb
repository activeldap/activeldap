module SyntaxesHelper
  def link_to_syntax(syntax)
    link_to(h(ls_(syntax)),
            :controller => "syntaxes",
            :action => "show",
            :id => syntax)
  end
end
