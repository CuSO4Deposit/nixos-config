def deepseek($slug; $name; $desc; $priority; $modalities):
  (.models[] | select(.slug == "gpt-6.1-sol"))
  | .slug = $slug
  | .display_name = $name
  | .description = $desc
  | .default_reasoning_level = "high"
  | .supported_reasoning_levels = [
      { effort: "low", description: "Fast responses with lighter reasoning" },
      { effort: "high", description: "Greater reasoning depth" },
      { effort: "max", description: "Maximum reasoning depth" }
    ]
  | .priority = $priority
  | .input_modalities = $modalities
  | .context_window = 1048576
  | .max_context_window = 1048576
  | .supports_search_tool = false
  | .supports_image_detail_original = ($modalities | index("image") != null)
  | .comp_hash = null
  | .upgrade = null
  | .availability_nux = null
  | .model_specialty = null
  | .auto_review_model_override = null
  | .additional_speed_tiers = []
  | .service_tiers = []
  | .default_service_tier = null
  | .available_access_programs = null
  | del(.effective_context_window_percent);

{
  models: [
    deepseek(
      "deepseek-flash";
      "DeepSeek V4.1 Flash";
      "Fast long-context model for coding and everyday work.";
      1;
      ["text", "image"]
    )
  ]
}
