port module DesktopApp.Ports exposing (loadUserData, userDataLoaded, writeUserData)


port writeUserData : String -> Cmd msg


port loadUserData : () -> Cmd msg


port userDataLoaded : (Maybe String -> msg) -> Sub msg
