module SyntaxesHelper
  def link_to_syntax(syntax)
    label = h(ls_(syntax))
    label << "{#{syntax.length}}" if syntax.length
    link_to(label,
            :controller => "syntaxes",
            :action => "show",
            :id => syntax)
  end
end
