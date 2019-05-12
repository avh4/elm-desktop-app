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
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


port writeOut : List ( String, String ) -> Cmd msg


port loadFile : String -> Cmd msg


port fileLoaded : (( String, Maybe String ) -> msg) -> Sub msg


program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    , files : File model msg
    , noOp : msg
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

        decoders =
            [ config.files ]
                |> List.map (\(File filename (Object _ decode)) -> ( filename, decode ))
                |> Dict.fromList
    in
    Browser.document
        { init =
            \() ->
                let
                    ( model, cmd ) =
                        config.init
                in
                ( model
                , Cmd.batch
                    [ cmd
                    , [ config.files ]
                        |> List.map (\(File name _) -> name)
                        |> List.map loadFile
                        |> Cmd.batch
                    ]
                )
        , update =
            \msg model ->
                config.update msg model
                    |> saveFiles
        , subscriptions =
            let
                handleLoad ( filename, result ) =
                    case result of
                        Nothing ->
                            config.noOp

                        Just body ->
                            case Dict.get filename decoders of
                                Nothing ->
                                    -- Log error?
                                    config.noOp

                                Just decoder ->
                                    case Json.Decode.decodeString decoder body of
                                        Err err ->
                                            -- Log error?
                                            config.noOp

                                        Ok value ->
                                            value
            in
            \model ->
                Sub.batch
                    [ config.subscriptions model
                    , fileLoaded handleLoad
                    ]
        , view =
            \model ->
                { title = ""
                , body =
                    [ config.view model
                    ]
                }
        }


type File model msg
    = File String (Object msg model)


encodeFile : File model msg -> model -> ( String, String )
encodeFile (File filename (Object fields _)) model =
    let
        json =
            Json.object
                (List.map (\( k, f ) -> ( k, f model )) fields)
    in
    ( filename, Json.encode 0 json )


jsonFile : String -> (a -> msg) -> Object a a -> File a msg
jsonFile filename toMsg (Object encode decode) =
    File filename (Object encode (Json.Decode.map toMsg decode))


type Object a b
    = Object (List ( String, b -> Json.Value )) (Decoder a)


object : a -> Object a b
object a =
    Object [] (Json.Decode.succeed a)


type Field a
    = Field (a -> Json.Value) (Decoder a)


field : String -> (x -> a) -> Field a -> Object (a -> b) x -> Object b x
field name get (Field toJson fd) (Object fields decoder) =
    Object (( name, get >> toJson ) :: fields) (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) decoder)


int : Field Int
int =
    Field Json.int Json.Decode.int


staticString : String -> String -> Object a x -> Object a x
staticString name value (Object fields decoder) =
    Object (( name, \_ -> Json.string value ) :: fields) decoder
