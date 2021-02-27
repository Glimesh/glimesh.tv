defmodule Glimesh.AccountsProfileTest do
  use Glimesh.DataCase
  use Bamboo.Test

  alias Glimesh.Accounts.Profile

  describe "normal safe user markdown" do
    test "allows normal markdown" do
      assert {:ok, "<p>\n<strong>bold</strong></p>\n"} ==
               Profile.safe_user_markdown_to_html("**bold**")
    end

    test "errors on weird markdown" do
      assert {:error, "Unexpected line </h2> on line 1"} ==
               Profile.safe_user_markdown_to_html("</h2>")
    end

    test "can use urls" do
      assert {:ok,
              "<p><a rel=\"ugc\" target=\"_blank\" href=\"https://google.com\">link</a></p>\n"} ==
               Profile.safe_user_markdown_to_html("[link](https://google.com)")
    end

    test "allows nil's when clearing out content" do
      assert {:ok, nil} ==
               Profile.safe_user_markdown_to_html(nil)
    end
  end

  describe "markdown xss injection" do
    @bad_links [
      {"<&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>",
       "&lt;&amp;#x6A&amp;#x61&amp;#x76&amp;#x61&amp;#x73&amp;#x63&amp;#x72&amp;#x69&amp;#x70&amp;#x74&amp;#x3A&amp;#x61&amp;#x6C&amp;#x65&amp;#x72&amp;#x74&amp;#x28&amp;#x27&amp;#x58&amp;#x53&amp;#x53&amp;#x27&amp;#x29&gt;"},
      {"[a](javascript://www.google.com%0Aprompt(1))", "<a>a</a>"},
      {"[test](javascript://%0d%0aprompt(1))", "<a>test</a>"},
      {"[clickme](vbscript:alert(document.domain))", "<a>clickme</a>"},
      {"_http://danlec_@.1 style=background-image:url(data:image/png;base64,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);background-repeat:no-repeat;display:block;width:100%;height:100px; onclick=alert(unescape(/Oh%20No!/.source));return(false);//",
       "<em><a rel=\"ugc\" target=\"_blank\" href=\"http://danlec\">http://danlec</a></em>@.1 style=background-image:url(data:image/png;base64,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);background-repeat:no-repeat;display:block;width:100%;height:100px; onclick=alert(unescape(/Oh%20No!/.source));return(false);//"},
      {"<http://<meta http-equiv=\"refresh\" content=\"0; url=http://danlec.com/\">>",
       "&lt;<a rel=\"ugc\" target=\"_blank\" href=\"http://%3Cmeta\">http://&lt;meta</a> http-equiv=”refresh” content=”0; url=<a rel=\"ugc\" target=\"_blank\" href=\"http://danlec.com/%22%3E%3E\">http://danlec.com/“&gt;&gt;</a>"},
      {"[a](javascript:alert(document.domain&#41;)",
       "[a](javascript:alert(document.domain&amp;#41;)"},
      {"[a](Javas&#99;ript:alert(1&#41;)", "[a](Javas&amp;#99;ript:alert(1&amp;#41;)"},
      {"[a](javascript://%0d%0aconfirm(1);com)", "<a>a</a>"},
      {"<javascript:prompt(document.cookie)>", "&lt;javascript:prompt(document.cookie)&gt;"},
      {"![a](https://www.google.com/image.png\"onload=\"alert(1))",
       "<p><img src=\"https://www.google.com/image.png\" alt=\"a\" />\n</p>\n"},
      {"[a](javascript:window.onerror=confirm;throw%201)", "<a>a</a>"},
      {"[a](Javas%26%2399;ript:alert(1&#41;)", "[a](Javas%26%2399;ript:alert(1&amp;#41;)"},
      {"[XSS](.alert(1);)", "<a rel=\"ugc\" target=\"_blank\" href=\".alert(1);\">XSS</a>"},
      {"[a](javascript://www.google.com%0Aalert(1))", "<a>a</a>"},
      {"[a](&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29)",
       "<a>a</a>"},
      {"[a](JaVaScRiPt:alert(1))", "<a>a</a>"},
      {"[test](javascript://%0d%0aprompt(1);com)", "<a>test</a>"},
      {"</http://<?php><h1><script:script>confirm(2)",
       "<a>/http://&lt;?php</a>&lt;h1&gt;&lt;script:script&gt;confirm(2)"},
      {"[a]('javascript:alert(\"1\")')", "<a>a</a>"},
      {"[a](javascript:confirm(1)", "[a](javascript:confirm(1)"},
      {"[a](javascript:this;alert(1))", "<a>a</a>"},
      {"[text](http://danlec.com \" [@danlec](/danlec) \")",
       "<a rel=\"ugc\" target=\"_blank\" href=\"http://danlec.com\" title=\" [@danlec](/danlec) \">text</a>"},
      {"[notmalicious](javascript:window.onerror=alert;throw%20document.cookie)",
       "<a>notmalicious</a>"},
      {"![a](\"onerror=\"alert(1))", "<p><img src=\"\" alt=\"a\" />\n</p>\n"},
      {"[ ](http://a?p=[[/onclick=alert(0) .]])",
       "<a rel=\"ugc\" target=\"_blank\" href=\"http://a?p=[[/onclick=alert(0) .]]\"> </a>"},
      {"[a](javascript&#58this;alert(1&#41;)", "[a](javascript&amp;#58this;alert(1&amp;#41;)"},
      {"[ ](https://a.de?p=[[/data-x=. style=background-color:#000000;z-index:999;width:100%;position:fixed;top:0;left:0;right:0;bottom:0; data-y=.]])",
       "<a rel=\"ugc\" target=\"_blank\" href=\"https://a.de?p=[[/data-x=. style=background-color:#000000;z-index:999;width:100%;position:fixed;top:0;left:0;right:0;bottom:0; data-y=.]]\"> </a>"},
      {"[a](javascript:alert&#65534;(1&#41;)", "[a](javascript:alert&amp;#65534;(1&amp;#41;)"},
      {"[a](j    a   v   a   s   c   r   i   p   t:prompt(document.cookie))", "<a>a</a>"},
      {"[a](javascript:this;alert(1&#41;)", "[a](javascript:this;alert(1&amp;#41;)"},
      {"[notmalicious](javascript://%0d%0awindow.onerror=alert;throw%20document.cookie)",
       "<a>notmalicious</a>"},
      {"![a](javascript:prompt(document.cookie))", "<img alt=\"a\" />"},
      {"[citelol]: (javascript:prompt(document.cookie))", ""},
      {"[a](javascript:prompt(document.cookie))", "<a>a</a>"},
      {"[a](data:text/html;base64,PHNjcmlwdD5hbGVydCgnWFNTJyk8L3NjcmlwdD4K)", "<a>a</a>"}
    ]

    ExUnit.Case.register_attribute(__ENV__, :pair)

    for {lhs, rhs} <- @bad_links do
      @pair {lhs, rhs}
      left_hash = :crypto.hash(:sha, lhs) |> Base.encode16()

      test "bad_links: #{left_hash}", context do
        {l, r} = context.registered.pair

        {:ok, out} = Profile.safe_user_markdown_to_html(l)

        assert out =~ r
      end
    end

    test "cannot inject local urls" do
      bad_markdown = "[a](javascript:prompt(document.cookie))"
      bad_html = "<a href=\"javascript:prompt(document.cookie)\">a</a>"

      refute {:ok, bad_html} == Profile.safe_user_markdown_to_html(bad_markdown)
    end
  end
end
