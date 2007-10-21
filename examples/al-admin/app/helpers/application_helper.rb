# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include UrlHelper

  def flash_box(message)
    id = "flash-box"
    fade_out = update_page {|page| page.visual_effect(:fade, id)}
    flash_box_div = content_tag("div", message,
                                :id => id,
                                :onclick => fade_out)
    set_opacity = update_page {|page| page[id].setOpacity("0.8")}
    effect = update_page do |page|
      page.delay(5) do
        page.visual_effect(:fade, fade_out)
      end
    end
    flash_box_div + javascript_tag(set_opacity + effect)
  end
end
