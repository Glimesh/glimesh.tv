%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Design.AliasUsage,
         if_called_more_often_than: 1,
         excluded_namespaces: [
           "Ecto",
           "File",
           "IO",
           "Inspect",
           "Kernel",
           "Macro",
           "Supervisor",
           "Stripe",
           "Task",
           "Version"
         ]},
        {Credo.Check.Readability.ModuleDoc,
         ignore_names: [
           ~r/(GlimeshWeb.*)$/,
           ~r/(\.\w+Controller|\.Endpoint|\.Repo|\.Router|\.\w+Socket|\.\w+View|\.\w+Live)$/
         ]}
      ]
    }
  ]
}
