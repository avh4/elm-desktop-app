module DesktopApp.Ports exposing
    ( loadUserData
    , setMenu
    , userDataLoaded
    , writeUserData
    )

{-| This module is used when publishing the elm-desktop-app -- theses "ports" do
nothing when used in the browser.
When building a project with elm-desktop-app, these will be replaced will real ports
that will connect to the electron process.
-}

import Json.Encode as Json


writeUserData : String -> Cmd msg
writeUserData _ =
    Cmd.none


loadUserData : () -> Cmd msg
loadUserData () =
    Cmd.none


userDataLoaded : (Maybe String -> msg) -> Sub msg
userDataLoaded _ =
    Sub.none


setMenu : Json.Value -> Cmd msg
setMenu _ =
    Cmd.none
