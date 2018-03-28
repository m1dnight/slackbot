# TODO

A message that's edited does get through, so we need to add another type to that.
An edited message looks like this:


```
    {:event,
     %{
       channel: "D3PL9E24E",
       event_ts: "1522268590.000239",
       hidden: true,
       message: %{
         edited: %{ts: "1522268590.000000", user: "U04K740G0"},
         text: "emoji foo",
         ts: "1522268587.000224",
         type: "message",
         user: "U04K740G0"
       },
       previous_message: %{
         text: "emoji bar",
         ts: "1522268587.000224",
         type: "message",
         user: "U04K740G0"
       },
       subtype: "message_changed",
       ts: "1522268590.000239",
       type: "message"
     }}
```