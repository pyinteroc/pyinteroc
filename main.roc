app "pyinteroc"
    packages { pf: "platform/main.roc" }
    imports [pf.Effect.{Effect}]
    provides [main] to pf

main = 
    Effect.after (Effect.stdoutLine "Starting the project!!\n") 
        \_ -> Effect.always {}