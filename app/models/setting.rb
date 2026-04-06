class Setting < ApplicationRecord
  has_rich_text :room_rules

  CAMERA_TUNING_DEFAULTS = {
    minRatio: 0.30,
    maxRatio: 0.70,
    scoreThreshold: 0.50,
    goodScore: 0.60,
    minZoom: 1.12,
    maxZoom: 1.82,
    zoomWidthFactor: 1.02,
    zoomHeightFactor: 0.94,
    blurStrength: 3,
    blurSaturation: 1.00,
    focusInnerRadius: 67,
    focusOuterRadius: 92,
    autoCaptureEnabled: true,
    meshStyle: "biometric"
  }.freeze

  def self.instance
  first_or_create!
end

    def self.get(key)
  find_by(key: key)&.value
end


# app/models/setting.rb
after_commit :reload_schedulers, on: [:update]

  def require_room_rules_ack?
    require_room_rules_ack == true
  end
  
def reload_schedulers
  SchedulerManager.reload_all
end



  # Defaults elegantes (evita nils)
  def smtp_address_or_default
    smtp_address.presence || "smtp.gmail.com"
  end

  def smtp_port_or_default
    (smtp_port.presence || 587).to_i
  end

  def smtp_authentication_or_default
    (smtp_authentication.presence || "plain").to_sym
  end

  def smtp_enable_starttls_auto_or_default
    smtp_enable_starttls_auto.nil? ? true : smtp_enable_starttls_auto
  end

  def from_email_or_default
    smtp_from_email.presence || smtp_username.presence
  end

  def reply_to_or_default
    smtp_reply_to.presence
  end

  def camera_tuning_config
    CAMERA_TUNING_DEFAULTS.merge(
      minRatio: camera_min_ratio.presence || CAMERA_TUNING_DEFAULTS[:minRatio],
      maxRatio: camera_max_ratio.presence || CAMERA_TUNING_DEFAULTS[:maxRatio],
      scoreThreshold: camera_score_threshold.presence || CAMERA_TUNING_DEFAULTS[:scoreThreshold],
      goodScore: camera_good_score.presence || CAMERA_TUNING_DEFAULTS[:goodScore],
      minZoom: camera_min_zoom.presence || CAMERA_TUNING_DEFAULTS[:minZoom],
      maxZoom: camera_max_zoom.presence || CAMERA_TUNING_DEFAULTS[:maxZoom],
      zoomWidthFactor: camera_zoom_width_factor.presence || CAMERA_TUNING_DEFAULTS[:zoomWidthFactor],
      zoomHeightFactor: camera_zoom_height_factor.presence || CAMERA_TUNING_DEFAULTS[:zoomHeightFactor],
      blurStrength: camera_blur_strength.presence || CAMERA_TUNING_DEFAULTS[:blurStrength],
      blurSaturation: camera_blur_saturation.presence || CAMERA_TUNING_DEFAULTS[:blurSaturation],
      focusInnerRadius: camera_focus_inner_radius.presence || CAMERA_TUNING_DEFAULTS[:focusInnerRadius],
      focusOuterRadius: camera_focus_outer_radius.presence || CAMERA_TUNING_DEFAULTS[:focusOuterRadius],
      autoCaptureEnabled: camera_auto_capture_enabled.nil? ? CAMERA_TUNING_DEFAULTS[:autoCaptureEnabled] : camera_auto_capture_enabled,
      meshStyle: camera_mesh_style.presence || CAMERA_TUNING_DEFAULTS[:meshStyle]
    )
  end
end
