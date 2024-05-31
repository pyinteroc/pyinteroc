platform "python"
    requires {} { main : PyArg -> Task {} [Exit I32 Str]_ }
    exposes []
    packages {}
    imports [Task.{Task}, Stderr.{line}, PyTypes.{PyArg}]
    provides [mainForHost]

mainForHost : PyArg  -> Task {} I32 as Fx
mainForHost =
    \py -> Task.attempt (main py) \res ->
        when res is
            Ok {} -> Task.ok {}

            Err (Exit code str) ->
                if Str.isEmpty str then
                    Task.err code
                else
                    line str
                    |> Task.onErr \_ -> Task.err code
                    |> Task.await \{} -> Task.err code

            Err err ->
                line "Program exited early with error: $(Inspect.toStr err)"
                |> Task.onErr \_ -> Task.err 1
                |> Task.await \_ -> Task.err 1
