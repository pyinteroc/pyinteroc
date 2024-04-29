app "pyinteroc"
    packages { pf: "platform/main.roc" }
    imports [pf.Effect.{Effect}]
    provides [main] to pf

main = 
    Effect.after (Effect.stdoutLine "Starting the project!!") 
        \_ -> Effect.always {}
    # |> Effect.map \res -> when res is
    #     Ok {} -> {}
    #     _ -> {}