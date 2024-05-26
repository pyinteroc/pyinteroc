# app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

### Stopping platform development until things become more stable
app [main] { pf: platform  "./platform/main.roc" }


import pf.Stdout
import pf.Stderr
import pf.Stdin
import pf.Task exposing [Task]

# main = Stdout.line "Testing from ROC"

main =
    Stdout.line! "Enter a series of number characters (0-9):"
    # numberBytes = Stdin.line!
    numberBytes = takeNumberBytes!

    if List.isEmpty numberBytes then
        Stderr.line "Expected a series of number characters (0-9)"
    else
        when Str.fromUtf8 numberBytes is
            Ok nStr ->
                Stdout.line "Got number $(nStr)"

            Err _ ->
                Stderr.line "Error, bad utf8"

takeNumberBytes : Task (List U8) _
takeNumberBytes =

    bytesRead = Stdin.bytes!

    numberBytes =
        List.walk bytesRead [] \bytes, b ->
            if b >= '0' && b <= '9' then
                List.append bytes b
            else
                bytes

    Task.ok numberBytes