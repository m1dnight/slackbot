defmodule Brain.DishwasherManager do
  require Logger
  use GenServer

  @users_file "data/dishwasher_manager/users.dat"
  @schedule_file "data/dishwasher_manager/schedule.dat"

  def start_link(initial_state \\ []) do
    GenServer.start_link __MODULE__, [initial_state], name: __MODULE__
  end

  def init([[]]) do
    Logger.debug "No orders provided. Reading from disk."
    case restore_state() do
      {:ok, state} ->
        {:ok, state}
      _ ->
        Logger.warn "No initial orders and can't read backup, starting with empty order."
        {:ok, {%{}, %{}, :no_specified}}
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


  #########
  # Calls #
  #########

  def handle_call(:users, _from, {_, users, _} = state) do
    Logger.debug "brain -> users"
    {:reply, {:ok, users}, state}
  end

  def handle_call(:manager?, _from, {_, _, manager} = state) do
    Logger.debug "brain -> manager?"
    {:reply, {:ok, manager}, state}
  end

  def handle_call(:schedule, _from, {schedule, _,_} = state) do
    Logger.debug "brain -> schedule"
    {:reply, {:ok, schedule}, state}
  end

  def handle_call({:create_schedule, startDate}, _from, {_, users, }) do
    Logger.debug "brain -> create_schedule"
    usersList = Map.to_list users
    {_, manager} = List.first(usersList)
    schedule = build_schedule(usersList, startDate)
    {:reply, {:ok, schedule}, {schedule, users, manager}}
  end

  def handle_call({:add_user, user, fullname}, _from,  {schedule, users, manager}) do
    Logger.debug "brain -> add_user #{user}"
    fullname = buildFullName(fullname)
    users = Map.put_new(users, user, fullname)
    schedule = add_to_schedule(schedule, user, fullname)
    save_state(users, @users_file)
    {:reply, :ok, {schedule, users, manager}}
  end


  def handle_call({:remove_user, user}, _from, {schedule, users, manager}) do
    Logger.debug "brain -> remove_user #{user}"
    users = Map.delete(users, user)
    save_state(users, @users_file)
    {:reply, :ok, {schedule, users, manager}}
  end

  def handle_call({:swap, userA, userB}, _from, {schedule, users, manager}) do
    Logger.debug "brain -> swap order for duties of user #{userA} with #{userB}"

    case validate_user_names([userA, userB], users) do
      true ->
              {_, dateA} = Map.get(users, userA)
              {_, dateB} = Map.get(users, userB)

              schedule = schedule
                |> Map.replace!(userA, dateB)
                |> Map.replace!(userB, dateA)

              save_state(schedule, @schedule_file)
              {:reply, :ok, {schedule, users, manager}}

      msg -> {:reply, {:error, msg}, {schedule, users, manager}}

    end
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
      _               -> {:error}
      end

    schedule = case scheduleData do
      {:ok, [values]} -> values
      _               -> {:error}
    end

    {schedule, users}
  end

  defp buildFullName(fullName, acc \\ "")
  defp buildFullName([], acc) do
    String.trim(acc)
  end
  defp buildFullName([h|rest], acc) do
    acc = acc <> " " <> h
    buildFullName rest, acc
  end

  defp add_to_schedule(%{} = schedule, _user, _fullName) do
    schedule
  end

  defp add_to_schedule(schedule, user, fullName) do
    {_, {_, lastDate}} = schedule
                         |> Enum.to_list
                         |> List.last
    Map.put(schedule, user, {fullName, Date.add(lastDate, 7)})
  end

  defp  validate_user_names([user| rest], users) do
    case Map.has_key?(users, user) do
       false -> "Invalid username! The user #{user} is not a registered."
       _     -> validate_user_names(rest, users)
    end
  end

  defp build_schedule(list, startDate, schedule \\ %{})

  defp build_schedule([], _startDate, schedule), do: schedule

  defp build_schedule([{k, v} | rest], startDate, schedule) do
    schedule = Map.put(schedule, k, {v, startDate} )
    nextDate = Date.add(startDate, 7)
    build_schedule(rest,nextDate, schedule )
  end

end
