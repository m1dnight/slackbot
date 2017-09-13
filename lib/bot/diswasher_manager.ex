defmodule Bot.DiswasherManager do
  require Logger
  use Plugin

  @boss    Application.fetch_env!(:slack, :diswasher_duties_owner)
  @channel Application.fetch_env!(:slack, :diswasher_duties_channel)

  # The message "swap_with @x" is used to swap weekly duties with the user  `x`.
  def on_message(<<"swap_with"::utf8, user::bitstring>>, _channel, sender)  do
    user = String.trim(user)
    case Brain.DishwasherManager.swap_duties(sender, user) do
       :ok -> SlackManager.send_private_message("You swapped your dishwasher duties with @#{sender}.", user)
              {:ok, "Duties swapped!"}
       {:error, msg} -> {:ok, msg}
    end
  end

  # The message "manager?" return the name uf the current dishwasher manager
  def on_message(<<"manager?"::utf8>>, _channel, _sender) do
    {:ok, manager, fullname} = Brain.DishwasherManager.manager?()

    case manager do
       :no_specified -> {:ok, "The schedule has not been created. Use the command 'help' for more information."}
       name          -> {:ok, "The current dishwasher manager is `#{fullname}`"}
    end
  end

  def on_message(<<"when?"::utf8>>, _channel, sender) do
    {:ok, fullname, startDate} = Brain.DishwasherManager.when?(sender)

    case fullname do
      :invalid_user -> {:ok, "The schedule has not been created. Use the command 'help' for more information."}

                  _ -> from = Date.to_string(startDate)
                       to = startDate |> Date.add(4) |> Date.to_string()
                       {:ok, "Your next dishwasher duties will be from `#{from}` to `#{to}`"}
    end
  end

  # Prints out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"schedule"::utf8, _::bitstring>>, _channel, _sender) do
    {:ok, schedule} = Brain.DishwasherManager.schedule()
    build_schedule_list(schedule)
  end

  # Prints out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"create_schedule"::utf8, startDate::bitstring>>, _channel, @boss) do
    {:ok, schedule} = Brain.DishwasherManager.create_schedule(startDate)
    build_schedule_list(schedule)
  end

  def on_message(<<"users"::utf8, _::bitstring>>, _channel, @boss) do
    {:ok, users} = Brain.DishwasherManager.users()
    build_user_list(users)
  end

  def on_message(<<"add_user"::utf8, userDetails::bitstring>>, _channel, @boss) do
     case String.split(userDetails) do
      []          -> {:noreply}
      [user| fullname] -> :ok  = Brain.DishwasherManager.add_user(user, fullname)
                          {:ok, "The user {#{user}, #{fullname}} has been saved."}
    end
  end

  def on_message(<<"remove_user"::utf8, user::bitstring>>, _channel, @boss) do
    :ok  = Brain.DishwasherManager.remove_user(user)
    {:ok, "The user #{user} has been removed."}
  end

  def on_message(<<"remove_users"::utf8>>, _channel, @boss) do
    :ok  = Brain.DishwasherManager.remove_users()
    {:ok, "The user list was removed."}
  end

  def on_message(<<"remove_schedule"::utf8>>, _channel, @boss) do
    :ok  = Brain.DishwasherManager.remove_schedule()
    {:ok, "The schedule was removed."}
  end

  def on_message(<<"set_manager"::utf8>>, _channel, @boss) do
    {:ok, manager}  = Brain.DishwasherManager.set_manager_of_the_week()
    case manager do
      :no_specified -> {:ok, "The schedule has not been created. Use the command 'help' for more information."}
      name          -> {:ok, "The current dishwasher manager is `#{name}`"}
    end
  end

  def on_message(<<"wave"::utf8>>, :dishwasher_app, _sender) do
    wave_dishwasher_manager()
  end

  def on_message(<<"wave"::utf8>>, :channel, _sender) do
    wave_dishwasher_manager()
  end

  def on_message(<<":wave:"::utf8>>, :dishwasher_app, _sender) do
    wave_dishwasher_manager()
  end


  def on_message(<<":wave:"::utf8>>, :channel, _sender) do
    wave_dishwasher_manager()
  end

  defp wave_dishwasher_manager do
    {:ok, manager, fullname} = Brain.DishwasherManager.manager?()

    case manager do
      :no_specified -> {:ok, "As the schedule has not been created, there is not Dishwasher Manager."}
      name          -> SlackManager.send_private_message(":wave: Hey Dishwasher Manager! Please do your dishwasher duties as soon as you can.", manager)
                       {:ok, "The current dishwasher manager `#{fullname}` was :wave:"}
    end
  end

  # Prints out help message.
  def on_message(<<"help"::utf8>>, @channel, @boss) do
    res = boss_help_menu()
    {:ok, res}
  end

  # Prints out help message.
  def on_message(<<"help"::utf8>>, @channel, _sender) do
    res = user_help_menu()
    {:ok, res}
  end

  # Prints out help message.
  def on_message(<<"help"::utf8>>, :dishwasher_app, @boss) do
    res = boss_help_menu()
    {:ok, res}
  end

  def on_message(<<"help"::utf8>>, :dishwasher_app, _sender) do
    res = user_help_menu()
    {:ok, res}
  end


#  def on_message(_text, @channel, _sender) do
#     {:ok, general_msg()}
#  end
#
#  def on_message(_text, :dishwasher_app, _sender) do
#     {:ok, general_msg()}
#  end

  def on_message(_text, _channel, _sender) do
    {:noreply}
  end


#  defp general_msg do
#    """
#    Hello Softie! Please use the command `help` for more information.
#    """
#  end

  defp build_schedule_list(schedule) when schedule == %{}  , do: {:ok, "There is no schedule ready. Use the command 'help' for more information."}

  defp build_schedule_list(schedule) do
    resp = schedule
           |> Enum.map(fn {_k,{fullname, from}} ->
                "- #{fullname} -> from: #{from} to: #{Date.add(from, 4)}" end)
           |> Enum.join("\n")

    {:ok, "```#{resp}```"}
  end

  defp build_user_list(users)  when users == %{} , do: {:ok, "The list of user is empty. Use the command 'help' for more information."}

  defp build_user_list(users) do
    resp = users
           |> Enum.map(fn {user, fullname} -> "- #{fullname} (@#{user})" end)
           |> Enum.join("\n")

    {:ok, "```#{resp}```"}
  end

  defp user_help_menu do
    """
    ```
    swap_with           : Swaps weekly duties with another person.
                          Example: "swap_with @cdtroye".
    manager?            : Shows the current dishwasher manager.
                          Example: "manager?"
    schedule            : Shows the current dishwasher schedule.
                          Example: "schedule"
    wave                : Sends a notification to the current diswasher manager.
                          Example: "wave"  or  ":wave:"
    when?               : Shows the dates of your the next diswasher duties.
                          Example: "when? "
    ```

    """
  end

  defp boss_help_menu do
    """
    ```
    swap_with           : Swaps weekly duties with another person.
                          Example: "swap_with @cdtroye".
    manager?            : Shows the current dishwasher manager.
                          Example: "manager?"
    schedule            : Shows the current dishwasher schedule.
                          Example: "schedule"
    create_schedule     : Creates a dishwasher schedule starting from the date specified.
                          Example: "create_schedule 2017-09-07"
    users               : Shows the current list of users.
                          Example: "users"
    add_user            : Add a new user. The first argument is the "slack user name",
                          followed by its fullname.
                          Example: "add_user @humberto Humberto Rodriguez Avila"
    remove_user         : Remove an user.
                          Example: "remove_user @humberto"
    set_manager         : Set the manager for the current week.
                          Example: "set_manager"
    ```

    """
  end


end
