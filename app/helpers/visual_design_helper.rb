# frozen_string_literal: true

module VisualDesignHelper
  def render_affiliate_visual_design_value(visual_design_json, property)
    if visual_design_json.present? && visual_design_json[property.to_s]
      visual_design_json[property.to_s]
    else
      Affiliate::DEFAULT_VISUAL_DESIGN[property]
    end
  end

  def render_logo_alt_text(logo_metadata)
    if logo_metadata.present? && logo_metadata.key?('alt_text')
      logo_metadata['alt_text']
    else
      t('sites.visual_designs.image_assets.logo', scope: 'admin_center')
    end
  end
end