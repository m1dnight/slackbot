defmodule Scheduler.DishwasherScheduler do
  @moduledoc false

  use Cronex.Scheduler

  require Logger

  every :monday, at: "07:00" do
    Brain.DishwasherManager.set_manager_of_the_week()
  end

  every :monday, at: "08:00" do
    msg = "Good morning! Enjoy your week as dishwasher manager and don't forget your duties."
    send_notification(msg)
  end

  every :wednesday, at: "09:00" do
    msg = "Good morning! Don't forget your dishwasher duties."
    send_notification(msg)
  end

  every :wednesday, at: "17:00" do
    msg = "Hey Dishwasher Manager! I hope you did your duties today :slightly_smiling_face:"
    send_notification(msg)
  end

  every :friday, at: "09:00" do
    msg = "Good morning! Don't forget your dishwasher duties."
    send_notification(msg)
  end

  every :friday, at: "17:00" do
    msg = """
          Hi Dishwasher Manager! We hope you did all your dishwasher duties this week :stuck_out_tongue_winking_eye:
          Have a nice weekend!
          """
    send_notification(msg)
  end

  every :thursday, at: "14:00" do
    msg = """
          Hello! Next week you will be our Dishwasher Managger :tada:
          If you will be out next week please change your turn with another person using the `swap_with` command.
          e.g. `swap_with @cdetroye`
          """
    {:ok, manager} = Brain.DishwasherManager.get_next_manager()
    SlackManager.send_private_message(msg, manager)
  end

  defp send_notification(msg) do
    {:ok, manager} = Brain.DishwasherManager.manager?()
    SlackManager.send_private_message(msg, manager)
  end


end
