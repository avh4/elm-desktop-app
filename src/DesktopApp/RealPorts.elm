port module DesktopApp.Ports exposing
    ( loadUserData
    , setMenu
    , userDataLoaded
    , writeUserData
    )

import Json.Encode as Json


port writeUserData : String -> Cmd msg


port loadUserData : () -> Cmd msg


port userDataLoaded : (Maybe String -> msg) -> Sub msg


port setMenu : Json.Value -> Cmd msg
