{
  models: [
    .models[]
    | select(.slug == "gpt-6-astra" or .slug == "gpt-6.1-sol")
    | .default_reasoning_level = (
        if .slug == "gpt-6-astra" then "high" else "xhigh" end
      )
  ]
}
