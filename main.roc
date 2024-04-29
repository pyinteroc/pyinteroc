app "pyinteroc"
    packages { pf: "./platform/main.roc" }
    imports [pf.Stdout]
    provides [main] to pf

main = Stdout.line "Starting project!!"