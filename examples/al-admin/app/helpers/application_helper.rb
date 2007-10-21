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
end
