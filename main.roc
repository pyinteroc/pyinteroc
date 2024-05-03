app "pyinteroc"
    packages { pf: "platform/main.roc" }
    imports [pf.Effect.{Effect}]
    provides [main] to pf

main = 
    Effect.map (Effect.stderrLine "Starting the project!!") 
        \res -> when res is 
            Ok _ -> {}
            _ -> {}