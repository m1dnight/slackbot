defmodule Brain.DishwasherManager do
  require Logger
  use GenServer

  @users_file "data/dishwasher_manager/users.dat"
  @users_map_file "data/dishwasher_manager/users-map.dat"
  @schedule_file "data/dishwasher_manager/schedule.dat"
  @holidays [~D[2017-12-25], ~D[2018-01-01] ]

  def start_link(initial_state \\ []) do
    GenServer.start_link __MODULE__, [initial_state], name: __MODULE__
  end

  def init([[]]) do
    Logger.debug "No state provided. Reading from disk."
    case restore_state() do
      {:ok, state} ->
        {:ok, state}
      _ ->
        Logger.warn "No initial state was restored from backup."
        {:ok, {%{}, %{}, %{}, :no_specified}}
    end
  end

  def init([state]) do
    {:ok, state}

  end

  #############
  # Interface #
  #############

  def swap_duties(userA, userB) do
    GenServer.call __MODULE__, {:swap, userA, userB}
  end

  def manager?() do
    GenServer.call __MODULE__, :manager?
  end

  def next_manager do
    GenServer.call __MODULE__, :next_manager
  end

  def when?(user) do
    GenServer.call __MODULE__, {:when?, user}
  end

  def schedule() do
    GenServer.call __MODULE__, :schedule
  end

  def create_schedule(startDate) do
    GenServer.call __MODULE__, {:create_schedule, startDate}
  end

  def users() do
    GenServer.call __MODULE__, :users
  end

  def add_user(user, fullname) do
    GenServer.call __MODULE__, {:add_user, user, fullname}
  end

  def remove_user(user) do
    GenServer.call __MODULE__, {:remove_user, user}
  end

  def set_manager_of_the_week() do
    GenServer.call __MODULE__, :set_manager_of_the_week
  end

  def remove_users() do
    GenServer.call __MODULE__, :remove_users
  end

  def remove_schedule() do
    GenServer.call __MODULE__, :remove_schedule
  end


  #########
  # Calls #
  #########

  def handle_call(:users, _from, {_, users, _, _,_} = state) do
    {:reply, {:ok, users}, state}
  end

  def handle_call(:manager?, _from, {_, users, idNameMap, _, manager} = state) do
    fullName = Keyword.get(users, manager, :no_specified)
    user = Map.get(idNameMap, Atom.to_string(manager))
    {:reply, {:ok, user, fullName}, state}
  end

  def handle_call(:next_manager, _from, {schedule, users, idNameMap, _, _} = state) do
    manager =
      case get_next_manager(schedule) do
        :no_specified -> {user, _} = List.first users
                          user
                 user -> user
      end
    {:reply, {:ok, Map.get(idNameMap, Atom.to_string(manager))}, state}
  end

  def handle_call({:when?, user}, _from, {schedule, _, _, nameIdMap, _} = state) do
    userId = Map.get(nameIdMap, user) |> String.to_atom
    {fullName, startDate} = Keyword.get(schedule, userId, {:invalid_user, :no_specified})
    {:reply, {:ok, fullName, startDate}, state}
  end


  def handle_call(:set_manager_of_the_week, _from, {schedule, users, idNameMap, nameIdMap, _} ) do
    {schedule, manager} =
      case get_manager_of_week(schedule) do
        :no_specified -> sch = build_schedule(users, Date.utc_today)
                         man = get_manager_of_week(sch)
                         {sch, man}
                 user -> {schedule, user}
    end

    fullName = Keyword.get(users, manager, :no_specified)
    {:reply, {:ok, fullName}, {schedule, users, idNameMap, nameIdMap, manager}}
  end

  def handle_call(:schedule, _from, {schedule, _,_,_,_} = state) do
    {:reply, {:ok, schedule}, state}
  end

  def handle_call({:create_schedule, startDate}, _from, {_, users, idNameMap, nameIdMap, _}) do

    {:ok, startDate} = startDate
                       |> String.trim()
                       |> Date.from_iso8601()

    schedule = build_schedule(users, startDate)
    save_state(schedule, @schedule_file)
    manager = get_manager_of_week(schedule)
    {:reply, {:ok, schedule}, {schedule, users, idNameMap, nameIdMap, manager}}
  end

  def handle_call({:add_user, user, fullname}, _from,  {schedule, users, idNameMap, nameIdMap, manager}) do
    fullname = buildFullName(fullname)
    user = user
           |> String.trim()
          #  |> String.to_atom()

    userId = Map.get(nameIdMap, user)
    users = Keyword.put_new(users, userId, fullname)
    schedule = add_to_schedule(schedule, userId, fullname)
    save_state(schedule, @schedule_file)
    save_state(users, @users_file)
    {:reply, :ok, {schedule, users, idNameMap, nameIdMap, manager}}
  end


  def handle_call({:remove_user, user}, _from, {schedule, users, idNameMap, nameIdMap, manager}) do
    user = user
           |> String.trim()
          #  |> String.to_atom()

    userId = Map.get(nameIdMap, user)
    userList = Keyword.delete(users, userId)
    save_state(userList, @users_file)

    {:reply, :ok, {schedule, userList, idNameMap, nameIdMap, manager}}
  end

  def handle_call({:swap, _userA, _userB}, _from, {[], _, _, _, _} = state) do
    {:reply, {:error, "There is no schedule ready. Use the command 'help' for more information."}, state}
  end

  def handle_call({:swap, userA, userB}, _from, {schedule, users, idNameMap, nameIdMap, manager}) do
    userA = userA
           |> String.trim()
          #  |> String.to_atom()

    userB = userB
            |> String.trim()
            # |> String.to_atom()

    userIdA = Map.get(nameIdMap, userA) |> String.to_atom
    userIdB = Map.get(nameIdMap, userB) |> String.to_atom

    case validate_user_ids([userIdA, userIdB], users) do
      true ->
              {nameA, dateA} = Keyword.get(schedule, userIdA)
              {nameB, dateB} = Keyword.get(schedule, userIdB)

              newSchedule = schedule
                |> Keyword.replace!(userIdA, {nameA, dateB})
                |> Keyword.replace!(userIdB, {nameB, dateA})

              save_state(newSchedule, @schedule_file)
              manager = get_manager_of_week(newSchedule)
              {:reply, :ok, {newSchedule, users, idNameMap, nameIdMap, manager}}

      msg -> {:reply, {:error, msg}, {schedule, users, idNameMap, nameIdMap, manager}}

    end
  end

  def handle_call(:remove_users, _from, {_, _, idNameMap, nameIdMap, _}) do
    save_state([], @users_file)
    save_state([], @schedule_file)
    {:reply, :ok, {[], [], idNameMap, :no_specified}}
  end

  def handle_call(:remove_schedule, _from, {_, users, idNameMap,nameIdMap, _}) do
    save_state([], @schedule_file)
    {:reply, :ok, {[], users, idNameMap,nameIdMap, :no_specified}}
  end


  ###########
  # Private #
  ###########

  defp save_state(data, file) do
    content = :io_lib.format("~tp.~n", [data])
    :ok     = :file.write_file(file, content)
  end

  defp restore_state() do
    usersData = :file.consult(@users_file)
    scheduleData = :file.consult(@schedule_file)

    users = case usersData do
        {:ok, [values]} -> values
      _               -> []
    end

    schedule = case scheduleData do
      {:ok, [values]} -> values
      _               -> []
    end

    manager = get_manager_of_week(schedule)

    members = Slack.Web.Users.list(%{token: "xoxb-236968418545-LS34wziPDCf07sha2bkzhbe3"})
    idNameMap = members
               |> Map.get("members")
               |> Enum.map(fn(member) ->
                 {member["id"], member["name"]}
               end)

    nameIdMap = members
               |> Map.get("members")
               |> Enum.map(fn(member) ->
                {member["name"], member["id"]}
               end)


    {:ok, {schedule, users, Map.new(idNameMap), Map.new(nameIdMap), manager}}
  end

  defp buildFullName(fullName, acc \\ "")
  defp buildFullName([], acc) do
    String.trim(acc)
  end
  defp buildFullName([h|rest], acc) do
    acc = acc <> " " <> h
    buildFullName rest, acc
  end

  defp add_to_schedule([] = schedule, _user, _fullName), do: schedule

  defp add_to_schedule(schedule, user, fullName) do
    {_, {_, lastDate}} = Enum.max_by(schedule, fn({_, {_, date}}) -> date end)
    Keyword.put(schedule, user, {fullName, get_next_valid_date(Date.add(lastDate, 7))})
  end

  defp  validate_user_ids([], _users), do: true
  defp  validate_user_ids([user| rest], users) do
    case Keyword.has_key?(users, user) do
       false -> "Invalid user id! The user #{user} is not a registered."
       _     -> validate_user_ids(rest, users)
    end
  end

  defp build_schedule(list, startDate, schedule \\ [])
  defp build_schedule([], _startDate, schedule), do:  Enum.reverse(schedule)

  defp build_schedule([{k, v} | rest], startDate, schedule) do
    startDate = get_next_valid_date(startDate)
    schedule = Keyword.put_new(schedule, k, {v, startDate})
    nextDate = get_next_valid_date(Date.add(startDate, 7))
    build_schedule(rest,nextDate, schedule )
  end

  defp get_next_valid_date(date) do
    holiday? = Enum.find(@holidays, fn(x) -> Date.compare(date, x) == :eq end)
    case holiday? do
       nil -> get_start_date(date)
       _   -> get_next_valid_date(Date.add(date, 7))
    end
  end

  defp get_manager_of_week([]), do: :no_specified
  defp get_manager_of_week(schedule) do
    startDate = get_start_date()
    result = Enum.find(schedule, fn({_, {_, date}}) -> Date.compare(startDate, date) == :eq end)
    case result do
      nil      -> :no_specified
      {user,_} -> user
    end

  end

  defp get_next_manager([]), do: :no_specified
  defp get_next_manager(schedule) do
    startDate = Date.add(get_start_date(), 7)
    result = Enum.find(schedule, fn({_, {_, date}}) -> Date.compare(startDate, date) == :eq end)
    case result do
      nil      -> :no_specified
      {user,_} -> user
    end
  end

  defp get_start_date( date \\ Date.utc_today) do
    case Date.day_of_week(date) do
       1     -> date
       value -> Date.add(date, -(value-1))
    end
  end

end
