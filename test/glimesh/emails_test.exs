defmodule Glimesh.EmailsTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Emails

  describe "log_email/1" do
    test "logs emails successful and lists them" do
      user = user_fixture()

      Glimesh.Accounts.deliver_user_reset_password_instructions(
        user,
        fn _ -> "some-url" end
      )

      email_log = Emails.list_email_log(user)
      assert [%Glimesh.Emails.EmailLog{}] = email_log
    end
  end
end
