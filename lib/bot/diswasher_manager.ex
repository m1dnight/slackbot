defmodule Bot.DiswasherManager do
  require Logger
  use Plugin

  @boss    Application.fetch_env!(:slack, :diswasher_duties_owner)
  @channel Application.fetch_env!(:slack, :diswasher_duties_channel)

  # The message "swap_with @x" is used to swap weekly duties with the user  `x`.
  def on_message(<<"swap_with"::utf8, user::bitstring>>, @channel, sender)  do
    case Brain.DishwasherManager.swap_duties(sender, user) do
       :ok -> {:ok, "Duties swapped!"}
       {:error, msg} -> {:ok, msg}
    end
  end

  # The message "who_is?" return the name uf the current dishwasher manager
  def on_message(<<"manager?"::utf8, _rest::bitstring>>, @channel, _sender) do
    Logger.debug "bot -> manager?"
    {:ok, manager} = Brain.DishwasherManager.manager?()

    case manager do
       :no_specified -> {:ok, "The schedule has not been created. Use the command 'help' for more information."}
       name          -> {:ok, "The current dishwasher manager is `#{name}`"}
    end
    

  end

  # Prints out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"schedule"::utf8, _::bitstring>>, @channel, _sender) do
    {:ok, schedule} = Brain.DishwasherManager.schedule()
    build_schedule_list(schedule)
  end

  # Prints out all the outstanding orders.
  # Restricted to admins only.
  def on_message(<<"create_schedule"::utf8, startDate::bitstring>>, @channel, @boss) do
    {:ok, schedule} = Brain.DishwasherManager.create_schedule(startDate)
    build_schedule_list(schedule)
  end

  def on_message(<<"users"::utf8, _::bitstring>>, @channel, _sender) do
    {:ok, users} = Brain.DishwasherManager.users()
    build_user_list(users)
  end

  def on_message(<<"add_user"::utf8, userDetails::bitstring>>, @channel, @boss) do
    case String.split(userDetails) do
      []          -> {:noreply}
      [user| fullname] -> :ok  = Brain.DishwasherManager.add_user(user, fullname)
                          {:ok, "The user {#{user}, #{fullname}} has been saved."}
    end
  end

  def on_message(<<"remove_user"::utf8, user::bitstring>>, @channel, @boss) do
    :ok  = Brain.DishwasherManager.remove_user(user)
    {:ok, "The user #{user} has been removed."}
  end

  # Prints out help message.
  def on_message(<<"help"::utf8>>, @channel, _sender) do
    res = """
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
    ```
    Ps: Only the admin can execute `create_schedule`, `add_user`, and `remove_user`

    """
    {:ok, res}
  end

  def on_message(_text, _hannel, _sender) do
    {:noreply}
  end

  defp build_schedule_list(%{}), do: {:ok, "There is no schedule ready. Use the command 'help' for more information."}

  defp build_schedule_list(schedule) do
    resp = schedule
           |> Enum.map(fn {_k,{fullname, date}} -> "- #{fullname} ->  #{date}-#{Date.add(date, 4)}" end)
           |> Enum.join("\n")

    {:ok, "```#{resp}```"}
  end

  defp build_user_list(%{}), do: {:ok, "The list of user is empty. Use the command 'help' for more information."}

  defp build_user_list(users) do
    resp = users
           |> Enum.map(fn {user, fullname} -> "- #{fullname} (#{user})" end)
           |> Enum.join("\n")

    {:ok, "```#{resp}```"}
  end


end
