app "pyinteroc"
    packages { pf: "platform/main.roc" }
    imports [ pf.Task, pf.Stdout, pf.Stdin  ]
    provides [main] to pf

main = 
    result <- Stdin.line |> Task.attempt
    when result is
        Ok mystr -> Stdout.line "Success!! : $(mystr)"
        _ -> Stdout.line "Failure..."