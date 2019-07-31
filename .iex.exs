import Slackbot.Parser
import Slackbot.ConnectionHandler
t = Application.get_env(:slackbot, :secrets)[:slacktoken]
ts = "1564660689.006700"
c = "C04K740PA"

# Slackbot.Parser.channel_readable_to_hash("random", t)
# Slackbot.Parser.channel_readable_to_hash("random", t)

# react_to(%Slackbot.Message{id: ts, channel: "#random"}, "sunglasses")
