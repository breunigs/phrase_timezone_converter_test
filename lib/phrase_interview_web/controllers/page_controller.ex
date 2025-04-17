defmodule PhraseInterviewWeb.PageController do
  use PhraseInterviewWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def redirect_to_timezone(conn, _params) do
    redirect(conn, to: ~p"/timezone")
  end
end
