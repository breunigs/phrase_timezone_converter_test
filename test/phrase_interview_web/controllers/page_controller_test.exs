defmodule PhraseInterviewWeb.PageControllerTest do
  use PhraseInterviewWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert "/timezone" = redirected_to(conn, 302)
  end
end
