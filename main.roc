app "pyinteroc"
    packages { pf: "platform/main.roc" }
    imports [ pf.Stdout.{ line, write }  ]
    provides [main] to pf

main = line "Starting the project!!"