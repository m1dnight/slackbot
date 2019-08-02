r = %{
  event_ts: "1564739459.037600",
  item: %{channel: "C04K740NY", ts: "1564739285.036900", type: "message"},
  item_user: "U04K740G0",
  reaction: "heart",
  ts: "1564739459.037600",
  type: "reaction_added",
  user: "U04K740G0"
}

t = Application.get_env(:slackbot, :secrets)[:slacktoken]
