{
  models: [
    .models[]
    | select(.slug == "gpt-6-astra" or .slug == "gpt-6.1-sol")
  ]
}
