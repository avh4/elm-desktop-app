port module App exposing
    ( program
    , File, jsonFile
    , Object, field, int, object, staticString
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
    , files : File model
    }
    -> Program () model msg
program config =
    let
        saveFiles ( model, cmd ) =
            ( model
            , Cmd.batch
                [ cmd
                , [ config.files ]
                    |> List.map (\f -> encodeFile f model)
                    |> writeOut
                ]
            )
    in
    Browser.document
        { init =
            \() ->
                config.init
                    |> saveFiles
        , update =
            \msg model ->
                config.update msg model
                    |> saveFiles
        , subscriptions = config.subscriptions
        , view =
            \model ->
                { title = ""
                , body =
                    [ config.view model
                    ]
                }
        }


type File model
    = File String (Object model model)


encodeFile : File model -> model -> ( String, String )
encodeFile (File filename (Object fields)) model =
    let
        json =
            Json.object
                (List.map (\( k, f ) -> ( k, f model )) fields)
    in
    ( filename, Json.encode 0 json )


jsonFile : String -> Object a a -> File a
jsonFile filename json =
    File filename json


type Object a b
    = Object (List ( String, b -> Json.Value ))


object : a -> Object a b
object _ =
    Object []


type Field a
    = Field (a -> Json.Value)


field : String -> (x -> a) -> Field a -> Object (a -> b) x -> Object b x
field name get (Field toJson) (Object fields) =
    Object (( name, get >> toJson ) :: fields)


int : Field Int
int =
    Field Json.int


staticString : String -> Field a
staticString value =
    Field (\_ -> Json.string value)
