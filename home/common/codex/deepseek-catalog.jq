{
  models: [
    {
      slug: "deepseek-flash",
      display_name: "DeepSeek V4.1 Flash",
      description: "Fast long-context model for coding and everyday work.",
      default_reasoning_level: "high",
      supported_reasoning_levels: [
        { effort: "low", description: "Fast responses with lighter reasoning" },
        { effort: "high", description: "Greater reasoning depth" },
        { effort: "max", description: "Maximum reasoning depth" }
      ],
      shell_type: "shell_command",
      visibility: "list",
      supported_in_api: true,
      priority: 1,
      availability_nux: null,
      upgrade: null,
      prefer_websockets: false,
      support_verbosity: true,
      default_verbosity: "low",
      apply_patch_tool_type: "freeform",
      web_search_tool_type: "text",
      input_modalities: ["text", "image"],
      supports_image_detail_original: true,
      truncation_policy: { mode: "tokens", limit: 10000 },
      supports_parallel_tool_calls: true,
      tool_mode: null,
      multi_agent_version: "v2",
      use_responses_lite: false,
      include_skills_usage_instructions: false,
      auto_review_model_override: null,
      context_window: 1048576,
      max_context_window: 1048576,
      effective_context_window_percent: 95,
      auto_compact_token_limit: null,
      comp_hash: "3000",
      reasoning_summary_format: "experimental",
      default_reasoning_summary: "none",
      supports_reasoning_summaries: true,
      experimental_supported_tools: [],
      supports_search_tool: false,
      default_service_tier: null,
      model_messages: (.models[] | select(.slug == "gpt-6.1-sol") | .model_messages)
    }
  ]
}
