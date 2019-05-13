module DesktopApp.Ports exposing (fileLoaded, loadFile, writeOut)

{-| This module is used when publishing the elm-desktop-app -- theses "ports" do
nothing when used in the browser.
When building a project with elm-desktop-app, these will be replaced will real ports
that will connect to the electron process.
-}


writeOut : List ( String, String ) -> Cmd msg
writeOut _ =
    Cmd.none


loadFile : String -> Cmd msg
loadFile _ =
    Cmd.none


fileLoaded : (( String, Maybe String ) -> msg) -> Sub msg
fileLoaded _ =
    Sub.none
