port module DesktopApp.Ports exposing (fileLoaded, loadFile, writeOut)


port writeOut : List ( String, String ) -> Cmd msg


port loadFile : String -> Cmd msg


port fileLoaded : (( String, Maybe String ) -> msg) -> Sub msg
