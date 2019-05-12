port module App exposing
    ( program
    , File, jsonFile
    )

{-|

@docs program

@docs File, jsonFile

-}

import Browser
import Html exposing (Html)
import Json.Encode as Json


port writeOut : List ( String, String ) -> Cmd msg


program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    , files : model -> File
    }
    -> Program () model msg
program config =
    Browser.document
        { init =
            \_ ->
                let
                    ( model, cmd ) =
                        config.init

                    saveFiles =
                        [ config.files model ]
                            |> List.map encodeFile
                            |> writeOut
                in
                ( model
                , Cmd.batch
                    [ cmd
                    , saveFiles
                    ]
                )
        , update = config.update
        , subscriptions = config.subscriptions
        , view =
            \model ->
                { title = ""
                , body =
                    [ config.view model
                    ]
                }
        }


type File
    = File String String


encodeFile : File -> ( String, String )
encodeFile (File filename content) =
    ( filename, content )


jsonFile : String -> Json.Value -> File
jsonFile filename jsonContent =
    File filename (Json.encode 0 jsonContent)
