# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include UrlHelper

  def flash_box(message)
    id = "flash-box"
    fade_out = Proc.new {|page| page.visual_effect(:fade, id)}
    flash_box_div = content_tag("div", "\n#{message}\n",
                                :id => id,
                                :onclick => update_page(&fade_out))
    set_opacity = update_page {|page| page[id].setOpacity("0.8")}
    effect = update_page do |page|
      page.delay(5) do
        fade_out.call(page)
      end
    end
    javascript_content = "#{set_opacity}\n#{effect}"
    "#{flash_box_div}\n#{javascript_tag(javascript_content)}"
  end

  def switcher(prefix, title, &proc)
    concat(render(:partial => "_switcher/before",
                  :locals => {:prefix => prefix, :title => title}),
           proc.binding)
    yield
    concat(render(:partial => "_switcher/after",
                  :locals => {:prefix => prefix}),
           proc.binding)
  end

  def switcher_element(prefix, options={})
    options[:open] = true unless options.has_key?(:open)
    switch_id = "#{prefix}-switch".to_json
    content_id = "#{prefix}-content".to_json
    options = options_for_javascript(options)
    javascript_tag("new Switcher(#{switch_id}, #{content_id}, #{options});")
  end

  def boolean_value(condition)
    condition ? "o" : "x"
  end
end
