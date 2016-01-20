defmodule Zerotier.NetworkMemberView do
  use Zerotier.Web, :view
  use Timex

  def epoch_timestamp_to_string(milliseconds) do
    milliseconds
    |> Date.from(:msecs)
    |> Date.local
    |> DateFormat.format("{YYYY}-{0M}-{0D} {h12}:{m}:{s} {AM}")
    |> elem(1)
  end

  @doc """
  Implementation of inputs_for for simple array schema-fields.

  ## Usage
  <%= inputs_for_list f, :ipLocalRoutes, fn i -> %>
    <%= text_input i, :nil, id: i.id, name: i.name %>
  <% end %>

  See: https://github.com/phoenixframework/phoenix_html/blob/master/lib/phoenix_html/form.ex
  """
  def inputs_for_list(form, field, options \\ [], fun) do
    forms = list_to_form(form.source, form, field, options)
    html_escape Enum.map(forms, fn form ->
      hidden = Enum.map(form.hidden, fn {k, v} -> hidden_input(form, k, value: v) end)
      [hidden, fun.(form)]
    end)
  end

  #defimpl Phoenix.HTML.FormData, for: Ecto.Changeset do
  @doc """
  Implementation of to_form for simple array schema-fields

  See: https://github.com/phoenixframework/phoenix_html/blob/master/lib/phoenix_html/form_data.ex
  """
  def list_to_form(source = %Ecto.Changeset{}, form, field, opts) do
    {default, opts} = Keyword.pop(opts, :default, [])
    {prepend, opts} = Keyword.pop(opts, :prepend, [])
    {append, opts}  = Keyword.pop(opts, :append, [])
    {name, opts}    = Keyword.pop(opts, :as)
    {id, opts}      = Keyword.pop(opts, :id)

    id     = to_string(id || form.id <> "_#{field}")
    name   = to_string(name || form.name <> "[#{field}]")
    params = Map.get(form.params, Atom.to_string(field), nil)
    value_list = Ecto.Changeset.get_field(source, field, prepend ++ default ++ append)

    case params do
      params = %{} ->
        model = for {element, index} <- Enum.with_index(value_list), into: %{}, do: { index, element }
        for { {_key, value }, index} <- Enum.with_index(params) do
          index_string = Integer.to_string(index)
          %Phoenix.HTML.Form{
            source: source,
            impl: __MODULE__,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[" <> index_string <> "]",
            model: %{ nil: Map.get(model, index, nil)},
            params: %{ "nil" => value },
            options: opts}
        end

      params when is_list(params) ->
        model = for {element, index} <- Enum.with_index(value_list), into: %{}, do: { index, element }
        for {value, index} <- Enum.with_index(params) do
          index_string = Integer.to_string(index)
          %Phoenix.HTML.Form{
            source: source,
            impl: __MODULE__,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[]",
            model: %{ nil: Map.get(model, index, nil)},
            params: %{ "nil" => value },
            options: opts}
        end

      _params = nil ->
        for {value, index} <- Enum.with_index(value_list) do
          index_string = Integer.to_string(index)
          %Phoenix.HTML.Form{
            source: source,
            impl: __MODULE__,
            index: index,
            id: id <> "_" <> index_string,
            name: name <> "[]",
            model: %{nil: value},
            params: %{},
            options: opts}
        end
    end

  end

end
