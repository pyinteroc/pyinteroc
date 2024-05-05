app "pyinteroc"
    packages { pf: "platform/main.roc" }
    # packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }
    imports [ pf.Task, pf.Stdout, pf.Stdin  ]
    provides [main] to pf

main = 
    result <- Stdin.line |> Task.attempt
    when result is
        Ok mystr -> Stdout.line "Success!! : $(mystr)"
        _ -> Stdout.line "Failure..."